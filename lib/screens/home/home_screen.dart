import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../models/medical_file_model.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common_widgets.dart';
import '../files/file_viewer_screen.dart';
import '../files/upload_file_screen.dart';
import '../help/help_support_screen.dart';
import '../ocr_scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isRefreshing = false;

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.refreshData();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight(context),
      drawer: _buildDrawer(context),
      floatingActionButton: _buildFAB(context),
      body: Builder(
        builder: (context) => SafeArea(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingL,
                  AppSizes.paddingM,
                  AppSizes.paddingL,
                  AppSizes.paddingL,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(context).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: AppSizes.paddingL),

                    // Critical Info Card (Always visible)
                    _buildCriticalInfoCard(context)
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 100.ms)
                        .slideY(begin: -0.1),

                    const SizedBox(height: AppSizes.paddingL),

                    // Quick Actions Row (QR + Emergency)
                    _buildQuickActions(
                      context,
                    ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

                    const SizedBox(height: AppSizes.paddingL),

                    // Main Menu Cards
                    _buildMainMenuSection(context),

                    const SizedBox(height: AppSizes.paddingL),

                    // Recent Files Section
                    _buildRecentFilesSection(
                      context,
                    ).animate().fadeIn(duration: 500.ms, delay: 500.ms),

                    const SizedBox(height: AppSizes.paddingXL),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Menu button
        GestureDetector(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.backgroundCard(context),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadow(context),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.menu_rounded,
              color: AppTheme.textSecondary(context),
              size: 24,
            ),
          ),
        ),
        // App Logo
        Image.asset(
          'assets/images/medpass_logo.png',
          height: 40,
          fit: BoxFit.contain,
        ),
        // Emergency Mode button
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/emergency-mode'),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.backgroundCard(context),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadow(context),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'assets/images/siren.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCriticalInfoCard(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        final hasAllergies = user?.allergies.isNotEmpty ?? false;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.paddingL),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1B4D6E), // Dark navy from logo text
                AppColors.accent,   // Teal from logo icon
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF1B4D6E).withAlpha((0.3 * 255).round()),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User greeting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${user?.fullName.split(' ').first ?? 'User'}',
                        style: GoogleFonts.dmSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Your Health Pass',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withAlpha((0.8 * 255).round()),
                        ),
                      ),
                    ],
                  ),
                  // Premium badge
                  if (user?.isPremium == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingS,
                        vertical: AppSizes.paddingXS,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.2 * 255).round()),
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Premium',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppSizes.paddingL),

              // Critical info row
              Row(
                children: [
                  // Blood Type
                  _buildCriticalInfoItem(
                    icon: Icons.bloodtype_rounded,
                    label: 'Blood',
                    value: user?.bloodType ?? 'N/A',
                    color: Colors.white,
                  ),
                  const SizedBox(width: AppSizes.paddingL),
                  // Allergies indicator
                  Expanded(
                    child: _buildCriticalInfoItem(
                      icon: Icons.warning_amber_rounded,
                      label: 'Allergies',
                      value: hasAllergies
                          ? '${user!.allergies.length} known'
                          : 'None',
                      color: hasAllergies ? AppColors.warning : Colors.white,
                      isWarning: hasAllergies,
                    ),
                  ),
                ],
              ),

              // Show allergies if any
              if (hasAllergies) ...[
                const SizedBox(height: AppSizes.paddingM),
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingS),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha((0.2 * 255).round()),
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_rounded,
                        color: AppColors.warning,
                        size: 16,
                      ),
                      const SizedBox(width: AppSizes.paddingS),
                      Expanded(
                        child: Text(
                          user!.allergies.join(', '),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSizes.paddingL),

              // Emergency contact
              if (user?.emergencyContactPhone != null &&
                  user!.emergencyContactPhone!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingS),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.15 * 255).round()),
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.phone_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: AppSizes.paddingS),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (user.emergencyContactName != null &&
                                user.emergencyContactName!.isNotEmpty)
                              Text(
                                'Emergency: ${user.emergencyContactName}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            Text(
                              user.emergencyContactPhone!,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCriticalInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isWarning = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (isWarning ? AppColors.warning : Colors.white).withAlpha(
              (0.2 * 255).round(),
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppSizes.paddingS),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Colors.white.withAlpha((0.7 * 255).round()),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GestureDetector(
      onTap: () => _showQuickQRCode(context),
      child: Container(
        width: double.infinity,
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingS),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSizes.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Show QR Code',
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark(context),
                    ),
                  ),
                  Text(
                    'Share your health profile instantly',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.textMuted(context),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainMenuSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark(context),
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
        const SizedBox(height: AppSizes.paddingM),
        Row(
          children: [
            Expanded(
              child: _buildMenuCard(
                context,
                icon: Icons.folder_rounded,
                title: 'My Files',
                subtitle: 'Documents',
                color: AppColors.primary,
                onTap: () => Navigator.pushNamed(context, '/my-files'),
              ),
            ),
            const SizedBox(width: AppSizes.paddingM),
            Expanded(
              child: _buildMenuCard(
                context,
                icon: Icons.person_rounded,
                title: 'Profile',
                subtitle: 'View info',
                color: AppColors.accent,
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms, delay: 350.ms),
        const SizedBox(height: AppSizes.paddingM),
        Row(
          children: [
            Expanded(
              child: _buildMenuCard(
                context,
                icon: Icons.credit_card_rounded,
                title: 'Health Card',
                subtitle: 'NFC Card',
                color: AppColors.medication,
                onTap: () => Navigator.pushNamed(context, '/personal-card'),
              ),
            ),
            const SizedBox(width: AppSizes.paddingM),
            Expanded(
              child: _buildMenuCard(
                context,
                icon: Icons.local_hospital_rounded,
                title: 'Emergency',
                subtitle: 'Contacts',
                color: AppColors.emergency,
                onTap: () => Navigator.pushNamed(context, '/emergency'),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
      ],
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
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
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingS),
              decoration: BoxDecoration(
                color: color.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: AppSizes.paddingM),
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
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentFilesSection(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final recentFiles = userProvider.medicalFiles.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Files',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark(context),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/my-files'),
                  child: Text(
                    'See All',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingM),
            if (recentFiles.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.paddingXL),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundCard(context),
                  borderRadius: BorderRadius.circular(AppSizes.radiusL),
                  border: Border.all(
                    color: AppTheme.divider(context),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 48,
                      color: AppTheme.textMuted(context),
                    ),
                    const SizedBox(height: AppSizes.paddingM),
                    Text(
                      'No files yet',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingXS),
                    Text(
                      'Add your first medical document',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textMuted(context),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...recentFiles.map(
                (file) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.paddingS),
                  child: _buildRecentFileItem(context, file),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRecentFileItem(BuildContext context, MedicalFileModel file) {
    return GestureDetector(
      onTap: () => _openFile(context, file),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: AppTheme.backgroundCard(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadow(context),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingS),
              decoration: BoxDecoration(
                color: AppColors.document.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: const Icon(
                Icons.description_rounded,
                color: AppColors.document,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSizes.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    file.categoryName,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
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

  void _openFile(BuildContext context, MedicalFileModel file) {
    // Image files: show in dialog
    if (file.fileUrl != null && file.isImage) {
      showDialog(
        context: context,
        builder: (dialogContext) => Dialog(
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
                    backgroundColor: Colors.white.withAlpha((0.9 * 255).round()),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textDark),
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

    // Other files with URL: offer to open externally
    if (file.fileUrl != null) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(file.name),
          content: Text(file.description ?? 'Open this file in an external viewer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final uri = Uri.tryParse(file.fileUrl!);
                if (uri == null) {
                  AppSnackBar.showError(context, 'Invalid file URL');
                  return;
                }
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (e) {
                  AppSnackBar.showError(context, 'Failed to open file: $e');
                }
              },
              child: const Text('Open'),
            ),
          ],
        ),
      );
      return;
    }

    // No URL: show info
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(file.name),
        content: Text(file.description ?? 'No file available to preview.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showQuickQRCode(BuildContext context) {
    final user = context.read<UserProvider>().user;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          decoration: BoxDecoration(
            color: AppTheme.backgroundCard(sheetContext),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusXL),
            ),
          ),
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
              const SizedBox(height: AppSizes.paddingM),
              Text(
                'Your Health Pass',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark(sheetContext),
                ),
              ),
              const SizedBox(height: AppSizes.paddingM),
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight(sheetContext),
                  borderRadius: BorderRadius.circular(AppSizes.radiusL),
                ),
                child: QrImageView(
                  data: user?.emergencyQrData ?? 'No emergency data',
                  version: QrVersions.auto,
                  size: 160,
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
              ),
              const SizedBox(height: AppSizes.paddingM),
              Text(
                'Scan for emergency info',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary(sheetContext),
                ),
              ),
              const SizedBox(height: AppSizes.paddingM),
              GestureDetector(
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.pushNamed(context, '/qr-code');
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
                      'View Full Screen',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingS),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showUploadOptionsDialog(context),
      backgroundColor: AppColors.accentDark,
      elevation: 8,
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
    );
  }

  void _showUploadOptionsDialog(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: AppTheme.backgroundCard(parentContext),
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
                'Add Document',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark(sheetContext),
                ),
              ),
              const SizedBox(height: AppSizes.paddingS),
              Text(
                'Choose how to add your document',
                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary(sheetContext)),
              ),
              const SizedBox(height: AppSizes.paddingL),

              // Scan Document Option
              _buildUploadOption(
                context: sheetContext,
                icon: Icons.document_scanner_rounded,
                title: 'Scan Document',
                subtitle: 'Camera scan with OCR & translation',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    parentContext,
                    MaterialPageRoute(
                      builder: (context) => const OCRScanScreen(),
                      settings: const RouteSettings(arguments: {'autoShowDialog': true}),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSizes.paddingM),

              // Upload PDF Option
              _buildUploadOption(
                context: sheetContext,
                icon: Icons.picture_as_pdf_rounded,
                title: 'Upload PDF',
                subtitle: 'Import existing PDF file directly',
                color: AppColors.accent,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _pickAndUploadPdf(parentContext);
                },
              ),
              const SizedBox(height: AppSizes.paddingL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadOption({
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
              child: Icon(icon, color: color, size: 28),
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
                      fontSize: 13,
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

  Future<void> _pickAndUploadPdf(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Navigate directly to upload screen with the PDF
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UploadFileScreen(initialFile: file),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, 'Error picking file: $e');
      }
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.backgroundCard(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(AppSizes.radiusL),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingL),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1B4D6E), // Dark navy from logo text
                    AppColors.accent,   // Teal from logo icon
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.2 * 255).round()),
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingM),
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      final user = userProvider.user;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'User',
                            style: GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSizes.paddingXS),
                          Text(
                            user?.email ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withAlpha(
                                (0.8 * 255).round(),
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.paddingM),

            // Menu Items
            _buildDrawerItem(
              icon: Icons.person_outline_rounded,
              title: 'My Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            _buildDrawerItem(
              icon: Icons.folder_outlined,
              title: 'My Files',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/my-files');
              },
            ),
            _buildDrawerItem(
              icon: Icons.credit_card_outlined,
              title: 'Billing & Plans',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/billing');
              },
            ),

            Divider(
              color: AppTheme.divider(context),
              indent: AppSizes.paddingL,
              endIndent: AppSizes.paddingL,
            ),

            _buildDrawerItem(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            _buildDrawerItem(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                );
              },
            ),

            const Spacer(),

            // Logout button
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              child: Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  return GestureDetector(
                    onTap: () async {
                      if (!context.mounted) return;
                      final confirmed = await ConfirmDialog.showLogout(context);
                      if (confirmed && context.mounted) {
                        await userProvider.logout();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/',
                            (route) => false,
                          );
                        }
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSizes.paddingM),
                      decoration: BoxDecoration(
                        color: AppColors.emergency.withAlpha(
                          (0.1 * 255).round(),
                        ),
                        borderRadius: BorderRadius.circular(AppSizes.radiusL),
                        border: Border.all(
                          color: AppColors.emergency.withAlpha(
                            (0.3 * 255).round(),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.logout_rounded,
                            color: AppColors.emergency,
                            size: 20,
                          ),
                          const SizedBox(width: AppSizes.paddingS),
                          Text(
                            'Logout',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.emergency,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) => ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 24),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.textDark(context),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppTheme.textSecondary(context),
          size: 16,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
      ),
    );
  }
}
