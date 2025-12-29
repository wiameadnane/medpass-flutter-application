import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants.dart';
import '../providers/user_provider.dart';
import '../services/language_detection_service.dart';
import '../services/translation_service.dart';
import '../widgets/common_widgets.dart';
import 'files/upload_file_screen.dart';

class PdfExtractionScreen extends StatefulWidget {
  final String extractedText;
  final int pageCount;
  final String fileName;
  final String originalPdfPath;

  const PdfExtractionScreen({
    super.key,
    required this.extractedText,
    required this.pageCount,
    required this.fileName,
    required this.originalPdfPath,
  });

  @override
  State<PdfExtractionScreen> createState() => _PdfExtractionScreenState();
}

class _PdfExtractionScreenState extends State<PdfExtractionScreen> {
  final LanguageDetectionService _languageDetectionService =
      LanguageDetectionService();

  String? _translatedText;
  bool _translating = false;
  bool _saving = false;
  bool _detectingLanguage = false;

  TranslateLanguage? _sourceLanguage; // null means auto-detected
  TranslateLanguage? _detectedLanguage;
  TranslateLanguage _targetLanguage = TranslateLanguage.english;

  @override
  void initState() {
    super.initState();
    _setDefaultTargetLanguage();
    _detectSourceLanguage();
  }

  void _setDefaultTargetLanguage() {
    final userProvider = context.read<UserProvider>();
    final preferredCode = userProvider.user?.preferredLanguage ?? 'en';
    final preferredLang = LanguageDetectionService.codeToTranslateLanguage(preferredCode);
    if (preferredLang != null) {
      setState(() {
        _targetLanguage = preferredLang;
      });
    }
  }

  @override
  void dispose() {
    _languageDetectionService.dispose();
    super.dispose();
  }

  Future<void> _detectSourceLanguage() async {
    if (widget.extractedText.isEmpty) return;

    setState(() => _detectingLanguage = true);

    try {
      final detected = await _languageDetectionService.detectLanguage(
        widget.extractedText.substring(
          0,
          widget.extractedText.length > 500 ? 500 : widget.extractedText.length,
        ),
      );

      if (detected != null && mounted) {
        setState(() {
          _detectedLanguage = detected;
          // If detected language is same as target, suggest switching target
          if (detected == _targetLanguage) {
            if (detected == TranslateLanguage.english) {
              _targetLanguage = TranslateLanguage.french;
            } else {
              _targetLanguage = TranslateLanguage.english;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Language detection failed: $e');
    } finally {
      if (mounted) {
        setState(() => _detectingLanguage = false);
      }
    }
  }

  Future<void> _translateText() async {
    if (widget.extractedText.isEmpty) return;

    // Use detected language if source is not manually selected
    final effectiveSourceLanguage = _sourceLanguage ?? _detectedLanguage ?? TranslateLanguage.english;

    // Prevent translation to same language
    if (effectiveSourceLanguage == _targetLanguage) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Source and target language cannot be the same')),
        );
      }
      return;
    }

    setState(() {
      _translating = true;
      _translatedText = null;
    });

    try {
      final translation = await TranslationService.translateText(
        context,
        widget.extractedText,
        effectiveSourceLanguage,
        _targetLanguage,
      );

      if (mounted) {
        setState(() => _translatedText = translation);
      }
    } catch (e) {
      if (mounted && !e.toString().contains('Premium feature required')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Translation failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _translating = false);
      }
    }
  }

  File? _generatedPdfFile;

  Future<File?> _generatePdf() async {
    if (widget.extractedText.isEmpty) return null;

    final effectiveSourceLanguage = _sourceLanguage ?? _detectedLanguage ?? TranslateLanguage.english;
    final sourceLanguageName = LanguageDetectionService.getLanguageName(effectiveSourceLanguage);
    final targetLanguageName = LanguageDetectionService.getLanguageName(_targetLanguage);

    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final hasTranslation = _translatedText != null && _translatedText!.isNotEmpty;
    final totalPages = hasTranslation ? 2 : 1;

    // ===== PAGE 1: Original Extracted Text =====
    _addTextPage(
      pdf,
      title: 'Extracted Text',
      subtitle: sourceLanguageName,
      content: widget.extractedText,
      pageNumber: 1,
      totalPages: totalPages,
      accentColor: PdfColors.blue700,
      dateStr: dateStr,
      timeStr: timeStr,
      fileName: widget.fileName,
      pageCount: widget.pageCount,
    );

    // ===== PAGE 2: Translation (if available) =====
    if (hasTranslation) {
      _addTextPage(
        pdf,
        title: 'Translation',
        subtitle: targetLanguageName,
        content: _translatedText!,
        pageNumber: 2,
        totalPages: totalPages,
        accentColor: PdfColors.teal700,
        dateStr: dateStr,
        timeStr: timeStr,
        showDisclaimer: true,
      );
    }

    // Save PDF
    final tempDir = await getTemporaryDirectory();
    final baseName = widget.fileName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
    final suffix = hasTranslation ? '_translated' : '_extracted';
    final outputPath = '${tempDir.path}/$baseName$suffix.pdf';

    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());

    setState(() => _generatedPdfFile = file);
    return file;
  }

