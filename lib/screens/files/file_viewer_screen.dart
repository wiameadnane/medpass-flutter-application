import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../models/medical_file_model.dart';
import '../../providers/user_provider.dart';
import '../../services/pdf_extraction_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/premium_widgets.dart';
import '../pdf_extraction_screen.dart';

class FileViewerScreen extends StatelessWidget {
  final FileCategory? category;
  final bool showImportantOnly;

  const FileViewerScreen({super.key, this.category, this.showImportantOnly = false});

  @override
  Widget build(BuildContext context) {
    final String title = showImportantOnly
        ? 'Important Files'
        : (category != null ? _getCategoryName(category!) : 'All Documents');

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.textDark(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showImportantOnly) ...[
              const Icon(Icons.star_rounded, color: AppColors.warning, size: 24),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark(context),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          List<MedicalFileModel> files;
          if (showImportantOnly) {
            files = userProvider.importantFiles;
          } else if (category != null) {
            files = userProvider.getFilesByCategory(category!);
          } else {
            files = userProvider.medicalFiles;
          }
          if (files.isEmpty) {
            return _buildEmptyState();
          }
          return _buildFilesList(context, files);
        },
      ),
    );
  }

  Widget _buildFilesList(BuildContext context, List<MedicalFileModel> files) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      itemCount: files.length,
      itemBuilder: (ctx, index) {
        final file = files[index];
        return GestureDetector(
          onTap: () => _openFilePreview(context, file),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
            padding: const EdgeInsets.all(AppSizes.paddingM),
            decoration: BoxDecoration(
              color: AppTheme.backgroundCard(ctx),
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadow(ctx),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Thumbnail + File info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildThumbnail(ctx, file),
                    const SizedBox(width: AppSizes.paddingM),
                    // File name and description - takes full remaining width
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark(ctx),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            file.description ?? file.categoryName,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textSecondary(ctx),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingS),
                // Bottom row: Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Star button
                    _buildActionButton(
                      icon: file.isImportant ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: file.isImportant ? AppColors.warning : AppTheme.textMuted(ctx),
                      label: file.isImportant ? 'Important' : 'Mark important',
                      onTap: () {
                        context.read<UserProvider>().toggleFileImportant(file.id);
                      },
                    ),
                    const SizedBox(width: AppSizes.paddingM),
                    // Delete button
                    _buildActionButton(
                      icon: Icons.delete_outline_rounded,
                      color: AppColors.error,
                      label: 'Delete',
                      onTap: () => _showDeleteConfirmation(context, file),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha((0.1 * 255).round()),
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, MedicalFileModel file) {
    if (file.fileUrl != null && file.isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        child: Image.network(
          file.fileUrl!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (ctx, error, stackTrace) => Container(
            width: 56,
            height: 56,
            color: AppTheme.backgroundLight(ctx),
            child: Icon(Icons.broken_image, color: AppTheme.textMuted(ctx)),
          ),
        ),
      );
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: Icon(
        Icons.insert_drive_file_outlined,
        color: AppTheme.textSecondary(context),
      ),
    );
  }

  void _openFilePreview(BuildContext context, MedicalFileModel file) {
    if (file.fileUrl != null && file.isImage) {
      showDialog(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: AppTheme.backgroundCard(dialogContext),
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(dialogContext).size.width * 0.95,
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.85,
            ),
            child: Stack(
              children: [
                InteractiveViewer(
                  child: Image.network(file.fileUrl!, fit: BoxFit.contain),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor:
                        AppTheme.backgroundCard(dialogContext).withAlpha((0.9 * 255).round()),
                    child: IconButton(
                      icon: Icon(Icons.close, color: AppTheme.textDark(dialogContext)),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    // PDF files: open in-app PDF viewer
    if (file.fileUrl != null && file.isPdf) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerScreen(
            fileUrl: file.fileUrl!,
            fileName: file.name,
          ),
        ),
      );
      return;
    }

    // Other files: show info / placeholder
    // If we have a file URL, offer to open it with an external app/browser.
    if (file.fileUrl != null) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppTheme.backgroundCard(dialogContext),
          title: Text(file.name, style: TextStyle(color: AppTheme.textDark(dialogContext))),
          content:
              Text(file.description ?? 'Open this file in an external viewer.',
                  style: TextStyle(color: AppTheme.textSecondary(dialogContext))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Close', style: TextStyle(color: AppTheme.textSecondary(dialogContext))),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final uri = Uri.tryParse(file.fileUrl!);
                if (uri == null) {
                  if (context.mounted) AppSnackBar.showError(context, 'Invalid file URL');
                  return;
                }

                try {
                  final can = await canLaunchUrl(uri);
                  if (!can) {
                    if (context.mounted) AppSnackBar.showError(context, 'Cannot open file URL');
                    return;
                  }
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (e) {
                  if (context.mounted) AppSnackBar.showError(context, 'Failed to open file: ${e.toString()}');
                }
              },
              child: const Text('Open'),
            ),
          ],
        ),
      );
      return;
    }

    // No URL available: show basic info
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.backgroundCard(dialogContext),
        title: Text(file.name, style: TextStyle(color: AppTheme.textDark(dialogContext))),
        content: Text(
          file.description ?? 'No preview available for this file type.',
          style: TextStyle(color: AppTheme.textSecondary(dialogContext)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Close', style: TextStyle(color: AppTheme.textSecondary(dialogContext))),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Builder(
      builder: (context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundCard(context),
                  borderRadius: BorderRadius.circular(AppSizes.radiusL),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shadow(context),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  showImportantOnly ? Icons.star_outline_rounded : Icons.folder_open_rounded,
                  size: 48,
                  color: showImportantOnly ? AppColors.warning : AppTheme.textMuted(context),
                ),
              ),
              const SizedBox(height: AppSizes.paddingL),
              Text(
                showImportantOnly ? 'No important files' : 'No files yet',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark(context),
                ),
              ),
              const SizedBox(height: AppSizes.paddingS),
              Text(
                showImportantOnly
                    ? 'Tap the star icon on any file\nto mark it as important'
                    : 'Upload your first medical document\nto get started',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary(context),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, MedicalFileModel file) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.backgroundCard(dialogContext),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete File',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
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
              'Are you sure you want to delete this file?',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textDark(dialogContext),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight(dialogContext),
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              child: Row(
                children: [
                  Icon(Icons.insert_drive_file_outlined, color: AppTheme.textSecondary(dialogContext)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      file.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textDark(dialogContext),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone. The file will be permanently deleted from the cloud.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary(dialogContext),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.textSecondary(dialogContext)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              final userProvider = context.read<UserProvider>();
              final success = await userProvider.removeMedicalFile(file.id);

              if (context.mounted) {
                if (success) {
                  AppSnackBar.showSuccess(context, 'File deleted successfully');
                } else {
                  AppSnackBar.showError(context, 'Failed to delete file');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(FileCategory category) {
    switch (category) {
      case FileCategory.allergyReport:
        return AppStrings.allergyReport;
      case FileCategory.prescription:
        return AppStrings.recentPrescriptions;
      case FileCategory.birthCertificate:
        return AppStrings.birthCertificate;
      case FileCategory.medicalAnalysis:
        return AppStrings.medicalAnalysis;
      case FileCategory.other:
        return 'Other Documents';
    }
  }

  Color _getCategoryColor(FileCategory category) {
    switch (category) {
      case FileCategory.allergyReport:
        return AppColors.warning;
      case FileCategory.prescription:
        return AppColors.accent;
      case FileCategory.birthCertificate:
        return AppColors.primary;
      case FileCategory.medicalAnalysis:
        return AppColors.primaryLight;
      case FileCategory.other:
        return AppColors.textSecondary;
    }
  }
}

class PDFViewerScreen extends StatefulWidget {
  final String fileUrl;
  final String fileName;

  const PDFViewerScreen({
    super.key,
    required this.fileUrl,
    required this.fileName,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;
  bool isDownloading = true;
  bool isExtracting = false;
  String? localFilePath;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    try {
      final response = await HttpClient().getUrl(Uri.parse(widget.fileUrl));
      final httpResponse = await response.close();

      if (httpResponse.statusCode != 200) {
        throw Exception('Failed to download PDF: ${httpResponse.statusCode}');
      }

      final bytes = await consolidateHttpClientResponseBytes(httpResponse);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${widget.fileName}');
      await tempFile.writeAsBytes(bytes);

      if (mounted) {
        setState(() {
          localFilePath = tempFile.path;
          isDownloading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to download PDF: $e';
          isDownloading = false;
        });
      }
    }
  }

  Future<void> _sharePdf() async {
    if (localFilePath == null) return;

    try {
      final xFile = XFile(localFilePath!, mimeType: 'application/pdf');
      await Share.shareXFiles(
        [xFile],
        subject: widget.fileName,
        text: 'Shared from Med-Pass',
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to share: $e');
      }
    }
  }

  Future<void> _extractAndTranslate() async {
    if (localFilePath == null) return;

    // Check if user has premium access for PDF extraction
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isPremium = userProvider.user?.isPremium ?? false;

    if (!PremiumFeatures.canExtractPdfText(isPremium)) {
      await PremiumFeatureDialog.show(
        context: context,
        featureName: 'PDF Text Extraction',
        description: 'Extract text from PDFs and translate them into your preferred language. This powerful feature is available with Premium.',
        icon: Icons.text_snippet_outlined,
      );
      return;
    }

    setState(() => isExtracting = true);

    try {
      final extractionService = PdfExtractionService();
      final result = await extractionService.extractTextFromPdf(localFilePath!);
      await extractionService.dispose();

      if (!mounted) return;

      if (result.success && result.text.isNotEmpty) {
        // Navigate to extraction screen with the extracted text
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfExtractionScreen(
              extractedText: result.text,
              pageCount: result.pageCount,
              fileName: widget.fileName,
              originalPdfPath: localFilePath!,
            ),
          ),
        );
      } else {
        AppSnackBar.showError(context, result.error ?? 'No text could be extracted from this PDF');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Extraction failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isExtracting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        actions: [
          // Extract & Translate button (Premium feature)
          if (localFilePath != null && isReady)
            Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                final isPremium = userProvider.user?.isPremium ?? false;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.translate_rounded),
                      tooltip: isPremium ? 'Extract & Translate' : 'Extract & Translate (Premium)',
                      onPressed: isExtracting ? null : _extractAndTranslate,
                    ),
                    // Show premium badge for free users
                    if (!isPremium)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.warning, Color(0xFFFFB347)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          // Share button
          if (localFilePath != null && isReady)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Share PDF',
              onPressed: _sharePdf,
            ),
          // Page indicator
          if (pages != null && pages! > 1)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${currentPage! + 1} / $pages',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (localFilePath != null)
            PDFView(
              filePath: localFilePath!,
              defaultPage: currentPage!,
              enableSwipe: true,
              swipeHorizontal: true,
              autoSpacing: false,
              pageFling: false,
              onRender: (_pages) {
                setState(() {
                  pages = _pages;
                  isReady = true;
                });
              },
              onError: (error) {
                setState(() {
                  errorMessage = error.toString();
                });
                debugPrint(error.toString());
              },
              onPageError: (page, error) {
                setState(() {
                  errorMessage = '$page: ${error.toString()}';
                });
                debugPrint('$page: ${error.toString()}');
              },
              onViewCreated: (PDFViewController pdfViewController) {
                // You can use the controller to control the PDF view
              },
              onPageChanged: (int? page, int? total) {
                setState(() {
                  currentPage = page;
                });
              },
            ),
          if ((isDownloading || !isReady) && errorMessage.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    isDownloading ? 'Downloading PDF...' : 'Loading PDF...',
                    style: GoogleFonts.inter(color: AppTheme.textSecondary(context)),
                  ),
                ],
              ),
            ),
          if (errorMessage.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load PDF',
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Extraction progress overlay
          if (isExtracting)
            Container(
              color: Colors.black.withAlpha((0.7 * 255).round()),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundCard(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Extracting Text...',
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This may take a moment\nfor large documents',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
