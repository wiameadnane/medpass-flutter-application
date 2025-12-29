import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:projet/core/constants.dart';
import 'package:projet/providers/user_provider.dart';
import 'package:projet/screens/files/upload_file_screen.dart';
import 'package:projet/services/image_enhancement_service.dart';
import 'package:projet/services/language_detection_service.dart';
import 'package:projet/services/translation_service.dart';
import 'package:projet/widgets/common_widgets.dart';
import 'package:projet/widgets/ocr_service.dart';

class OCRScanScreen extends StatefulWidget {
  const OCRScanScreen({super.key});

  @override
  State<OCRScanScreen> createState() => _OCRScanScreenState();
}

class _OCRScanScreenState extends State<OCRScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final OCRService _ocrService = OCRService();
  final LanguageDetectionService _langDetectionService = LanguageDetectionService();

  File? _imageFile;
  File? _enhancedImageFile; // Enhanced version of the image for OCR
  String? _recognizedText;
  String? _translatedText;
  File? _generatedPdfFile;
  bool _loading = false;
  bool _enhancing = false;
  bool _translating = false;
  bool _saving = false;
  bool _detectingLanguage = false;
  TranslateLanguage? _sourceLanguage; // null means auto-detected
  TranslateLanguage? _detectedLanguage;
  TranslateLanguage _targetLanguage = TranslateLanguage.english;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set target language to user's preferred language
      _setDefaultTargetLanguage();

      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final autoShowDialog = args?['autoShowDialog'] as bool? ?? false;
      if (autoShowDialog) {
        _showImageSourceDialog();
      }
    });
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
    _ocrService.dispose();
    _langDetectionService.dispose();
    // Clean up temporary enhanced image
    ImageEnhancementService.cleanupEnhancedImage(_enhancedImageFile);
    super.dispose();
  }

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied && mounted) {
      _showPermissionDialog('Camera permission is required to take photos.');
    } else if (mounted) {
      AppSnackBar.showWarning(context, 'Camera permission is required');
    }
    return false;
  }

  Future<bool> _requestGalleryPermission() async {
    Permission permission = Permission.photos;
    var status = await permission.request();

    if (status.isDenied || status.isPermanentlyDenied) {
      permission = Permission.storage;
      status = await permission.request();
    }

    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied && mounted) {
      _showPermissionDialog('Storage permission is required to access gallery.');
    } else if (mounted) {
      AppSnackBar.showWarning(context, 'Storage permission is required');
    }
    return false;
  }

  void _showPermissionDialog(String message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.backgroundCard(dialogContext),
        title: Text('Permission Required', style: TextStyle(color: AppTheme.textDark(dialogContext))),
        content: Text(message, style: TextStyle(color: AppTheme.textSecondary(dialogContext))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary(dialogContext))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Scan document using ML Kit Document Scanner
  /// Provides: edge detection, perspective correction, cropping, enhancement
  Future<void> _scanWithDocScanner() async {
    final hasPermission = await _requestCameraPermission();
    if (!hasPermission) return;

    setState(() {
      _loading = true;
      _recognizedText = null;
      _translatedText = null;
      _generatedPdfFile = null;
      _detectedLanguage = null;
      _sourceLanguage = null;
      _enhancedImageFile = null;
    });

    try {
      // Use Flutter Doc Scanner (ML Kit Document Scanner API)
      // This provides: edge detection, perspective correction, cropping
      // Use getScannedDocumentAsImages to get image paths directly
      final dynamic scannedDocuments = await FlutterDocScanner().getScannedDocumentAsImages(
        page: 1, // Scan single page
      );

      // Debug: Log what we received
      debugPrint('FlutterDocScanner returned: $scannedDocuments');
      debugPrint('Type: ${scannedDocuments.runtimeType}');

      if (scannedDocuments == null) {
        setState(() => _loading = false);
        return;
      }

      // Get the scanned document path
      // The scanner can return: List<String>, String, or Map with pdfUri/images
      String? imagePath;

      if (scannedDocuments is List) {
        debugPrint('Is List with ${scannedDocuments.length} items');
        if (scannedDocuments.isNotEmpty) {
          imagePath = scannedDocuments.first?.toString();
          debugPrint('First item: $imagePath');
        }
      } else if (scannedDocuments is String) {
        imagePath = scannedDocuments;
      } else if (scannedDocuments is Map) {
        debugPrint('Is Map with keys: ${scannedDocuments.keys.toList()}');

        // Convert to string and extract file path directly
        // Format: {Uri: [Page{imageUri=file:///path/to/image.jpg}], Count: 1}
        final rawString = scannedDocuments.toString();
        debugPrint('Raw string: $rawString');

        // Method 1: Look for imageUri= pattern (most specific)
        final imageUriPattern = RegExp(r'imageUri=file://(/[^\s\}\]\,]+)', caseSensitive: false);
        var match = imageUriPattern.firstMatch(rawString);
        if (match != null) {
          imagePath = match.group(1);
          debugPrint('Extracted from imageUri pattern: $imagePath');
        }

        // Method 2: Look for file:/// pattern with common image extensions
        if (imagePath == null) {
          final filePattern = RegExp(r'file://(/[^\s\}\]\,]+\.(jpg|jpeg|png|pdf))', caseSensitive: false);
          match = filePattern.firstMatch(rawString);
          if (match != null) {
            imagePath = match.group(1);
            debugPrint('Extracted from file pattern: $imagePath');
          }
        }

        // Method 3: Look for any file:/// path
        if (imagePath == null) {
          final anyFilePattern = RegExp(r'file://(/[^\s\}\]\,]+)');
          match = anyFilePattern.firstMatch(rawString);
          if (match != null) {
            imagePath = match.group(1);
            debugPrint('Extracted from any file pattern: $imagePath');
          }
        }

        // Method 4: Manual extraction as last resort
        if (imagePath == null && rawString.contains('file:///')) {
          final startIndex = rawString.indexOf('file:///');
          if (startIndex != -1) {
            var endIndex = rawString.length;
            // Find the nearest terminator
            for (final terminator in ['}', ']', ',', ' ']) {
              final idx = rawString.indexOf(terminator, startIndex);
              if (idx != -1 && idx < endIndex) {
                endIndex = idx;
              }
            }
            final fileUri = rawString.substring(startIndex, endIndex);
            imagePath = fileUri.replaceFirst('file://', '');
            debugPrint('Extracted manually: $imagePath');
          }
        }
      }

      debugPrint('Final imagePath: $imagePath');

      if (imagePath == null || imagePath.isEmpty) {
        setState(() => _loading = false);
        if (mounted) {
          AppSnackBar.showError(context, 'No document scanned. Raw: $scannedDocuments');
        }
        return;
      }

      final file = File(imagePath);
      if (!await file.exists()) {
        setState(() => _loading = false);
        if (mounted) {
          AppSnackBar.showError(context, 'Failed to access scanned image');
        }
        return;
      }

      setState(() => _imageFile = file);

      // Apply image enhancement for better OCR
      await _enhanceAndProcess(file);
    } on PlatformException catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Scanner error: ${e.message}');
      }
      setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Scanning error: $e');
      }
      setState(() => _loading = false);
    }
  }

  /// Pick image from gallery (fallback option)
  Future<void> _pickFromGallery() async {
    final hasPermission = await _requestGalleryPermission();
    if (!hasPermission) return;

    setState(() {
      _loading = true;
      _recognizedText = null;
      _translatedText = null;
      _generatedPdfFile = null;
      _detectedLanguage = null;
      _sourceLanguage = null;
      _enhancedImageFile = null;
    });

    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (picked == null) {
        setState(() => _loading = false);
        return;
      }

      final file = File(picked.path);
      setState(() => _imageFile = file);

      // Apply image enhancement for better OCR
      await _enhanceAndProcess(file);
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error: $e');
      }
      setState(() => _loading = false);
    }
  }

  /// Enhance image and run OCR
  Future<void> _enhanceAndProcess(File imageFile) async {
    try {
      setState(() => _enhancing = true);

      // Enhance the image for better OCR results
      final enhancedFile = await ImageEnhancementService.enhanceDocument(imageFile);
      setState(() => _enhancedImageFile = enhancedFile);

      setState(() => _enhancing = false);

      // Run OCR on the enhanced image
      final text = await _ocrService.scanDocument(enhancedFile.path);
      setState(() => _recognizedText = text);

      // Auto-detect language after OCR
      if (text.isNotEmpty) {
        await _detectLanguage(text);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Processing error: $e');
      }
    } finally {
      setState(() {
        _loading = false;
        _enhancing = false;
      });
    }
  }

  Future<void> _detectLanguage(String text) async {
    setState(() => _detectingLanguage = true);

    try {
      final detected = await _langDetectionService.detectLanguage(text);
      if (mounted) {
        setState(() {
          _detectedLanguage = detected;
          // If detected language is same as target, suggest switching target
          if (detected != null && detected == _targetLanguage) {
            // Auto-switch target to English if detected is same as target
            // (unless detected is already English, then switch to French)
            if (detected == TranslateLanguage.english) {
              _targetLanguage = TranslateLanguage.french;
            } else {
              _targetLanguage = TranslateLanguage.english;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Language detection error: $e');
    } finally {
      if (mounted) {
        setState(() => _detectingLanguage = false);
      }
    }
  }

  Future<void> _translateText() async {
    if (_recognizedText == null || _recognizedText!.isEmpty) return;

    // Use detected language if source is not manually selected
    final effectiveSourceLanguage = _sourceLanguage ?? _detectedLanguage ?? TranslateLanguage.english;

    // Prevent translation to same language
    if (effectiveSourceLanguage == _targetLanguage) {
      if (mounted) {
        AppSnackBar.showWarning(context, 'Source and target language cannot be the same');
      }
      return;
    }

    setState(() {
      _translating = true;
      _translatedText = null;
    });

    try {
      final translated = await TranslationService.translateText(
        context,
        _recognizedText!,
        effectiveSourceLanguage,
        _targetLanguage,
      );
      setState(() => _translatedText = translated);
    } catch (e) {
      if (mounted && !e.toString().contains('Premium feature required')) {
        AppSnackBar.showError(context, 'Translation failed: $e');
      }
    } finally {
      setState(() => _translating = false);
    }
  }

  Future<File?> _generatePdf() async {
    if (_imageFile == null || _recognizedText == null) return null;

    // Get language names for PDF
    final effectiveSourceLanguage = _sourceLanguage ?? _detectedLanguage ?? TranslateLanguage.english;
    final sourceLanguageName = LanguageDetectionService.getLanguageName(effectiveSourceLanguage);
    final targetLanguageName = LanguageDetectionService.getLanguageName(_targetLanguage);

    // Use enhanced image if available, otherwise fall back to original
    // This ensures the PDF contains the clean, processed document image
    final imageForPdf = _enhancedImageFile ?? _imageFile!;

    // Generate PDF with processed image, original text, and translation (if available)
    final pdfFile = await _ocrService.generateMedicalPdf(
      imageForPdf,
      _recognizedText!,
      _translatedText ?? 'No translation available',
      sourceLanguage: sourceLanguageName,
      targetLanguage: targetLanguageName,
    );

    setState(() => _generatedPdfFile = pdfFile);
    return pdfFile;
  }

  Future<void> _saveToMedPass() async {
    if (_imageFile == null || _recognizedText == null) return;

    setState(() => _saving = true);

    try {
      final pdfFile = _generatedPdfFile ?? await _generatePdf();
      if (pdfFile == null || !mounted) return;

      // Create PlatformFile for upload screen
      final platformFile = PlatformFile(
        name: 'scan_${DateTime.now().millisecondsSinceEpoch}.pdf',
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
        AppSnackBar.showError(context, 'Failed to save document: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _shareDocument() async {
    if (_imageFile == null || _recognizedText == null) return;

    setState(() => _saving = true);

    try {
      final pdfFile = _generatedPdfFile ?? await _generatePdf();
      if (pdfFile == null || !mounted) return;

      final xFile = XFile(pdfFile.path, mimeType: 'application/pdf');
      await Share.shareXFiles(
        [xFile],
        subject: 'Med-Pass Scan',
        text: 'Medical document scanned with Med-Pass',
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to share document: $e');
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
                'Choose how to save your scanned document',
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

  void _showImageSourceDialog() {
    // Directly open the document scanner - it has both camera and gallery built-in
    // This ensures all images get the same edge detection & perspective correction
    _scanWithDocScanner();
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingS),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: AppSizes.paddingS),
            Text(title, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary), textAlign: TextAlign.center),
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
        title: Text('Scan Document', style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textDark(context))),
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
              // Instructions
              _buildInstructionsCard(),
              const SizedBox(height: AppSizes.paddingL),

              // Scan Button (shown when no image)
              if (_imageFile == null && !_loading) _buildScanButton(),

              // Loading State
              if (_loading) _buildLoadingState(),

              // Results (shown after scan)
              if (_imageFile != null && !_loading) ...[
                _buildImagePreview(),
                const SizedBox(height: AppSizes.paddingM),
                _buildRescanButton(),
                if (_recognizedText != null) ...[
                  const SizedBox(height: AppSizes.paddingL),
                  _buildResultsCard(),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: AppTheme.backgroundCard(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          boxShadow: [BoxShadow(color: AppTheme.shadow(context), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scan a Document', style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textDark(context))),
            const SizedBox(height: AppSizes.paddingS),
            Text('Take a photo or choose from gallery to extract text from medical documents.',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppTheme.textSecondary(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.paddingXL),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1B4D6E), AppColors.accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          boxShadow: [BoxShadow(color: const Color(0xFF1B4D6E).withAlpha((0.3 * 255).round()), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          children: [
            const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 48),
            const SizedBox(height: AppSizes.paddingM),
            Text('Start Scanning', style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            Text('Auto edge detection & enhancement', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white.withAlpha((0.8 * 255).round()))),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    String loadingText = 'Processing image...';
    if (_enhancing) {
      loadingText = 'Enhancing document...';
    } else if (_imageFile != null && _recognizedText == null) {
      loadingText = 'Extracting text...';
    }

    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(color: AppTheme.backgroundCard(context), borderRadius: BorderRadius.circular(AppSizes.radiusL)),
        child: Column(
          children: [
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
            const SizedBox(height: AppSizes.paddingM),
            Text(loadingText, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textSecondary(context))),
            if (_enhancing) ...[
              const SizedBox(height: AppSizes.paddingS),
              Text(
                'Improving contrast & sharpness for better OCR',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary(context)),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    // Show enhanced image if available, otherwise show original
    final displayImage = _enhancedImageFile ?? _imageFile!;

    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
            image: DecorationImage(image: FileImage(displayImage), fit: BoxFit.cover),
          ),
        ),
        if (_enhancedImageFile != null) ...[
          const SizedBox(height: AppSizes.paddingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_fix_high, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'Enhanced for better OCR',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRescanButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showImageSourceDialog,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Rescan'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusM)),
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
                    text: _recognizedText!,
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

  Widget _buildLanguageSelector() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final sourceLanguages = TranslationService.getAvailableSourceLanguages(context);
        final allTargetLanguages = TranslationService.allLanguages; // Show ALL languages
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
                // SOURCE LANGUAGE - All languages available for everyone
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
                      // All available source languages (unlimited for all users)
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
                          // Show upgrade dialog
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
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.translate),
        label: Text(_translating ? 'Translating...' : 'Translate'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      ),
    );
  }

}
