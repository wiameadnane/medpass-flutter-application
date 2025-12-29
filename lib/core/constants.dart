import 'package:flutter/material.dart';

/// Returns theme-aware colors based on current brightness
class AppTheme {
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // Backgrounds
  static Color background(BuildContext context) =>
      isDark(context) ? AppColorsDark.background : AppColors.background;
  static Color backgroundLight(BuildContext context) =>
      isDark(context) ? AppColorsDark.backgroundLight : AppColors.backgroundLight;
  static Color backgroundGrey(BuildContext context) =>
      isDark(context) ? AppColorsDark.backgroundGrey : AppColors.backgroundGrey;
  static Color backgroundCard(BuildContext context) =>
      isDark(context) ? AppColorsDark.backgroundCard : AppColors.backgroundCard;

  // Text
  static Color textPrimary(BuildContext context) =>
      isDark(context) ? AppColorsDark.textPrimary : AppColors.textPrimary;
  static Color textSecondary(BuildContext context) =>
      isDark(context) ? AppColorsDark.textSecondary : AppColors.textSecondary;
  static Color textDark(BuildContext context) =>
      isDark(context) ? AppColorsDark.textDark : AppColors.textDark;
  static Color textMuted(BuildContext context) =>
      isDark(context) ? AppColorsDark.textMuted : AppColors.textMuted;

  // Input
  static Color inputBackground(BuildContext context) =>
      isDark(context) ? AppColorsDark.inputBackground : AppColors.inputBackground;
  static Color inputBorder(BuildContext context) =>
      isDark(context) ? AppColorsDark.inputBorder : AppColors.inputBorder;

  // Other
  static Color divider(BuildContext context) =>
      isDark(context) ? AppColorsDark.divider : AppColors.divider;
  static Color shadow(BuildContext context) =>
      isDark(context) ? AppColorsDark.shadow : AppColors.shadow;

  // Gradients
  static List<Color> cardGradient(BuildContext context) =>
      isDark(context) ? AppColorsDark.cardGradient : AppColors.cardGradient;
}

class AppColors {
  // Primary Colors - Trust & Professionalism
  static const Color primary = Color(0xFF2D7DD2);
  static const Color primaryLight = Color(0xFF5A9FE8);
  static const Color primaryDark = Color(0xFF1A5FA4);

  // Secondary/Accent Colors - Health & Wellness
  static const Color accent = Color(0xFF45B7A0);
  static const Color accentLight = Color(0xFF6FCDB8);
  static const Color accentDark = Color(0xFF2E9A84);

  // Emergency Colors - Urgency & Alerts
  static const Color emergency = Color(0xFFE63946);
  static const Color emergencyLight = Color(0xFFFF6B6B);
  static const Color emergencyDark = Color(0xFFC62828);

  // Background Colors - Clean & Medical
  static const Color background = Colors.white;
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundGrey = Color(0xFFF1F3F4);
  static const Color backgroundCard = Color(0xFFFFFFFF);

  // Text Colors - Readability
  static const Color textPrimary = Color(0xFF2B2D42);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textLight = Colors.white;
  static const Color textMuted = Color(0xFF9CA3AF);

  // Input Colors
  static const Color inputBackground = Color(0xFFF1F3F4);
  static const Color inputBorder = Color(0xFFE5E7EB);
  static const Color inputFocusBorder = Color(0xFF2D7DD2);

  // Status Colors
  static const Color success = Color(0xFF52B788);
  static const Color error = Color(0xFFE63946);
  static const Color warning = Color(0xFFF4A261);
  static const Color info = Color(0xFF4ECDC4);

  // Medical-Specific Colors
  static const Color bloodType = Color(0xFFE63946);
  static const Color allergy = Color(0xFFF4A261);
  static const Color medication = Color(0xFF9B5DE5);
  static const Color document = Color(0xFF2D7DD2);

  // Other
  static const Color divider = Color(0xFFE5E7EB);
  static const Color shadow = Color(0x14000000);
  static const Color overlay = Color(0x80000000);
  static const Color blueOverlay = Color(0x6D017AEB);

  // Gradients
  static const List<Color> primaryGradient = [Color(0xFF2D7DD2), Color(0xFF45B7A0)];
  static const List<Color> emergencyGradient = [Color(0xFFE63946), Color(0xFFFF6B6B)];
  static const List<Color> cardGradient = [Color(0xFFF8F9FA), Color(0xFFFFFFFF)];
}

/// Dark theme colors
class AppColorsDark {
  // Primary Colors - Same brand colors work in dark mode
  static const Color primary = Color(0xFF5A9FE8);
  static const Color primaryLight = Color(0xFF7AB8F5);
  static const Color primaryDark = Color(0xFF2D7DD2);

  // Secondary/Accent Colors
  static const Color accent = Color(0xFF6FCDB8);
  static const Color accentLight = Color(0xFF8FDECE);
  static const Color accentDark = Color(0xFF45B7A0);

