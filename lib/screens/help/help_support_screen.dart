import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../widgets/common_widgets.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int? _expandedFaqIndex;

  final List<_FaqItem> _faqs = [
    _FaqItem(
      question: 'How do I scan a medical document?',
      answer: 'Tap the scan button (camera icon) on the home screen. You can either take a photo of your document or select one from your gallery. The app will automatically detect edges, enhance the image, and extract text using OCR technology.',
    ),
    _FaqItem(
      question: 'How do I share my medical information with a doctor?',
      answer: 'You can share your information in two ways:\n\n1. QR Code: Go to "My QR Code" from the home screen. The doctor can scan this code to view your medical profile.\n\n2. Share files: Open any document and tap the share button to send it via email, WhatsApp, or other apps.',
    ),
    _FaqItem(
      question: 'How does the translation feature work?',
      answer: 'After scanning a document or viewing a PDF, tap the translate button. Select your source and target languages, then tap "Translate". The app uses on-device AI translation, so your medical data stays private and secure.',
    ),
    _FaqItem(
      question: 'What languages are supported for translation?',
      answer: 'Free users can translate to their preferred language and English. Premium users have access to 25+ languages including Spanish, French, German, Arabic, Chinese, Japanese, Korean, and many more.',
    ),
    _FaqItem(
      question: 'How do I mark a file as important?',
      answer: 'When viewing your files, tap the star icon on any file to mark it as important. Important files appear in a separate "Important Files" section for quick access.',
    ),
    _FaqItem(
      question: 'Is my medical data secure?',
      answer: 'Yes! Your data is encrypted and stored securely in the cloud. We use industry-standard security measures to protect your sensitive medical information. Translation is performed on-device, meaning your text never leaves your phone.',
    ),
    _FaqItem(
      question: 'How do I set up emergency contacts?',
      answer: 'Go to your Profile, then tap "Emergency Contact". You can add a contact name and phone number that will be displayed on your Health Pass for emergency situations.',
    ),
    _FaqItem(
      question: 'What is the difference between Free and Premium?',
      answer: 'Free plan includes:\n- Basic document scanning and OCR\n- Translation to 2 languages\n- Cloud storage for your files\n- QR code sharing\n\nPremium adds:\n- Translation to 25+ languages\n- PDF text extraction and translation\n- Priority support\n- No ads',
    ),
    _FaqItem(
      question: 'How do I change my preferred language?',
      answer: 'Go to Settings from the menu drawer, then select your preferred language. This language will be used as the default target language for translations.',
    ),
    _FaqItem(
      question: 'Can I use the app offline?',
      answer: 'Yes, partially. Document scanning and OCR work offline. However, you need an internet connection to upload files to the cloud, download translation models (first time only), and sync your data across devices.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundCard(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textDark(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help & Support',
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FAQ Section
            _buildSectionHeader('Frequently Asked Questions'),
            const SizedBox(height: AppSizes.paddingM),
            _buildFaqList(),

            const SizedBox(height: AppSizes.paddingXL),

            // Contact Section
            _buildSectionHeader('Contact Us'),
            const SizedBox(height: AppSizes.paddingM),
            _buildContactCard(),

            const SizedBox(height: AppSizes.paddingXL),

            // Legal Section
            _buildSectionHeader('Legal'),
            const SizedBox(height: AppSizes.paddingM),
            _buildLegalOptions(),

            const SizedBox(height: AppSizes.paddingXL),

            // About Section
            _buildAboutCard(),

            const SizedBox(height: AppSizes.paddingL),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Builder(
      builder: (context) => Text(
        title,
        style: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppTheme.textDark(context),
        ),
      ),
    );
  }

  Widget _buildFaqList() {
    return Builder(
      builder: (context) => Container(
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          child: Column(
            children: List.generate(_faqs.length, (index) {
              final faq = _faqs[index];
              final isExpanded = _expandedFaqIndex == index;
              final isLast = index == _faqs.length - 1;

              return Column(
                children: [
                  _buildFaqTile(faq, index, isExpanded, context),
                  if (!isLast && !isExpanded)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
                      color: AppTheme.divider(context),
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqTile(_FaqItem faq, int index, bool isExpanded, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isExpanded ? AppColors.primary.withAlpha((0.05 * 255).round()) : AppTheme.backgroundCard(context),
      ),
      child: Column(
        children: [
          // Question header
          InkWell(
            onTap: () {
              setState(() {
                _expandedFaqIndex = isExpanded ? null : index;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? AppColors.primary
                          : AppColors.primary.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isExpanded ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingM),
                  Expanded(
                    child: Text(
                      faq.question,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark(context),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isExpanded ? AppColors.primary : AppTheme.textMuted(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Answer content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingM + 28 + AppSizes.paddingM,
                0,
                AppSizes.paddingM,
                AppSizes.paddingM,
              ),
              child: Text(
                faq.answer,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary(context),
                  height: 1.5,
                ),
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
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
            _buildContactOption(
              context: context,
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'support@medpass.com',
              color: AppColors.primary,
              onTap: () => _launchEmail(),
            ),
            Divider(height: 1, color: AppTheme.divider(context)),
            _buildContactOption(
              context: context,
              icon: Icons.bug_report_outlined,
              title: 'Report a Problem',
              subtitle: 'Help us improve the app',
              color: AppColors.warning,
              onTap: () => _launchEmail(subject: 'Bug Report - Med-Pass App'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppSizes.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
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
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.textMuted(context),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalOptions() {
    return Builder(
      builder: (context) => Container(
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
            _buildLegalOption(
              context: context,
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () => _showComingSoon('Privacy Policy'),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
              color: AppTheme.divider(context),
            ),
            _buildLegalOption(
              context: context,
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              onTap: () => _showComingSoon('Terms of Service'),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
              color: AppTheme.divider(context),
            ),
            _buildLegalOption(
              context: context,
              icon: Icons.medical_information_outlined,
              title: 'Medical Disclaimer',
              onTap: () => _showMedicalDisclaimer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary(context), size: 22),
            const SizedBox(width: AppSizes.paddingM),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDark(context),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.textMuted(context),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4D6E), AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/medpass_logo.png',
            height: 40,
            fit: BoxFit.contain,
            color: Colors.white,
            colorBlendMode: BlendMode.srcIn,
          ),
          const SizedBox(height: AppSizes.paddingM),
          Text(
            'Med-Pass',
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your Medical Passport',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withAlpha((0.8 * 255).round()),
            ),
          ),
          const SizedBox(height: AppSizes.paddingM),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.2 * 255).round()),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Version 1.0.0',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail({String? subject}) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@medpass.com',
      queryParameters: subject != null ? {'subject': subject} : null,
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (mounted) {
          AppSnackBar.showError(context, 'Could not open email app');
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error: $e');
      }
    }
  }

  void _showComingSoon(String feature) {
    AppSnackBar.showInfo(context, '$feature coming soon');
  }

  void _showMedicalDisclaimer() {
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
                color: AppColors.warning.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.medical_information_outlined,
                color: AppColors.warning,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Medical Disclaimer',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark(dialogContext),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Med-Pass is designed to help you store and access your medical documents. '
          'It is NOT a substitute for professional medical advice, diagnosis, or treatment.\n\n'
          'Always seek the advice of your physician or other qualified health provider '
          'with any questions you may have regarding a medical condition.\n\n'
          'In case of a medical emergency, call your local emergency services immediately.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textSecondary(dialogContext),
            height: 1.5,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  _FaqItem({required this.question, required this.answer});
}