  /// Build PDF header
  pw.Widget _buildPdfHeader(String dateStr, String timeStr, {String? fileName, int? pageCount}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [PdfColors.blue800, PdfColors.teal600],
        ),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Med-Pass',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                fileName != null ? 'PDF: $fileName' : 'Medical Document',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.white,
                ),
              ),
              if (pageCount != null)
                pw.Text(
                  '${pageCount} page(s) extracted',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey300,
                  ),
                ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                dateStr,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                timeStr,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build PDF footer
  pw.Widget _buildPdfFooter(int pageNumber, int totalPages) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Generated by Med-Pass',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
        ),
        pw.Text(
          'Page $pageNumber of $totalPages',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
        ),
      ],
    );
  }

  /// Add a text content page to the PDF
  void _addTextPage(
    pw.Document pdf, {
    required String title,
    required String subtitle,
    required String content,
    required int pageNumber,
    required int totalPages,
    required PdfColor accentColor,
    required String dateStr,
    required String timeStr,
    String? fileName,
    int? pageCount,
    bool showDisclaimer = false,
  }) {
    // Split content into chunks for multi-page support
    final lines = content.split('\n');
    const linesPerPage = 40;

    int currentPage = pageNumber;
    for (int i = 0; i < lines.length; i += linesPerPage) {
      final pageLines = lines.skip(i).take(linesPerPage).join('\n');
      final isFirstChunk = i == 0;
      final isLastChunk = i + linesPerPage >= lines.length;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header (only on first chunk of first page)
              if (isFirstChunk && pageNumber == 1)
                _buildPdfHeader(dateStr, timeStr, fileName: fileName, pageCount: pageCount),
              if (isFirstChunk && pageNumber == 1)
                pw.SizedBox(height: 12),

              // Section header (only on first chunk)
              if (isFirstChunk) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: pw.BoxDecoration(
                    color: accentColor,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        title,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(10),
                        ),
                        child: pw.Text(
                          subtitle,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
              ],

              // Text content
              pw.Expanded(
                child: pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.grey200),
                  ),
                  child: pw.Text(
                    pageLines,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      lineSpacing: 1.5,
                      color: PdfColors.grey800,
                    ),
                  ),
                ),
              ),

              // Disclaimer (only on last page with translation)
              if (showDisclaimer && isLastChunk) ...[
                pw.SizedBox(height: 12),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.amber200),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '!',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.amber800,
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: pw.Text(
                          'This translation was generated using AI. Please verify important medical information with a qualified healthcare professional.',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.amber900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              pw.SizedBox(height: 8),
              _buildPdfFooter(currentPage, totalPages + (lines.length > linesPerPage ? (lines.length ~/ linesPerPage) : 0)),
            ],
          ),
        ),
      );
      currentPage++;
    }
  }

  Future<void> _saveToMedPass() async {
    setState(() => _saving = true);

    try {
      final pdfFile = _generatedPdfFile ?? await _generatePdf();
      if (pdfFile == null || !mounted) return;

      // Create PlatformFile for upload screen
      final platformFile = PlatformFile(
        name: '${widget.fileName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '')}_translated.pdf',
        path: pdfFile.path,
        size: pdfFile.lengthSync(),
        bytes: pdfFile.readAsBytesSync(),
      );

      // Navigate to upload screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UploadFileScreen(initialFile: platformFile),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save document: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _shareDocument() async {
    setState(() => _saving = true);

    try {
      final pdfFile = _generatedPdfFile ?? await _generatePdf();
      if (pdfFile == null || !mounted) return;

      final xFile = XFile(pdfFile.path, mimeType: 'application/pdf');
      await Share.shareXFiles(
        [xFile],
        subject: 'Med-Pass: ${widget.fileName}',
        text: 'Medical document from Med-Pass',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share document: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSaveOptionsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundCard(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusL)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider(sheetContext),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSizes.paddingL),
              Text(
                'Save Document',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark(sheetContext),
                ),
              ),
              const SizedBox(height: AppSizes.paddingS),
              Text(
                'Choose how to save your translated document',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary(sheetContext),
                ),
              ),
              const SizedBox(height: AppSizes.paddingL),
              _buildSaveOption(
                context: sheetContext,
                icon: Icons.cloud_upload_rounded,
                title: 'Save to Med-Pass',
                subtitle: 'Upload to your cloud storage',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _saveToMedPass();
                },
              ),
              const SizedBox(height: AppSizes.paddingM),
              _buildSaveOption(
                context: sheetContext,
                icon: Icons.share_rounded,
                title: 'Share',
                subtitle: 'Send via email, WhatsApp, etc.',
                color: AppColors.accent,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _shareDocument();
                },
              ),
              const SizedBox(height: AppSizes.paddingL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: color.withAlpha((0.05 * 255).round()),
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(color: color.withAlpha((0.2 * 255).round())),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingS),
              decoration: BoxDecoration(
                color: color.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSizes.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark(context),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundCard(context),
        elevation: 0,
        title: Text(
          widget.fileName,
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark(context),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textDark(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              _buildInfoCard(),
              const SizedBox(height: AppSizes.paddingL),

              // Results card with tabs and translation controls
              _buildResultsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: AppTheme.backgroundCard(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          boxShadow: [BoxShadow(color: AppTheme.shadow(context), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingS),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: const Icon(Icons.description_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: AppSizes.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PDF Extracted',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark(context),
                    ),
                  ),
                  Text(
                    '${widget.pageCount} page(s) processed',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    return Builder(
      builder: (context) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.backgroundCard(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          boxShadow: [BoxShadow(color: AppTheme.shadow(context), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text Content Section with tabs
            _buildTextContentSection(),

            // Divider
            Container(
              height: 1,
              color: AppTheme.divider(context),
            ),

            // Translation Controls Section
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Column(
                children: [
                  // Language Selection
                  _buildLanguageSelector(),
                  const SizedBox(height: AppSizes.paddingM),

                  // Translate Button
                  _buildTranslateButton(),

                  // Save Document Button
                  const SizedBox(height: AppSizes.paddingM),
                  _buildSaveButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextContentSection() {
    return Builder(
      builder: (context) => DefaultTabController(
        length: _translatedText != null ? 2 : 1,
        child: Column(
          children: [
            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusL)),
              ),
              child: TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppTheme.textSecondary(context),
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
                tabs: [
                  const Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.text_fields_rounded, size: 18),
                        SizedBox(width: 6),
                        Text('Original'),
                      ],
                    ),
                  ),
                  if (_translatedText != null)
                    const Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.translate_rounded, size: 18),
                          SizedBox(width: 6),
                          Text('Translated'),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Tab Content
            SizedBox(
              height: 200, // Fixed height for text content
              child: TabBarView(
                children: [
                  // Original Text Tab
                  _buildTextTabContent(
                    text: widget.extractedText,
                    accentColor: AppColors.primary,
                  ),
                  // Translated Text Tab
                  if (_translatedText != null)
                    _buildTextTabContent(
                      text: _translatedText!,
                      accentColor: AppColors.accent,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextTabContent({
    required String text,
    required Color accentColor,
  }) {
    return Builder(
      builder: (context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Word count indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Text(
                '${text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length} words',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: accentColor,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingS),

            // Scrollable text content
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.paddingS),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight(context),
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  border: Border.all(color: AppTheme.divider(context)),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textDark(context),
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final sourceLanguages = TranslationService.getAvailableSourceLanguages(context);
        final allTargetLanguages = TranslationService.allLanguages;
        final freeTargetLanguages = TranslationService.getAvailableTargetLanguages(context);
        final userIsPremium = userProvider.user?.isPremium ?? false;

        // Build auto-detect display text
        String autoDetectText = 'Auto-detect';
        if (_detectingLanguage) {
          autoDetectText = 'Detecting...';
        } else if (_detectedLanguage != null) {
          autoDetectText = 'Auto (${LanguageDetectionService.getLanguageName(_detectedLanguage!)})';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Detected language indicator
            if (_detectedLanguage != null && _sourceLanguage == null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Detected: ${LanguageDetectionService.getLanguageName(_detectedLanguage!)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

            Row(
              children: [
                // SOURCE LANGUAGE
                Expanded(
                  child: DropdownButtonFormField<TranslateLanguage?>(
                    isDense: true,
                    isExpanded: true,
                    value: _sourceLanguage,
                    dropdownColor: AppTheme.backgroundCard(context),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textDark(context),
                    ),
                    decoration: InputDecoration(
                      labelText: 'From',
                      labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary(context)),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    selectedItemBuilder: (BuildContext ctx) {
                      return [
                        // Auto-detect option
                        Text(
                          autoDetectText,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textDark(ctx)),
                        ),
                        // All source languages
                        ...sourceLanguages.map((lang) => Text(
                          TranslationService.getLanguageName(lang),
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textDark(ctx)),
                        )),
                      ];
                    },
                    items: [
                      // Auto-detect option (null value)
                      DropdownMenuItem<TranslateLanguage?>(
                        value: null,
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                autoDetectText,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textDark(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // All available source languages
                      ...sourceLanguages.map((lang) {
                        return DropdownMenuItem<TranslateLanguage?>(
                          value: lang,
                          child: Text(
                            TranslationService.getLanguageName(lang),
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(color: AppTheme.textDark(context)),
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _sourceLanguage = value);
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.arrow_forward, color: AppColors.primary, size: 20),
                ),
                // TARGET LANGUAGE - Show all, but lock premium ones for free users
                Expanded(
                  child: DropdownButtonFormField<TranslateLanguage>(
                    isDense: true,
                    isExpanded: true,
                    value: _targetLanguage,
                    dropdownColor: AppTheme.backgroundCard(context),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textDark(context),
                    ),
                    decoration: InputDecoration(
                      labelText: 'To',
                      labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary(context)),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    selectedItemBuilder: (BuildContext ctx) {
                      return allTargetLanguages.map((lang) => Text(
                        TranslationService.getLanguageName(lang),
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textDark(ctx)),
                      )).toList();
                    },
                    items: allTargetLanguages.map((lang) {
                      final isLocked = !userIsPremium && !freeTargetLanguages.contains(lang);
                      return DropdownMenuItem(
                        value: lang,
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                TranslationService.getLanguageName(lang),
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: isLocked ? AppTheme.textMuted(context) : AppTheme.textDark(context),
                                ),
                              ),
                            ),
                            if (isLocked)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha((0.1 * 255).round()),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.lock, size: 10, color: AppColors.primary),
                                      const SizedBox(width: 2),
                                      Text(
                                        'PRO',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        final isLocked = !userIsPremium && !freeTargetLanguages.contains(value);
                        if (isLocked) {
                          _showPremiumLanguageDialog(context);
                        } else {
                          setState(() => _targetLanguage = value);
                        }
                      }
                    },
                  ),
                ),
              ],
            ),

            // Premium hint for free users
            if (!userIsPremium)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: AppTheme.textMuted(context),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Upgrade to Premium for all languages',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.textMuted(context),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/billing'),
                      child: Text(
                        'Upgrade',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  void _showPremiumLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.backgroundCard(dialogContext),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.translate, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Premium Feature',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark(dialogContext),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unlock all translation languages with Premium!',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textDark(dialogContext),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Free plan includes:',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary(dialogContext),
              ),
            ),
            const SizedBox(height: 8),
            _buildFeatureRow(dialogContext, Icons.check_circle, 'Your preferred language', true),
            _buildFeatureRow(dialogContext, Icons.check_circle, 'English', true),
            const SizedBox(height: 12),
            Text(
              'Premium adds:',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            _buildFeatureRow(dialogContext, Icons.add_circle, 'Spanish, Portuguese, Italian', false),
            _buildFeatureRow(dialogContext, Icons.add_circle, 'German, Dutch, Swedish', false),
            _buildFeatureRow(dialogContext, Icons.add_circle, 'Chinese, Japanese, Korean', false),
            _buildFeatureRow(dialogContext, Icons.add_circle, 'Arabic, Hebrew, Hindi, Urdu', false),
            _buildFeatureRow(dialogContext, Icons.add_circle, 'Russian, Polish, Turkish', false),
            _buildFeatureRow(dialogContext, Icons.add_circle, '+ 10 more languages', false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Maybe Later',
              style: GoogleFonts.inter(color: AppTheme.textSecondary(dialogContext)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushNamed(context, '/billing');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Upgrade Now',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, IconData icon, String text, bool isFree) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isFree ? AppColors.success : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textDark(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _translating ? null : _translateText,
        icon: _translating
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.translate),
        label: Text(_translating ? 'Translating...' : 'Translate'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusM)),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saving ? null : _showSaveOptionsDialog,
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save_rounded),
        label: Text(_saving ? 'Processing...' : 'Save & Share'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusM)),
        ),
      ),
    );
  }
}
