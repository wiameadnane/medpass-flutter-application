import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';

/// Premium feature definitions
class PremiumFeatures {
  // File storage limits
  static const int freeFileLimit = 5;
  static const int premiumFileLimit = -1; // Unlimited

  // Scan limits
  static const int freeScanLimit = 10; // Per month
  static const int premiumScanLimit = -1; // Unlimited

  // Emergency contact limits
  static const int freeEmergencyContactLimit = 1; // Primary only
  static const int premiumEmergencyContactLimit = -1; // Unlimited

  /// Check if user can upload more files
  static bool canUploadMoreFiles(int currentCount, bool isPremium) {
    if (isPremium) return true;
    return currentCount < freeFileLimit;
  }

  /// Check if user can perform more scans this month
  static bool canScanMore(int currentMonthlyCount, bool isPremium) {
    if (isPremium) return true;
    return currentMonthlyCount < freeScanLimit;
  }

  /// Get remaining scans for free user
  static int getRemainingScans(int currentMonthlyCount, bool isPremium) {
    if (isPremium) return -1; // Unlimited
    return (freeScanLimit - currentMonthlyCount).clamp(0, freeScanLimit);
  }

  /// Check if user can add more emergency contacts
  static bool canAddMoreEmergencyContacts(int currentCount, bool isPremium) {
    if (isPremium) return true;
    return currentCount < freeEmergencyContactLimit;
  }

  /// Check if month has reset for scan count
  static bool shouldResetScanCount(DateTime? lastResetDate) {
    if (lastResetDate == null) return true;
    final now = DateTime.now();
    return now.year > lastResetDate.year || now.month > lastResetDate.month;
  }

  // Premium-only features
  static bool canAccessCloudBackup(bool isPremium) => isPremium;
  static bool canAccessFamilySharing(bool isPremium) => isPremium;
  static bool canExportHealthCardPdf(bool isPremium) => isPremium;
  static bool canExtractPdfText(bool isPremium) => isPremium;
  static bool canAccessOfflineMode(bool isPremium) => isPremium;
  static bool canAccessMultiLanguage(bool isPremium) => isPremium;
}

/// Shows a premium feature dialog with nice UI
class PremiumFeatureDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String featureName,
    required String description,
    IconData icon = Icons.lock_outline,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium icon with gradient background
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warning.withAlpha((0.2 * 255).round()),
                      const Color(0xFFFFB347).withAlpha((0.2 * 255).round()),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.warning,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),

              // Premium badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.warning, Color(0xFFFFB347)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Premium Feature',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Feature name
              Text(
                featureName,
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        'Maybe Later',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.warning, Color(0xFFFFB347)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.warning.withAlpha((0.3 * 255).round()),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, true);
                          Navigator.pushNamed(context, '/billing');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Upgrade',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
