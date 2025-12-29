import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
          AppStrings.profile,
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark(context),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.paddingM),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/edit-profile'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingM,
                  vertical: AppSizes.paddingS,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.inputBackground(context),
                  borderRadius: BorderRadius.circular(AppSizes.radiusL),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16, color: AppTheme.textDark(context)),
                    const SizedBox(width: 4),
                    Text(
                      AppStrings.edit,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textDark(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
          children: [
            // User info
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  final user = userProvider.user;
                  return Column(
                    children: [
                      Text(
                        user?.fullName ?? 'User',
                        style: GoogleFonts.dmSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark(context),
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingXS),
                      if (user?.age != null)
                        Text(
                          '${user!.age} Years old',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                      const SizedBox(height: AppSizes.paddingXS),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (user?.formattedDateOfBirth.isNotEmpty ?? false)
                            Text(
                              user!.formattedDateOfBirth,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.accent,
                              ),
                            ),
                          if (user?.bloodType != null) ...[
                            const SizedBox(width: AppSizes.paddingL),
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
                          ],
                        ],
                      ),
                    ],
                  );
                },
              ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

              const SizedBox(height: AppSizes.paddingL),

              // Health Pass title
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
                padding: const EdgeInsets.all(AppSizes.paddingM),
                decoration: BoxDecoration(
                  color: AppTheme.inputBackground(context).withAlpha((0.3 * 255).round()),
                  borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                ),
                child: Text(
                  AppStrings.myHealthPass,
                  style: GoogleFonts.dmSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent.withAlpha((0.85 * 255).round()),
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

              const SizedBox(height: AppSizes.paddingL),

              // QR Code
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  final user = userProvider.user;
                  return Container(
                    padding: const EdgeInsets.all(AppSizes.paddingL),
                    margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXL),
                    decoration: BoxDecoration(
                      color: AppTheme.inputBackground(context).withAlpha((0.3 * 255).round()),
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    ),
                    child: QrImageView(
                      data: user?.emergencyQrData ?? 'No emergency data',
                      version: QrVersions.auto,
                      size: 200,
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
                  );
                },
              ).animate().fadeIn(duration: 600.ms, delay: 400.ms).scale(begin: const Offset(0.9, 0.9)),

              const SizedBox(height: AppSizes.paddingXL),

              // View details button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/personal-info');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.paddingM),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    ),
                    child: Center(
                      child: Text(
                        'View Personal Info',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 500.ms),

              const SizedBox(height: AppSizes.paddingM),

              // Logout button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
                child: GestureDetector(
                  onTap: () async {
                    final confirmed = await ConfirmDialog.showLogout(context);
                    if (confirmed && context.mounted) {
                      await context.read<UserProvider>().logout();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                      }
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.paddingM),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundCard(context),
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                      border: Border.all(color: AppColors.error, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        'Logout',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 600.ms),

            const SizedBox(height: AppSizes.paddingXL),
          ],
        ),
        ),
      ),
    );
  }
}
