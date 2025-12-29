import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common_widgets.dart';

class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundCard(context),
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ),
        ),
        title: Text(
          AppStrings.profile,
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppTheme.textDark(context),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/edit-profile');
            },
            child: Container(
              margin: const EdgeInsets.only(right: AppSizes.paddingM),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingM,
                vertical: AppSizes.paddingS,
              ),
              decoration: BoxDecoration(
                color: AppTheme.backgroundCard(context),
                borderRadius: BorderRadius.circular(AppSizes.radiusCircle),
              ),
              child: Text(
                AppStrings.edit,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDark(context),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.user;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User name
                Center(
                  child: Text(
                    user?.fullName ?? 'User',
                    style: GoogleFonts.dmSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark(context),
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms),

                const SizedBox(height: AppSizes.paddingL),

                // Personal Info section header
                Text(
                  AppStrings.personalInfo,
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textDark(context),
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

                const SizedBox(height: AppSizes.paddingS),
                Divider(color: AppTheme.divider(context)),
                const SizedBox(height: AppSizes.paddingM),

                // Info items
                _buildInfoRow(
                  'DATE OF BIRTH',
                  user?.formattedDateOfBirth ?? 'Not set',
                ).animate().fadeIn(duration: 500.ms, delay: 150.ms),

                const SizedBox(height: AppSizes.paddingM),

                _buildInfoRow(
                  AppStrings.userId.toUpperCase(),
                  user?.id ?? 'N/A',
                ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

                const SizedBox(height: AppSizes.paddingXL),

                // Health metrics
                _buildHealthMetric(
                  Icons.bloodtype_rounded,
                  'Blood Type',
                  user?.bloodType ?? 'Not set',
                  AppColors.error.withAlpha((0.1 * 255).round()),
                ).animate().fadeIn(duration: 500.ms, delay: 250.ms),

                const SizedBox(height: AppSizes.paddingM),

                _buildHealthMetric(
                  Icons.fitness_center_rounded,
                  'Weight',
                  user?.formattedWeight ?? 'Not set',
                  AppColors.accent.withAlpha((0.1 * 255).round()),
                ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

                const SizedBox(height: AppSizes.paddingM),

                _buildHealthMetric(
                  Icons.height_rounded,
                  'Height',
                  user?.formattedHeight ?? 'Not set',
                  AppColors.primary.withAlpha((0.1 * 255).round()),
                ).animate().fadeIn(duration: 500.ms, delay: 350.ms),

                const SizedBox(height: AppSizes.paddingM),

                _buildHealthMetric(
                  Icons.flag_rounded,
                  'Nationality',
                  user?.nationality ?? 'Not set',
                  AppColors.warning.withAlpha((0.1 * 255).round()),
                ).animate().fadeIn(duration: 500.ms, delay: 400.ms),

                const SizedBox(height: AppSizes.paddingM),

                _buildHealthMetric(
                  Icons.person_rounded,
                  'Gender',
                  user?.gender ?? 'Not set',
                  AppColors.primaryLight.withAlpha((0.1 * 255).round()),
                ).animate().fadeIn(duration: 500.ms, delay: 450.ms),

                const SizedBox(height: AppSizes.paddingXL),

                // Critical Medical Info section
                Text(
                  'CRITICAL MEDICAL INFO',
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: AppColors.emergency,
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 500.ms),

                const SizedBox(height: AppSizes.paddingS),
                Divider(color: AppTheme.divider(context)),
                const SizedBox(height: AppSizes.paddingM),

                // Allergies
                _buildListSection(
                  Icons.warning_amber_rounded,
                  'Allergies',
                  user?.allergies ?? [],
                  AppColors.allergy,
                ).animate().fadeIn(duration: 500.ms, delay: 550.ms),

                const SizedBox(height: AppSizes.paddingM),

                // Medical Conditions
                _buildListSection(
                  Icons.medical_information_rounded,
                  'Medical Conditions',
                  user?.medicalConditions ?? [],
                  AppColors.info,
                ).animate().fadeIn(duration: 500.ms, delay: 600.ms),

                const SizedBox(height: AppSizes.paddingM),

                // Current Medications
                _buildListSection(
                  Icons.medication_rounded,
                  'Current Medications',
                  user?.currentMedications ?? [],
                  AppColors.medication,
                ).animate().fadeIn(duration: 500.ms, delay: 650.ms),

                const SizedBox(height: AppSizes.paddingXL),

                // Emergency Contact section
                Text(
                  'EMERGENCY CONTACT',
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: AppColors.success,
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 700.ms),

                const SizedBox(height: AppSizes.paddingS),
                Divider(color: AppTheme.divider(context)),
                const SizedBox(height: AppSizes.paddingM),

                _buildEmergencyContactCard(
                  name: user?.emergencyContactName,
                  phone: user?.emergencyContactPhone,
                  relation: user?.emergencyContactRelation,
                  isPrimary: true,
                ).animate().fadeIn(duration: 500.ms, delay: 750.ms),

                // Additional Emergency Contacts
                if (user?.additionalEmergencyContacts.isNotEmpty ?? false) ...[
                  const SizedBox(height: AppSizes.paddingM),
                  ...user!.additionalEmergencyContacts.asMap().entries.map((entry) {
                    final contact = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.paddingS),
                      child: _buildEmergencyContactCard(
                        name: contact.name,
                        phone: contact.phone,
                        relation: contact.relation,
                        isPrimary: false,
                      ),
                    );
                  }).toList(),
                ],

                const SizedBox(height: AppSizes.paddingXL),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Builder(
      builder: (context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark(context),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetric(IconData icon, String label, String value, Color bgColor) {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingS),
              decoration: BoxDecoration(
                color: AppTheme.backgroundCard(context),
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              child: Icon(icon, size: 24, color: AppTheme.textDark(context)),
            ),
            const SizedBox(width: AppSizes.paddingM),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textDark(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListSection(IconData icon, String label, List<String> items, Color color) {
    return Builder(
      builder: (context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: color.withAlpha((0.1 * 255).round()),
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          border: Border.all(color: color.withAlpha((0.3 * 255).round())),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(width: AppSizes.paddingS),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingM),
            if (items.isEmpty)
              Text(
                'None listed',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary(context),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactCard({
    String? name,
    String? phone,
    String? relation,
    bool isPrimary = true,
  }) {
    final hasContact = phone != null && phone.isNotEmpty;
    final cardColor = isPrimary ? AppColors.success : AppColors.primary;

    return Builder(
      builder: (context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: hasContact
              ? cardColor.withAlpha((0.1 * 255).round())
              : AppTheme.backgroundCard(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          border: hasContact
              ? Border.all(color: cardColor.withAlpha((0.3 * 255).round()))
              : null,
        ),
        child: hasContact
            ? Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isPrimary ? AppSizes.paddingM : AppSizes.paddingS),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    ),
                    child: Icon(
                      isPrimary ? Icons.contact_emergency_rounded : Icons.person_rounded,
                      color: Colors.white,
                      size: isPrimary ? 28 : 22,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name ?? 'Contact',
                              style: GoogleFonts.dmSans(
                                fontSize: isPrimary ? 18 : 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark(context),
                              ),
                            ),
                            if (isPrimary) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Primary',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (relation != null && relation.isNotEmpty)
                          Text(
                            relation,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                        const SizedBox(height: AppSizes.paddingXS),
                        Text(
                          phone,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cardColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Center(
                child: Text(
                  'No emergency contact set',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ),
      ),
    );
  }
}
