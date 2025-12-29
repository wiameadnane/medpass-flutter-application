import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common_widgets.dart';

class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.textDark(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppStrings.billingPlan,
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark(context),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false, // AppBar already handles the top
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Column(
            children: [
              // Free plan card
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    final isPremium = userProvider.user?.isPremium ?? false;
                    return _buildPlanCard(
                      context,
                      title: 'FREE',
                      price: '\$0',
                      period: '/MON',
                      isCurrentPlan: !isPremium,
                      borderColor: AppColors.primary,
                      features: [
                        'Store up to 5 medical files',
                        'Health QR code for emergencies',
                        '10 document scans per month',
                        'Translation: Your language + EN/FR',
                        '1 emergency contact',
                        'Basic medical profile',
                      ],
                      limitations: [
                        'PDF text extraction locked',
                        'Health card PDF export locked',
                      ],
                    );
                  },
                ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideX(begin: -0.1),

                const SizedBox(height: AppSizes.paddingL),

                // Premium plan card
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    final isPremium = userProvider.user?.isPremium ?? false;
                    return _buildPlanCard(
                      context,
                      title: 'PREMIUM',
                      price: '\$12',
                      period: '/MON',
                      isCurrentPlan: isPremium,
                      borderColor: AppColors.warning,
                      isPremium: true,
                      features: [
                        'Unlimited file storage',
                        'Unlimited document scans',
                        'All 26 translation languages',
                        'Multiple emergency contacts',
                        'PDF text extraction & translation',
                        'Health card PDF export',
                      ],
                    );
                  },
                ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideX(begin: -0.1),

                const SizedBox(height: AppSizes.paddingL),

                // Subscribe / Cancel button
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    final isPremium = userProvider.user?.isPremium ?? false;
                    if (isPremium) {
                      // Cancel subscription button only for premium users
                      return GestureDetector(
                        onTap: userProvider.isLoading ? null : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Cancel Subscription?'),
                              content: const Text(
                                'You will lose access to premium features:\n\n'
                                '• Unlimited file storage → 5 files max\n'
                                '• Unlimited scans → 10/month\n'
                                '• All 26 languages → 3 languages only\n'
                                '• Multiple emergency contacts → 1 only\n'
                                '• PDF extraction & export → Locked',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Keep Premium'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text('Cancel Subscription'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final success = await userProvider.cancelPremium();
                            if (success && context.mounted) {
                              AppSnackBar.show(
                                context: context,
                                message: 'Subscription cancelled',
                              );
                            }
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSizes.paddingM),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundCard(context),
                            borderRadius: BorderRadius.circular(AppSizes.radiusL),
                            border: Border.all(color: Colors.red.shade300, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              userProvider.isLoading ? 'Processing...' : 'Cancel Subscription',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade400,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/payment');
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSizes.paddingM),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.warning, Color(0xFFFFB347)],
                          ),
                          borderRadius: BorderRadius.circular(AppSizes.radiusL),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.warning.withAlpha((0.3 * 255).round()),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.subscribeToPremium,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required String period,
    required bool isCurrentPlan,
    required Color borderColor,
    required List<String> features,
    List<String>? limitations,
    bool isPremium = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: borderColor, width: 3),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark(context),
                    ),
                  ),
                  if (isPremium) ...[
                    const SizedBox(width: AppSizes.paddingS),
                    const Icon(Icons.star_rounded, color: AppColors.warning, size: 20),
                  ],
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price,
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark(context),
                    ),
                  ),
                  Text(
                    period,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isCurrentPlan) ...[
            const SizedBox(height: AppSizes.paddingS),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingS,
                vertical: AppSizes.paddingXS,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Text(
                AppStrings.current,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSizes.paddingM),
          Divider(color: AppTheme.inputBackground(context)),
          const SizedBox(height: AppSizes.paddingM),
          ...features.map((feature) => _buildFeatureItem(context, feature, isPremium, isLimitation: false)),
          if (limitations != null && limitations.isNotEmpty) ...[
            const SizedBox(height: AppSizes.paddingS),
            ...limitations.map((limitation) => _buildFeatureItem(context, limitation, isPremium, isLimitation: true)),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String text, bool isPremium, {bool isLimitation = false}) {
    final isHeader = text.endsWith(':');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isHeader)
            Icon(
              isLimitation ? Icons.lock_outline_rounded : Icons.check_circle_rounded,
              color: isLimitation
                  ? AppTheme.textSecondary(context)
                  : (isPremium ? AppColors.warning : AppColors.accent),
              size: 16,
            ),
          if (!isHeader) const SizedBox(width: AppSizes.paddingS),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
                color: isLimitation ? AppTheme.textSecondary(context) : AppTheme.textDark(context),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
