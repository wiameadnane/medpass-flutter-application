import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final preferredLang = userProvider.user?.preferredLanguage ?? 'en';
    final preferredLangDisplay = UserModel.supportedLanguages[preferredLang] ?? 'English';
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Section
              _buildSectionHeader('Account').animate().fadeIn(duration: 300.ms),
              const SizedBox(height: AppSizes.paddingS),
              _buildSettingsCard(context, [
                _SettingsTile(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                ),
                _SettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () => _showChangePasswordDialog(context),
                ),
                _SettingsTile(
                  icon: Icons.email_outlined,
                  title: 'Email Preferences',
                  onTap: () => _showComingSoon(context),
                ),
              ]).animate().fadeIn(duration: 300.ms, delay: 100.ms),

              const SizedBox(height: AppSizes.paddingL),

              // Preferences Section
              _buildSectionHeader(
                'Preferences',
              ).animate().fadeIn(duration: 300.ms, delay: 150.ms),
              const SizedBox(height: AppSizes.paddingS),
              _buildSettingsCard(context, [
                _SettingsTile(
                  icon: Icons.language,
                  title: 'Translation Language',
                  trailing: Text(
                    preferredLangDisplay,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () => _showLanguageDialog(context, preferredLang),
                ),
                _SettingsTile(
                  icon: Icons.straighten,
                  title: 'Units',
                  trailing: Text(
                    'Metric',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () => _showUnitsDialog(context),
                ),
                _SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Theme',
                  trailing: Text(
                    themeProvider.themeModeDisplay,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () => _showThemeDialog(context),
                ),
              ]).animate().fadeIn(duration: 300.ms, delay: 200.ms),

              const SizedBox(height: AppSizes.paddingL),

              // Privacy & Security Section
              _buildSectionHeader(
                'Privacy & Security',
              ).animate().fadeIn(duration: 300.ms, delay: 250.ms),
              const SizedBox(height: AppSizes.paddingS),
              _buildSettingsCard(context, [
                _SettingsTile(
                  icon: Icons.fingerprint,
                  title: 'Biometric Lock',
                  trailing: Switch(
                    value: false,
                    onChanged: (value) => _showComingSoon(context),
                    activeThumbColor: AppColors.primary,
                  ),
                  onTap: () => _showComingSoon(context),
                ),
                _SettingsTile(
                  icon: Icons.shield_outlined,
                  title: 'Data Sharing',
                  onTap: () => _showComingSoon(context),
                ),
                _SettingsTile(
                  icon: Icons.download_outlined,
                  title: 'Export My Data',
                  onTap: () => _showComingSoon(context),
                ),
              ]).animate().fadeIn(duration: 300.ms, delay: 300.ms),

              const SizedBox(height: AppSizes.paddingL),

              // Notifications Section
              _buildSectionHeader(
                'Notifications',
              ).animate().fadeIn(duration: 300.ms, delay: 350.ms),
              const SizedBox(height: AppSizes.paddingS),
              _buildSettingsCard(context, [
                _SettingsTile(
                  icon: Icons.medication_outlined,
                  title: 'Medication Reminders',
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {},
                    activeThumbColor: AppColors.primary,
                  ),
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.calendar_today_outlined,
                  title: 'Appointment Alerts',
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {},
                    activeThumbColor: AppColors.primary,
                  ),
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.system_update_outlined,
                  title: 'App Updates',
                  trailing: Switch(
                    value: false,
                    onChanged: (value) {},
                    activeThumbColor: AppColors.primary,
                  ),
                  onTap: () {},
                ),
              ]).animate().fadeIn(duration: 300.ms, delay: 400.ms),

              const SizedBox(height: AppSizes.paddingL),

              // About Section
              _buildSectionHeader(
                'About',
              ).animate().fadeIn(duration: 300.ms, delay: 450.ms),
              const SizedBox(height: AppSizes.paddingS),
              _buildSettingsCard(context, [
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'App Version',
                  trailing: Text(
                    '1.0.0',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () => _showComingSoon(context),
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => _showComingSoon(context),
                ),
              ]).animate().fadeIn(duration: 300.ms, delay: 500.ms),

              const SizedBox(height: AppSizes.paddingL),

              // Danger Zone
              _buildSectionHeader(
                'Danger Zone',
                isDestructive: true,
              ).animate().fadeIn(duration: 300.ms, delay: 550.ms),
              const SizedBox(height: AppSizes.paddingS),
              _buildSettingsCard(context, [
                _SettingsTile(
                  icon: Icons.delete_outline,
                  title: 'Delete Account',
                  iconColor: AppColors.error,
                  textColor: AppColors.error,
                  onTap: () => _showDeleteAccountDialog(context),
                ),
              ]).animate().fadeIn(duration: 300.ms, delay: 600.ms),

              const SizedBox(height: AppSizes.paddingXL),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool isDestructive = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSizes.paddingS),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDestructive ? AppColors.error : AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<_SettingsTile> tiles) {
    return Container(
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
        children: tiles.map((tile) {
          final isLast = tiles.last == tile;
          return Column(
            children: [
              tile,
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 56,
                  color: AppTheme.inputBackground(context).withAlpha(
                    (0.5 * 255).round(),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
          ),
          title: Text(
            'Change Password',
            style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  obscureText: true,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.paddingM),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.paddingM),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value != newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setState(() => isLoading = true);

                      final userProvider = context.read<UserProvider>();
                      final success = await userProvider.changePassword(
                        currentPassword: currentPasswordController.text,
                        newPassword: newPasswordController.text,
                      );

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }

                      if (context.mounted) {
                        if (success) {
                          AppSnackBar.showSuccess(
                            context,
                            'Password changed successfully',
                          );
                        } else {
                          AppSnackBar.showError(
                            context,
                            userProvider.error ?? 'Failed to change password',
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, String currentLang) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        title: Text(
          'Translation Language',
          style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Documents will be translated to this language',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingM),
            ...UserModel.supportedLanguages.entries.map((entry) {
              return _buildLanguageOption(
                context,
                dialogContext,
                entry.key,
                entry.value,
                currentLang == entry.key,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    BuildContext dialogContext,
    String langCode,
    String langName,
    bool isSelected,
  ) {
    return ListTile(
      leading: Icon(
        Icons.translate_rounded,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        size: 20,
      ),
      title: Text(
        langName,
        style: GoogleFonts.inter(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? AppColors.primary : AppColors.textDark,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () async {
        Navigator.pop(dialogContext);
        if (!isSelected) {
          final userProvider = context.read<UserProvider>();
          await userProvider.updateProfile(preferredLanguage: langCode);
          if (context.mounted) {
            AppSnackBar.showSuccess(
              context,
              'Language set to $langName',
            );
          }
        }
      },
    );
  }

  void _showUnitsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        title: Text(
          'Select Units',
          style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Metric (cm, kg)'),
              trailing: const Icon(Icons.check, color: AppColors.primary),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Imperial (ft, lb)'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final currentMode = themeProvider.themeMode;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        title: Text(
          'Select Theme',
          style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Light'),
              trailing: currentMode == AppThemeMode.light
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                themeProvider.setThemeMode(AppThemeMode.light);
                Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark'),
              trailing: currentMode == AppThemeMode.dark
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                themeProvider.setThemeMode(AppThemeMode.dark);
                Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text('System'),
              trailing: currentMode == AppThemeMode.system
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                themeProvider.setThemeMode(AppThemeMode.system);
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
              const SizedBox(width: 8),
              Text(
                'Delete Account',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This action is permanent and cannot be undone. All your data will be deleted:',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingS),
                Text(
                  '• Your medical profile\n'
                  '• All uploaded files\n'
                  '• Emergency contacts\n'
                  '• Account credentials',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingL),
                Text(
                  'Enter your password to confirm:',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingS),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setState(() => isLoading = true);

                      final userProvider = context.read<UserProvider>();
                      final success = await userProvider.deleteAccount(
                        password: passwordController.text,
                      );

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }

                      if (context.mounted) {
                        if (success) {
                          // Navigate to login screen
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                          AppSnackBar.show(
                            context: context,
                            message: 'Account deleted successfully',
                          );
                        } else {
                          AppSnackBar.showError(
                            context,
                            userProvider.error ?? 'Failed to delete account',
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    AppSnackBar.show(context: context, message: 'Coming soon!');
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primary, size: 24),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor ?? AppTheme.textDark(context),
        ),
      ),
      trailing:
          trailing ??
          const Icon(
            Icons.arrow_forward_ios,
            color: AppColors.textSecondary,
            size: 16,
          ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingXS,
      ),
    );
  }
}