  // Emergency Colors
  static const Color emergency = Color(0xFFFF6B6B);
  static const Color emergencyLight = Color(0xFFFF8A8A);
  static const Color emergencyDark = Color(0xFFE63946);

  // Background Colors - Dark surfaces
  static const Color background = Color(0xFF121212);
  static const Color backgroundLight = Color(0xFF1E1E1E);
  static const Color backgroundGrey = Color(0xFF2C2C2C);
  static const Color backgroundCard = Color(0xFF1E1E1E);

  // Text Colors - Light text for dark backgrounds
  static const Color textPrimary = Color(0xFFE1E1E1);
  static const Color textSecondary = Color(0xFFA0A0A0);
  static const Color textDark = Color(0xFFF5F5F5);
  static const Color textLight = Colors.white;
  static const Color textMuted = Color(0xFF707070);

  // Input Colors
  static const Color inputBackground = Color(0xFF2C2C2C);
  static const Color inputBorder = Color(0xFF404040);
  static const Color inputFocusBorder = Color(0xFF5A9FE8);

  // Status Colors - Slightly brighter for dark mode
  static const Color success = Color(0xFF6FCF97);
  static const Color error = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFFB74D);
  static const Color info = Color(0xFF64D8CB);

  // Medical-Specific Colors
  static const Color bloodType = Color(0xFFFF6B6B);
  static const Color allergy = Color(0xFFFFB74D);
  static const Color medication = Color(0xFFB388FF);
  static const Color document = Color(0xFF5A9FE8);

  // Other
  static const Color divider = Color(0xFF404040);
  static const Color shadow = Color(0x40000000);
  static const Color overlay = Color(0x80000000);
  static const Color blueOverlay = Color(0x6D017AEB);

  // Gradients
  static const List<Color> primaryGradient = [Color(0xFF5A9FE8), Color(0xFF6FCDB8)];
  static const List<Color> emergencyGradient = [Color(0xFFFF6B6B), Color(0xFFFF8A8A)];
  static const List<Color> cardGradient = [Color(0xFF1E1E1E), Color(0xFF2C2C2C)];
}

class AppSizes {
  // Padding
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  // Border Radius
  static const double radiusS = 6.0;
  static const double radiusM = 10.0;
  static const double radiusL = 20.0;
  static const double radiusXL = 25.0;
  static const double radiusCircle = 100.0;

  // Icon Sizes
  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;

  // Button Heights
  static const double buttonHeight = 60.0;
  static const double buttonHeightSmall = 46.0;

  // Input Height
  static const double inputHeight = 46.0;
}

class AppStrings {
  static const String appName = 'Med-Pass';
  static const String tagline = 'Travel Light with Medpass';
  static const String description = 'Your Medical Passport in your pocket.\nEasy, quick and secure access to all your medical records.';

  // Auth
  static const String login = 'Log In';
  static const String signUp = 'Sign Up';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String fullName = 'Full Name';
  static const String phoneNumber = 'Phone number';
  static const String noAccount = 'No account?';
  static const String haveAccount = 'Already have an account?';

  // Profile
  static const String profile = 'Profile';
  static const String personalInfo = 'PERSONAL INFO';
  static const String createProfile = 'Create your profile';
  static const String dateOfBirth = 'Date of birth';
  static const String height = 'Height';
  static const String weight = 'Weight';
  static const String countryOfOrigin = 'Country of origin';
  static const String gender = 'Gender';
  static const String bloodType = 'Blood Type';
  static const String nationality = 'Nationality';
  static const String userId = 'USER ID';
  static const String save = 'Save';
  static const String edit = 'EDIT';

  // Dashboard
  static const String search = 'Search';
  static const String myFiles = 'My files';
  static const String myQrCode = 'My QR code';
  static const String emergency = 'Emergency';
  static const String personalCard = 'Personal Card';
  static const String clickToAccessProfile = 'Click to access your profile';

  // Files
  static const String viewFiles = 'View files';
  static const String uploadMore = 'Upload more';
  static const String importantInfo = 'Important informations';
  static const String allFilesInOneSpace = 'All your files in one space';
  static const String allergyReport = 'Allergy Report';
  static const String recentPrescriptions = 'Recent Prescriptions';
  static const String birthCertificate = 'Birth Certificate';
  static const String medicalAnalysis = 'Medical Analysis';
  static const String goBack = 'Go back';

  // Emergency
  static const String emergencyGuide = 'Emergency Guide';

  // Billing
  static const String billingPlan = 'Billing Plan';
  static const String free = 'FREE';
  static const String premium = 'PREMIUM';
  static const String current = 'CURRENT';
  static const String subscribeToPremium = 'Subscribe to premium';
  static const String proceedToPay = 'Proceed to pay';

  // Health Pass
  static const String myHealthPass = 'My Health Pass';

  // Coming Soon
  static const String comingSoon = 'Coming Soon...';
}
