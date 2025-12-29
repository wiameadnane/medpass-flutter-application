import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common_widgets.dart';

/// High-contrast Emergency Mode screen that displays critical medical info
/// Designed for: offline access, high visibility, quick access to critical data
class EmergencyModeScreen extends StatefulWidget {
  const EmergencyModeScreen({super.key});

  @override
  State<EmergencyModeScreen> createState() => _EmergencyModeScreenState();
}

class _EmergencyModeScreenState extends State<EmergencyModeScreen> {
  @override
  void initState() {
    super.initState();
    // Set system UI to dark theme for emergency mode
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    // Reset system UI when leaving
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  Future<void> _callEmergencyContact(String? phone) async {
    if (phone == null || phone.isEmpty) return;

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    try {
      await launchUrl(launchUri);
    } catch (e) {
      debugPrint('Could not launch $launchUri');
    }
  }

  void _showQRCode(BuildContext context) {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppTheme.backgroundCard(dialogContext),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MEDICAL QR CODE',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark(dialogContext),
                ),
              ),
              const SizedBox(height: AppSizes.paddingM),
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: QrImageView(
                  data: user.emergencyQrData,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.emergency,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingM),
              Text(
                'Scan for emergency info',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary(dialogContext),
                ),
              ),
              Text(
                'Works offline',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary(dialogContext).withAlpha((0.7 * 255).round()),
                ),
              ),
              const SizedBox(height: AppSizes.paddingM),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Close',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.emergency,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Dark background for contrast
      body: SafeArea(
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            final user = userProvider.user;

            return Column(
              children: [
                // Header with exit and QR buttons
                Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Exit button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingM,
                            vertical: AppSizes.paddingS,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((0.1 * 255).round()),
                            borderRadius: BorderRadius.circular(AppSizes.radiusM),
                            border: Border.all(
                              color: Colors.white.withAlpha((0.3 * 255).round()),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: AppSizes.paddingXS),
                              Text(
                                'EXIT',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // QR Code button
                      GestureDetector(
                        onTap: () => _showQRCode(context),
                        child: Container(
                          padding: const EdgeInsets.all(AppSizes.paddingS),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppSizes.radiusM),
                          ),
                          child: const Icon(
                            Icons.qr_code_rounded,
                            color: Color(0xFF1A1A2E),
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Emergency Mode Title
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingL,
                    vertical: AppSizes.paddingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emergency,
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: AppSizes.paddingS),
                      Text(
                        'EMERGENCY MODE',
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.paddingL),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
                    child: Column(
                      children: [
                        // Blood Type - Large and prominent
                        _buildBloodTypeCard(user?.bloodType),

                        const SizedBox(height: AppSizes.paddingM),

                        // Allergies - Critical
                        _buildCriticalInfoCard(
                          title: 'ALLERGIES',
                          icon: Icons.warning_amber_rounded,
                          color: AppColors.allergy,
                          items: user?.allergies ?? [],
                          emptyText: 'No known allergies',
                        ),

                        const SizedBox(height: AppSizes.paddingM),

                        // Medical Conditions
                        _buildCriticalInfoCard(
                          title: 'MEDICAL CONDITIONS',
                          icon: Icons.medical_information_rounded,
                          color: AppColors.info,
                          items: user?.medicalConditions ?? [],
                          emptyText: 'No known conditions',
                        ),

                        const SizedBox(height: AppSizes.paddingM),

                        // Current Medications
                        _buildCriticalInfoCard(
                          title: 'CURRENT MEDICATIONS',
                          icon: Icons.medication_rounded,
                          color: AppColors.medication,
                          items: user?.currentMedications ?? [],
                          emptyText: 'No current medications',
                        ),

                        const SizedBox(height: AppSizes.paddingL),

                        // Emergency Contact - Large call button
                        _buildEmergencyContactCard(
                          name: user?.emergencyContactName,
                          phone: user?.emergencyContactPhone,
                          relation: user?.emergencyContactRelation,
                        ),

                        const SizedBox(height: AppSizes.paddingM),

                        // User Identity Card
                        _buildIdentityCard(
                          name: user?.fullName ?? 'Unknown',
                          id: user?.id ?? '',
                          dob: user?.formattedDateOfBirth,
                          nationality: user?.nationality,
                        ),

                        const SizedBox(height: AppSizes.paddingXL),

                        // Emergency Services Button
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/emergency'),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSizes.paddingM),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha((0.1 * 255).round()),
                              borderRadius: BorderRadius.circular(AppSizes.radiusM),
                              border: Border.all(
                                color: Colors.white.withAlpha((0.3 * 255).round()),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.phone_in_talk_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: AppSizes.paddingS),
                                Text(
                                  'CALL EMERGENCY SERVICES',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSizes.paddingXL),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBloodTypeCard(String? bloodType) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.emergencyGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: Column(
        children: [
          Text(
            'BLOOD TYPE',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withAlpha((0.8 * 255).round()),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AppSizes.paddingS),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingXL,
              vertical: AppSizes.paddingM,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: Text(
              bloodType ?? '---',
              style: GoogleFonts.dmSans(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: AppColors.emergency,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
    required String emptyText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: color.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(
          color: color.withAlpha((0.5 * 255).round()),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: AppSizes.paddingS),
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingM),
          if (items.isEmpty)
            Text(
              emptyText,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white.withAlpha((0.7 * 255).round()),
              ),
            )
          else
            Wrap(
              spacing: AppSizes.paddingS,
              runSpacing: AppSizes.paddingS,
              children: items.map((item) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingM,
                  vertical: AppSizes.paddingS,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Text(
                  item,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard({
    String? name,
    String? phone,
    String? relation,
  }) {
    final hasContact = phone != null && phone.isNotEmpty;

    return GestureDetector(
      onTap: hasContact ? () => _callEmergencyContact(phone) : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.paddingL),
        decoration: BoxDecoration(
          color: hasContact
              ? AppColors.success.withAlpha((0.2 * 255).round())
              : Colors.white.withAlpha((0.1 * 255).round()),
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          border: Border.all(
            color: hasContact
                ? AppColors.success
                : Colors.white.withAlpha((0.3 * 255).round()),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.contact_emergency_rounded,
                  color: hasContact ? AppColors.success : Colors.white.withAlpha((0.5 * 255).round()),
                  size: 24,
                ),
                const SizedBox(width: AppSizes.paddingS),
                Text(
                  'EMERGENCY CONTACT',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: hasContact ? AppColors.success : Colors.white.withAlpha((0.5 * 255).round()),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingM),
            if (!hasContact)
              Text(
                'No emergency contact set',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withAlpha((0.5 * 255).round()),
                ),
              )
            else
              Column(
                children: [
                  Text(
                    name ?? 'Unknown',
                    style: GoogleFonts.dmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (relation != null && relation.isNotEmpty)
                    Text(
                      relation,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withAlpha((0.7 * 255).round()),
                      ),
                    ),
                  const SizedBox(height: AppSizes.paddingM),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingL,
                      vertical: AppSizes.paddingM,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.call_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: AppSizes.paddingS),
                        Text(
                          'TAP TO CALL',
                          style: GoogleFonts.dmSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingS),
                  Text(
                    phone,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withAlpha((0.8 * 255).round()),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityCard({
    required String name,
    required String id,
    String? dob,
    String? nationality,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(
          color: Colors.white.withAlpha((0.2 * 255).round()),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_rounded,
                color: Colors.white54,
                size: 20,
              ),
              const SizedBox(width: AppSizes.paddingS),
              Text(
                'PATIENT IDENTITY',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingM),
          Text(
            name,
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSizes.paddingS),
          Row(
            children: [
              if (dob != null && dob.isNotEmpty) ...[
                Text(
                  'DOB: $dob',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: AppSizes.paddingM),
              ],
              if (nationality != null && nationality.isNotEmpty)
                Text(
                  nationality,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingS),
          Text(
            'ID: $id',
            style: GoogleFonts.robotoMono(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}
