import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/premium_widgets.dart';

class QrCodeScreen extends StatefulWidget {
  const QrCodeScreen({super.key});

  @override
  State<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isGeneratingPdf = false;

  Future<void> _downloadAsPdf(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isPremium = userProvider.user?.isPremium ?? false;

    // Check if user has premium access
    if (!PremiumFeatures.canExportHealthCardPdf(isPremium)) {
      await PremiumFeatureDialog.show(
        context: context,
        featureName: 'PDF Health Card Export',
        description: 'Download your health pass as a professional PDF document to print or share. Available with Premium.',
        icon: Icons.picture_as_pdf_outlined,
      );
      return;
    }

    final user = userProvider.user;
    if (user == null || !user.hasEmergencyQrData) {
      AppSnackBar.showWarning(context, 'Please complete your health profile first');
      return;
    }

    setState(() => _isGeneratingPdf = true);

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'MEDICAL HEALTH PASS',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Emergency Medical Information',
                  style: const pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Divider(color: PdfColors.grey400),
                pw.SizedBox(height: 20),

                // User info
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        user.fullName,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          if (user.bloodType != null)
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.red100,
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Text(
                                'Blood Type: ${user.bloodType}',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.red900,
                                ),
                              ),
                            ),
                          if (user.age != null) ...[
                            pw.SizedBox(width: 12),
                            pw.Text('Age: ${user.age} years'),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // QR Code placeholder with instructions
                pw.Container(
                  width: 180,
                  height: 180,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue900, width: 2),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Center(
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          'QR CODE',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Scan in app',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Emergency info sections
                if (user.allergies.isNotEmpty)
                  _buildPdfSection('ALLERGIES', user.allergies),
                if (user.medicalConditions.isNotEmpty)
                  _buildPdfSection('MEDICAL CONDITIONS', user.medicalConditions),
                if (user.currentMedications.isNotEmpty)
                  _buildPdfSection('CURRENT MEDICATIONS', user.currentMedications),

                pw.SizedBox(height: 20),

                // Emergency contact
                if (user.emergencyContactName != null || user.emergencyContactPhone != null)
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.orange50,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.orange200),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'EMERGENCY CONTACT',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.orange900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        if (user.emergencyContactName != null)
                          pw.Text('${user.emergencyContactName}${user.emergencyContactRelation != null ? ' (${user.emergencyContactRelation})' : ''}'),
                        if (user.emergencyContactPhone != null)
                          pw.Text('Tel: ${user.emergencyContactPhone}'),
                      ],
                    ),
                  ),

                pw.Spacer(),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Generated by MedPass - Your Medical Passport',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey500,
                  ),
                ),
              ],
            );
          },
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/health_pass_${user.fullName.replaceAll(' ', '_')}.pdf';
      final file = File(outputPath);
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        final shouldShare = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('PDF Created'),
            content: const Text('Your health pass PDF is ready. Would you like to share it?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ],
          ),
        );

        if (shouldShare == true) {
          await Share.shareXFiles([XFile(outputPath)]);
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to generate PDF: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  pw.Widget _buildPdfSection(String title, List<String> items) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 4),
          ...items.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 8, top: 2),
                child: pw.Text('• $item'),
              )),
        ],
      ),
    );
  }

  Future<void> _shareQr(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user == null || !user.hasEmergencyQrData) {
      AppSnackBar.showWarning(context, 'Please complete your health profile first');
      return;
    }

    // Share the emergency text data
    await Share.share(
      user.emergencyQrData,
      subject: 'Emergency Medical Info - ${user.fullName}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.textDark(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppStrings.myHealthPass,
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark(context),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Column(
            children: [
              // User info card
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    final user = userProvider.user;
                    return Container(
                      padding: const EdgeInsets.all(AppSizes.paddingL),
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
                      child: Column(
                        children: [
                          // Profile icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundLight(context),
                              borderRadius: BorderRadius.circular(AppSizes.radiusM),
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              size: 50,
                              color: AppColors.primary.withAlpha((0.5 * 255).round()),
                            ),
                          ),
                          const SizedBox(height: AppSizes.paddingM),
                          Text(
                            user?.fullName ?? 'User',
                            style: GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark(context),
                            ),
                          ),
                          const SizedBox(height: AppSizes.paddingXS),
                          if (user?.bloodType != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.paddingS,
                                vertical: AppSizes.paddingXS,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withAlpha((0.1 * 255).round()),
                                borderRadius: BorderRadius.circular(AppSizes.radiusS),
                              ),
                              child: Text(
                                user!.bloodType!,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSizes.paddingXS),
                          ],
                          Text(
                            'ID: ${user?.id ?? 'N/A'}',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textSecondary(context),
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
                  },
                ),

                const SizedBox(height: AppSizes.paddingL),

                // QR Code
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    final user = userProvider.user;
                    final hasEmergencyData = user?.hasEmergencyQrData ?? false;
                    final qrData = user?.emergencyQrData ?? 'No emergency data';

                    return Container(
                      padding: const EdgeInsets.all(AppSizes.paddingL),
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
                      child: Column(
                        children: [
                          if (hasEmergencyData) ...[
                            QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 220,
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: AppColors.primary,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: AppSizes.paddingM),
                            Text(
                              'Scan for emergency info',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.textSecondary(context),
                              ),
                            ),
                            const SizedBox(height: AppSizes.paddingXS),
                            Text(
                              'Works offline with any QR scanner',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.textSecondary(context).withAlpha((0.7 * 255).round()),
                              ),
                            ),
                          ] else ...[
                            Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundLight(context),
                                borderRadius: BorderRadius.circular(AppSizes.radiusM),
                                border: Border.all(
                                  color: AppTheme.textSecondary(context).withAlpha((0.3 * 255).round()),
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code_2,
                                    size: 60,
                                    color: AppTheme.textSecondary(context).withAlpha((0.5 * 255).round()),
                                  ),
                                  const SizedBox(height: AppSizes.paddingM),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
                                    child: Text(
                                      'Add emergency info to generate your QR code',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textSecondary(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSizes.paddingM),
                            Text(
                              'Complete your profile to enable',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.textSecondary(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(duration: 600.ms, delay: 300.ms).scale(begin: const Offset(0.9, 0.9));
                  },
                ),

                const SizedBox(height: AppSizes.paddingL),

                // Action buttons
                Consumer<UserProvider>(
                  builder: (context, userProvider, _) {
                    final isPremium = userProvider.user?.isPremium ?? false;

                    return Row(
                      children: [
                        // Share button (available to all)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _shareQr(context),
                            child: Container(
                              padding: const EdgeInsets.all(AppSizes.paddingM),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(AppSizes.radiusL),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.share, color: Colors.white, size: 20),
                                  const SizedBox(width: AppSizes.paddingS),
                                  Text(
                                    'Share',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingM),
                        // Download PDF button (Premium feature)
                        Expanded(
                          child: GestureDetector(
                            onTap: _isGeneratingPdf ? null : () => _downloadAsPdf(context),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSizes.paddingM),
                                  decoration: BoxDecoration(
                                    color: _isGeneratingPdf
                                        ? AppColors.accent.withAlpha((0.6 * 255).round())
                                        : AppColors.accent,
                                    borderRadius: BorderRadius.circular(AppSizes.radiusL),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_isGeneratingPdf)
                                        const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      else
                                        const Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
                                      const SizedBox(width: AppSizes.paddingS),
                                      Text(
                                        'PDF',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Premium badge for free users
                                if (!isPremium)
                                  Positioned(
                                    right: -4,
                                    top: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [AppColors.warning, Color(0xFFFFB347)],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.star_rounded,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
