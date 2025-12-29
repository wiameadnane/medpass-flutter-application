import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/premium_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  final bool isCreating;

  const EditProfileScreen({super.key, this.isCreating = false});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal Info Controllers (only used when editing, not creating)
  late TextEditingController _dobController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _countryController;

  // Emergency Contact Controllers
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _emergencyRelationController;

  // Allergies & Conditions Controllers
  late TextEditingController _allergiesController;
  late TextEditingController _conditionsController;
  late TextEditingController _medicationsController;

  // Additional Emergency Contacts (Premium feature)
  List<EmergencyContact> _additionalContacts = [];

  String? _selectedBloodType;
  String? _selectedGender;
  DateTime? _selectedDate;

  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;

    // Personal Info (for edit mode)
    _dobController = TextEditingController(text: user?.formattedDateOfBirth ?? '');
    _heightController = TextEditingController(
      text: user?.height != null ? user!.height!.toInt().toString() : '',
    );
    _weightController = TextEditingController(
      text: user?.weight != null ? user!.weight!.toInt().toString() : '',
    );
    _countryController = TextEditingController(text: user?.nationality ?? '');
    _selectedBloodType = user?.bloodType;
    _selectedGender = user?.gender;
    _selectedDate = user?.dateOfBirth;

    // Emergency Contact
    _emergencyNameController = TextEditingController(text: user?.emergencyContactName ?? '');
    _emergencyPhoneController = TextEditingController(text: user?.emergencyContactPhone ?? '');
    _emergencyRelationController = TextEditingController(text: user?.emergencyContactRelation ?? '');

    // Additional Emergency Contacts (Premium)
    _additionalContacts = List.from(user?.additionalEmergencyContacts ?? []);

    // Allergies & Conditions (comma-separated)
    _allergiesController = TextEditingController(
      text: user?.allergies.join(', ') ?? '',
    );
    _conditionsController = TextEditingController(
      text: user?.medicalConditions.join(', ') ?? '',
    );
    _medicationsController = TextEditingController(
      text: user?.currentMedications.join(', ') ?? '',
    );
  }

  @override
  void dispose() {
    _dobController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _countryController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  List<String> _parseCommaSeparated(String text) {
    if (text.trim().isEmpty) return [];
    return text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = context.read<UserProvider>();

    // Build update params based on mode
    final success = await userProvider.updateProfile(
      // Only update personal info if editing (not creating - those are from signup)
      dateOfBirth: widget.isCreating ? null : _selectedDate,
      gender: widget.isCreating ? null : _selectedGender,
      nationality: widget.isCreating ? null : (_countryController.text.trim().isNotEmpty ? _countryController.text.trim() : null),
      // Always update these
      bloodType: _selectedBloodType,
      height: double.tryParse(_heightController.text),
      weight: double.tryParse(_weightController.text),
      emergencyContactName: _emergencyNameController.text.trim(),
      emergencyContactPhone: _emergencyPhoneController.text.trim(),
      emergencyContactRelation: _emergencyRelationController.text.trim(),
      additionalEmergencyContacts: _additionalContacts,
      allergies: _parseCommaSeparated(_allergiesController.text),
      medicalConditions: _parseCommaSeparated(_conditionsController.text),
      currentMedications: _parseCommaSeparated(_medicationsController.text),
    );

    if (success && mounted) {
      if (widget.isCreating) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        Navigator.pop(context);
      }
      AppSnackBar.showSuccess(
        context,
        widget.isCreating ? 'Profile created successfully' : 'Profile updated successfully',
      );
    }
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Add Emergency Contact',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Name *',
                    hintText: 'John Doe',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    hintText: '+1 234 567 8900',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: relationController,
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    hintText: 'e.g., Spouse, Parent',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              final relation = relationController.text.trim();

              if (name.isEmpty || phone.isEmpty) {
                AppSnackBar.showError(context, 'Name and phone number are required');
                return;
              }

              setState(() {
                _additionalContacts.add(EmergencyContact(
                  name: name,
                  phone: phone,
                  relation: relation.isNotEmpty ? relation : null,
                ));
              });

              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Add Contact'),
          ),
        ],
      ),
    );
  }

  void _handleSkip() {
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight(context),
      appBar: widget.isCreating
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: AppTheme.textDark(context)),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Edit Profile',
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingL,
              AppSizes.paddingS,
              AppSizes.paddingL,
              AppSizes.paddingL,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isCreating) ...[
                    // Logo for create mode
                    Center(
                      child: Image.asset(
                        'assets/images/medpass_logo.png',
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ).animate().fadeIn(duration: 500.ms),
                    const SizedBox(height: AppSizes.paddingM),

                    // Title
                    Center(
                      child: Text(
                        'Medical Information',
                        style: GoogleFonts.dmSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark(context),
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

                    const SizedBox(height: AppSizes.paddingS),

                    Center(
                      child: Text(
                        'This information helps medical professionals\nin case of emergencies',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 150.ms),

                    const SizedBox(height: AppSizes.paddingS),

                    // Optional notice
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingM,
                          vertical: AppSizes.paddingS,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(AppSizes.radiusM),
                        ),
                        child: Text(
                          'All fields are optional - you can fill them later',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

                    const SizedBox(height: AppSizes.paddingL),
                  ],

                  // ==========================================
                  // CRITICAL MEDICAL INFO
                  // ==========================================
                  _buildSectionHeader(
                    'Critical Medical Info',
                    Icons.emergency_rounded,
                    AppColors.emergency,
                  ).animate().fadeIn(duration: 500.ms, delay: 250.ms),

                  const SizedBox(height: AppSizes.paddingM),

                  // Blood Type
                  _buildDropdownField(
                    label: 'Blood Type',
                    value: _selectedBloodType,
                    items: _bloodTypes,
                    icon: Icons.bloodtype_rounded,
                    iconColor: AppColors.bloodType,
                    onChanged: (value) {
                      setState(() {
                        _selectedBloodType = value;
                      });
                    },
                  ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

                  const SizedBox(height: AppSizes.paddingM),

                  // Allergies
                  _buildTextFieldWithIcon(
                    label: 'Allergies',
                    hint: 'e.g., Penicillin, Peanuts, Latex',
                    controller: _allergiesController,
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppColors.allergy,
                    helperText: 'Separate multiple allergies with commas',
                  ).animate().fadeIn(duration: 500.ms, delay: 350.ms),

                  const SizedBox(height: AppSizes.paddingM),

                  // Medical Conditions
                  _buildTextFieldWithIcon(
                    label: 'Medical Conditions',
                    hint: 'e.g., Diabetes, Asthma, Heart Disease',
                    controller: _conditionsController,
                    icon: Icons.medical_information_rounded,
                    iconColor: AppColors.primary,
                    helperText: 'Separate multiple conditions with commas',
                  ).animate().fadeIn(duration: 500.ms, delay: 400.ms),

                  const SizedBox(height: AppSizes.paddingM),

                  // Current Medications
                  _buildTextFieldWithIcon(
                    label: 'Current Medications',
                    hint: 'e.g., Aspirin, Insulin, Ventolin',
                    controller: _medicationsController,
                    icon: Icons.medication_rounded,
                    iconColor: AppColors.medication,
                    helperText: 'Separate multiple medications with commas',
                  ).animate().fadeIn(duration: 500.ms, delay: 450.ms),

                  const SizedBox(height: AppSizes.paddingXL),

                  // ==========================================
                  // PHYSICAL INFO (Height/Weight)
                  // ==========================================
                  _buildSectionHeader(
                    'Physical Information',
                    Icons.straighten_rounded,
                    AppColors.accent,
                  ).animate().fadeIn(duration: 500.ms, delay: 500.ms),

                  const SizedBox(height: AppSizes.paddingM),

                  // Height & Weight Row
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Height',
                          hint: '170',
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          suffixIcon: Padding(
                            padding: const EdgeInsets.all(AppSizes.paddingM),
                            child: Text(
                              'cm',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingM),
                      Expanded(
                        child: CustomTextField(
                          label: 'Weight',
                          hint: '65',
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          suffixIcon: Padding(
                            padding: const EdgeInsets.all(AppSizes.paddingM),
                            child: Text(
                              'kg',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms, delay: 550.ms),

                  const SizedBox(height: AppSizes.paddingXL),

                  // ==========================================
                  // EMERGENCY CONTACT
                  // ==========================================
                  _buildSectionHeader(
                    'Emergency Contact',
                    Icons.contact_phone_rounded,
                    AppColors.primary,
                  ).animate().fadeIn(duration: 500.ms, delay: 600.ms),

                  const SizedBox(height: AppSizes.paddingM),

                  CustomTextField(
                    label: 'Contact Name',
                    hint: 'John Doe',
                    controller: _emergencyNameController,
                  ).animate().fadeIn(duration: 500.ms, delay: 650.ms),

                  const SizedBox(height: AppSizes.paddingM),

                  CustomTextField(
                    label: 'Contact Phone',
                    hint: '+1 234 567 8900',
                    controller: _emergencyPhoneController,
                    keyboardType: TextInputType.phone,
                  ).animate().fadeIn(duration: 500.ms, delay: 700.ms),

                  const SizedBox(height: AppSizes.paddingM),

                  CustomTextField(
                    label: 'Relationship',
                    hint: 'e.g., Spouse, Parent, Sibling',
                    controller: _emergencyRelationController,
                  ).animate().fadeIn(duration: 500.ms, delay: 750.ms),

                  const SizedBox(height: AppSizes.paddingM),

                  // Additional Emergency Contacts (Premium Feature)
                  Consumer<UserProvider>(
                    builder: (context, userProvider, _) {
                      final isPremium = userProvider.user?.isPremium ?? false;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Show existing additional contacts for premium users
                          if (isPremium && _additionalContacts.isNotEmpty) ...[
                            ..._additionalContacts.asMap().entries.map((entry) {
                              final index = entry.key;
                              final contact = entry.value;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            contact.name,
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${contact.phone}${contact.relation != null ? ' • ${contact.relation}' : ''}',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                      onPressed: () {
                                        setState(() {
                                          _additionalContacts.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],

                          // Add More button
                          GestureDetector(
                            onTap: () async {
                              if (!isPremium) {
                                await PremiumFeatureDialog.show(
                                  context: context,
                                  featureName: 'Multiple Emergency Contacts',
                                  description: 'Add multiple emergency contacts so your loved ones can be reached in case of emergency. Available with Premium.',
                                  icon: Icons.contact_phone_outlined,
                                );
                                return;
                              }
                              // Show add contact dialog for premium users
                              _showAddContactDialog();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isPremium ? AppColors.primary.withAlpha((0.3 * 255).round()) : Colors.grey.shade300,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    color: isPremium ? AppColors.primary : AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add Emergency Contact',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isPremium ? AppColors.primary : AppColors.textSecondary,
                                    ),
                                  ),
                                  if (!isPremium) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [AppColors.warning, Color(0xFFFFB347)],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded, size: 12, color: Colors.white),
                                          const SizedBox(width: 2),
                                          Text(
                                            'Premium',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ).animate().fadeIn(duration: 500.ms, delay: 780.ms),

                  // ==========================================
                  // PERSONAL INFO (Only show when EDITING, not creating)
                  // ==========================================
                  if (!widget.isCreating) ...[
                    const SizedBox(height: AppSizes.paddingXL),

                    _buildSectionHeader(
                      'Personal Information',
                      Icons.person_rounded,
                      AppColors.info,
                    ).animate().fadeIn(duration: 500.ms, delay: 800.ms),

                    const SizedBox(height: AppSizes.paddingM),

                    // Date of Birth
                    CustomTextField(
                      label: 'Date of Birth',
                      hint: 'DD/MM/YYYY',
                      controller: _dobController,
                      readOnly: true,
                      onTap: _selectDate,
                      suffixIcon: const Icon(Icons.calendar_today, color: AppColors.textSecondary),
                    ).animate().fadeIn(duration: 500.ms, delay: 850.ms),

                    const SizedBox(height: AppSizes.paddingM),

                    // Gender
                    _buildDropdownField(
                      label: 'Gender',
                      value: _selectedGender,
                      items: _genders,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                    ).animate().fadeIn(duration: 500.ms, delay: 900.ms),

                    const SizedBox(height: AppSizes.paddingM),

                    // Nationality
                    CustomTextField(
                      label: 'Nationality',
                      hint: 'e.g., Morocco, France, USA',
                      controller: _countryController,
                    ).animate().fadeIn(duration: 500.ms, delay: 950.ms),
                  ],

                  const SizedBox(height: AppSizes.paddingXL),

                  // Save Button
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      return CustomButton(
                        text: userProvider.isLoading
                            ? 'Saving...'
                            : (widget.isCreating ? 'Complete Profile' : 'Save Changes'),
                        onPressed: userProvider.isLoading ? () {} : _handleSave,
                        width: double.infinity,
                      );
                    },
                  ).animate().fadeIn(duration: 500.ms, delay: 800.ms),

                  // Skip button for create mode
                  if (widget.isCreating) ...[
                    const SizedBox(height: AppSizes.paddingM),
                    Center(
                      child: TextButton(
                        onPressed: _handleSkip,
                        child: Text(
                          'Skip for now',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 850.ms),
                  ],

                  if (!widget.isCreating) ...[
                    const SizedBox(height: AppSizes.paddingM),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSizes.paddingXL),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(
          color: color.withAlpha((0.3 * 255).round()),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: AppSizes.paddingS),
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldWithIcon({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    String? helperText,
  }) {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: AppSizes.paddingS),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingS),
          TextFormField(
            controller: controller,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppTheme.textPrimary(context),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textMuted(context),
              ),
              filled: true,
              fillColor: AppTheme.backgroundCard(context),
              contentPadding: const EdgeInsets.all(AppSizes.paddingM),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
                borderSide: BorderSide(color: AppTheme.inputBorder(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
                borderSide: BorderSide(color: AppTheme.inputBorder(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
                borderSide: BorderSide(color: iconColor, width: 2),
              ),
            ),
          ),
          if (helperText != null) ...[
            const SizedBox(height: AppSizes.paddingXS),
            Text(
              helperText,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppTheme.textMuted(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    IconData? icon,
    Color? iconColor,
  }) {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor ?? AppTheme.textSecondary(context), size: 20),
                const SizedBox(width: AppSizes.paddingS),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingS),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
            decoration: BoxDecoration(
              color: AppTheme.backgroundCard(context),
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
              border: Border.all(color: AppTheme.inputBorder(context)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: AppTheme.backgroundCard(context),
                hint: Text(
                  'Select $label',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textMuted(context),
                  ),
                ),
                icon: Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary(context)),
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
