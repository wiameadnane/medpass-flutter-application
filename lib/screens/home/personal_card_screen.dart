import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';

class PersonalCardScreen extends StatelessWidget {
  const PersonalCardScreen({super.key});

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
          'Health Card',
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
              // NFC Card illustration
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primaryLight,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha((0.3 * 255).round()),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: AppSizes.paddingL,
                        left: AppSizes.paddingL,
                        child: Image.asset(
                          'assets/images/medpass_logo.png',
                          height: 50,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        bottom: AppSizes.paddingL,
                        left: AppSizes.paddingL,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HEALTH CARD',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withAlpha((0.8 * 255).round()),
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              '**** **** **** 1234',
                              style: GoogleFonts.dmSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: AppSizes.paddingL,
                        right: AppSizes.paddingL,
                        child: Icon(
                          Icons.nfc_rounded,
                          color: Colors.white.withAlpha((0.8 * 255).round()),
                          size: 40,
                        ),
                      ),
                      Positioned(
                        bottom: AppSizes.paddingL,
                        right: AppSizes.paddingL,
                        child: Icon(
                          Icons.contactless_rounded,
                          color: Colors.white.withAlpha((0.8 * 255).round()),
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),

                const SizedBox(height: AppSizes.paddingXL),

                // Features list
                Container(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Health, One Tap Away.',
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark(context),
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingM),
                      _buildFeatureItem(context, Icons.nfc_rounded, 'Uses NFC technology: just tap the card on a smartphone'),
                      _buildFeatureItem(context, Icons.open_in_new_rounded, 'Instantly opens your digital medical record'),
                      _buildFeatureItem(context, Icons.picture_as_pdf_rounded, 'Direct access to your personal health profile (PDF format)'),
                      _buildFeatureItem(context, Icons.app_blocking_rounded, 'No app or login required for access'),
                      _buildFeatureItem(context, Icons.wifi_off_rounded, 'Works offline in emergency situations'),
                      _buildFeatureItem(context, Icons.share_rounded, 'Quick and secure sharing with healthcare professionals'),
                      _buildFeatureItem(context, Icons.flight_rounded, 'Ideal for travel, emergencies, or everyday care'),
                    ],
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

                const SizedBox(height: AppSizes.paddingL),

                // Pre-order button
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/billing');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.paddingM),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    ),
                    child: Center(
                      child: Text(
                        'Pre-order Now',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent, size: 18),
          const SizedBox(width: AppSizes.paddingS),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppTheme.textDark(context),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
