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

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Account Info
  final _step1FormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Step 1 continued: Preferred Language
  String _selectedPreferredLanguage = 'en';

  // Step 2: Personal Info
  final _dobController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedNationality;

  // Step 3: Medical Info
  String? _selectedBloodType;
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  static const List<String> _countries = [
    'Afghanistan', 'Albania', 'Algeria', 'Andorra', 'Angola', 'Argentina',
    'Armenia', 'Australia', 'Austria', 'Azerbaijan', 'Bahamas', 'Bahrain',
    'Bangladesh', 'Barbados', 'Belarus', 'Belgium', 'Belize', 'Benin',
    'Bhutan', 'Bolivia', 'Bosnia and Herzegovina', 'Botswana', 'Brazil',
    'Brunei', 'Bulgaria', 'Burkina Faso', 'Burundi', 'Cambodia', 'Cameroon',
    'Canada', 'Cape Verde', 'Central African Republic', 'Chad', 'Chile',
    'China', 'Colombia', 'Comoros', 'Congo', 'Costa Rica', 'Croatia', 'Cuba',
    'Cyprus', 'Czech Republic', 'Denmark', 'Djibouti', 'Dominican Republic',
    'Ecuador', 'Egypt', 'El Salvador', 'Equatorial Guinea', 'Eritrea',
    'Estonia', 'Eswatini', 'Ethiopia', 'Fiji', 'Finland', 'France', 'Gabon',
    'Gambia', 'Georgia', 'Germany', 'Ghana', 'Greece', 'Grenada', 'Guatemala',
    'Guinea', 'Guinea-Bissau', 'Guyana', 'Haiti', 'Honduras', 'Hungary',
    'Iceland', 'India', 'Indonesia', 'Iran', 'Iraq', 'Ireland', 'Israel',
    'Italy', 'Ivory Coast', 'Jamaica', 'Japan', 'Jordan', 'Kazakhstan',
    'Kenya', 'Kiribati', 'Kuwait', 'Kyrgyzstan', 'Laos', 'Latvia', 'Lebanon',
    'Lesotho', 'Liberia', 'Libya', 'Liechtenstein', 'Lithuania', 'Luxembourg',
    'Madagascar', 'Malawi', 'Malaysia', 'Maldives', 'Mali', 'Malta',
    'Mauritania', 'Mauritius', 'Mexico', 'Moldova', 'Monaco', 'Mongolia',
    'Montenegro', 'Morocco', 'Mozambique', 'Myanmar', 'Namibia', 'Nepal',
    'Netherlands', 'New Zealand', 'Nicaragua', 'Niger', 'Nigeria',
    'North Korea', 'North Macedonia', 'Norway', 'Oman', 'Pakistan', 'Panama',
    'Papua New Guinea', 'Paraguay', 'Peru', 'Philippines', 'Poland',
    'Portugal', 'Qatar', 'Romania', 'Russia', 'Rwanda', 'Saudi Arabia',
    'Senegal', 'Serbia', 'Sierra Leone', 'Singapore', 'Slovakia', 'Slovenia',
    'Somalia', 'South Africa', 'South Korea', 'South Sudan', 'Spain',
    'Sri Lanka', 'Sudan', 'Suriname', 'Sweden', 'Switzerland', 'Syria',
    'Taiwan', 'Tajikistan', 'Tanzania', 'Thailand', 'Togo', 'Tonga',
    'Trinidad and Tobago', 'Tunisia', 'Turkey', 'Turkmenistan', 'Uganda',
    'Ukraine', 'United Arab Emirates', 'United Kingdom', 'United States',
    'Uruguay', 'Uzbekistan', 'Venezuela', 'Vietnam', 'Yemen', 'Zambia',
    'Zimbabwe',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _medicationsController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_step1FormKey.currentState!.validate()) return;
    }

    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
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

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CountryPickerSheet(
        countries: _countries,
        selectedCountry: _selectedNationality,
        onSelected: (country) {
          setState(() {
            _selectedNationality = country;
          });
        },
      ),
    );
  }

  List<String> _parseCommaSeparated(String text) {
    if (text.trim().isEmpty) return [];
    return text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<void> _handleSignUp() async {
    final userProvider = context.read<UserProvider>();

    // Create account
    final success = await userProvider.signUp(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text,
      dateOfBirth: _selectedDate,
      gender: _selectedGender,
      nationality: _selectedNationality,
      preferredLanguage: _selectedPreferredLanguage,
    );

    if (!success) {
      if (mounted) {
        AppSnackBar.showError(context, userProvider.error ?? 'Sign up failed');
      }
      return;
    }

    // Update medical info
    await userProvider.updateProfile(
      bloodType: _selectedBloodType,
      height: double.tryParse(_heightController.text),
      weight: double.tryParse(_weightController.text),
      allergies: _parseCommaSeparated(_allergiesController.text),
      medicalConditions: _parseCommaSeparated(_conditionsController.text),
      currentMedications: _parseCommaSeparated(_medicationsController.text),
      emergencyContactName: _emergencyNameController.text.trim(),
      emergencyContactPhone: _emergencyPhoneController.text.trim(),
      emergencyContactRelation: _emergencyRelationController.text.trim(),
    );

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and progress
            _buildHeader(),

            // Progress indicator
            _buildProgressIndicator(),

            // Step content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingS,
        AppSizes.paddingS,
        AppSizes.paddingL,
        0,
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () {
              if (_currentStep > 0) {
                _previousStep();
              } else {
                Navigator.pop(context);
              }
            },
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: AppTheme.textDark(context),
            ),
          ),
          const Spacer(),
          // Step indicator
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingM,
              vertical: AppSizes.paddingS,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
            ),
            child: Text(
              '${_currentStep + 1}/3',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingL,
        vertical: AppSizes.paddingM,
      ),
      child: Row(
        children: List.generate(3, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 2 ? AppSizes.paddingS : 0),
              height: 4,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? AppColors.primary
                    : AppColors.inputBackground,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ==========================================
  // STEP 1: Account Information
  // ==========================================
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Create Account',
              style: GoogleFonts.dmSans(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark(context),
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: AppSizes.paddingS),

            Text(
              'Enter your basic information to get started',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary(context),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 50.ms),

            const SizedBox(height: AppSizes.paddingXL),

            // Full Name
            CustomTextField(
              label: 'Full Name',
              hint: 'John Doe',
              controller: _nameController,
              keyboardType: TextInputType.name,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

            const SizedBox(height: AppSizes.paddingM),

            // Email
            CustomTextField(
              label: 'Email',
              hint: 'example@email.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ).animate().fadeIn(duration: 400.ms, delay: 150.ms),

            const SizedBox(height: AppSizes.paddingM),

            // Phone
            CustomTextField(
              label: 'Phone Number',
              hint: '+1 234 567 8900',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

            const SizedBox(height: AppSizes.paddingM),

            // Password
            CustomTextField(
              label: 'Password',
              hint: '••••••••••',
              controller: _passwordController,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ).animate().fadeIn(duration: 400.ms, delay: 250.ms),

            const SizedBox(height: AppSizes.paddingM),

            // Preferred Language
            _buildLanguagePicker().animate().fadeIn(duration: 400.ms, delay: 300.ms),

            const SizedBox(height: AppSizes.paddingXL),

            // Next button
            CustomButton(
              text: 'Continue',
              onPressed: _nextStep,
              width: double.infinity,
            ).animate().fadeIn(duration: 400.ms, delay: 350.ms),

            const SizedBox(height: AppSizes.paddingL),

            // Login link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: Text(
                    'Log In',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms, delay: 350.ms),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STEP 2: Personal Information
  // ==========================================
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Personal Information',
            style: GoogleFonts.dmSans(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark(context),
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: AppSizes.paddingS),

          Text(
            'Help us personalize your health profile',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary(context),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 50.ms),

          const SizedBox(height: AppSizes.paddingS),

          // Optional badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingM,
              vertical: AppSizes.paddingXS,
            ),
            decoration: BoxDecoration(
              color: AppColors.info.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: Text(
              'All fields are optional',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.info,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

          const SizedBox(height: AppSizes.paddingXL),

          // Date of Birth
          CustomTextField(
            label: 'Date of Birth',
            hint: 'DD/MM/YYYY',
            controller: _dobController,
            readOnly: true,
            onTap: _selectDate,
            suffixIcon: const Icon(Icons.calendar_today, color: AppColors.textSecondary),
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),

          const SizedBox(height: AppSizes.paddingM),

          // Gender
          _buildDropdownField(
            label: 'Gender',
            value: _selectedGender,
            hint: 'Select Gender',
            items: _genders,
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
            },
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

          const SizedBox(height: AppSizes.paddingM),

          // Nationality
          _buildNationalityField().animate().fadeIn(duration: 400.ms, delay: 250.ms),

          const SizedBox(height: AppSizes.paddingXL),

          // Next button
          CustomButton(
            text: 'Continue',
            onPressed: _nextStep,
            width: double.infinity,
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

          const SizedBox(height: AppSizes.paddingM),

          // Skip button
          Center(
            child: TextButton(
              onPressed: _nextStep,
              child: Text(
                'Skip for now',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary(context),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 350.ms),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 3: Medical Information
  // ==========================================
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Medical Information',
            style: GoogleFonts.dmSans(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark(context),
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: AppSizes.paddingS),

          Text(
            'This helps medical professionals in emergencies',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary(context),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 50.ms),

          const SizedBox(height: AppSizes.paddingS),

          // Optional badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingM,
              vertical: AppSizes.paddingXS,
            ),
            decoration: BoxDecoration(
              color: AppColors.info.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: Text(
              'All fields are optional - you can add more later',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.info,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

          const SizedBox(height: AppSizes.paddingL),

          // Critical Info Section
          _buildSectionLabel('Critical Info', Icons.emergency_rounded, AppColors.emergency)
              .animate().fadeIn(duration: 400.ms, delay: 150.ms),

          const SizedBox(height: AppSizes.paddingM),

          // Blood Type
          _buildDropdownField(
            label: 'Blood Type',
            value: _selectedBloodType,
            hint: 'Select Blood Type',
            items: _bloodTypes,
            onChanged: (value) {
              setState(() {
                _selectedBloodType = value;
              });
            },
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

          const SizedBox(height: AppSizes.paddingM),

          // Height & Weight
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Height (cm)',
                  hint: '170',
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSizes.paddingM),
              Expanded(
                child: CustomTextField(
                  label: 'Weight (kg)',
                  hint: '65',
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 250.ms),

          const SizedBox(height: AppSizes.paddingM),

          // Allergies
          CustomTextField(
            label: 'Allergies',
            hint: 'e.g., Penicillin, Peanuts (comma separated)',
            controller: _allergiesController,
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

          const SizedBox(height: AppSizes.paddingM),

          // Medical Conditions
          CustomTextField(
            label: 'Medical Conditions',
            hint: 'e.g., Diabetes, Asthma (comma separated)',
            controller: _conditionsController,
          ).animate().fadeIn(duration: 400.ms, delay: 350.ms),

          const SizedBox(height: AppSizes.paddingM),

          // Current Medications
          CustomTextField(
            label: 'Current Medications',
            hint: 'e.g., Aspirin, Insulin (comma separated)',
            controller: _medicationsController,
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

          const SizedBox(height: AppSizes.paddingL),

          // Emergency Contact Section
          _buildSectionLabel('Emergency Contact', Icons.contact_phone_rounded, AppColors.primary)
              .animate().fadeIn(duration: 400.ms, delay: 450.ms),

          const SizedBox(height: AppSizes.paddingM),

          CustomTextField(
            label: 'Contact Name',
            hint: 'John Doe',
            controller: _emergencyNameController,
          ).animate().fadeIn(duration: 400.ms, delay: 500.ms),

          const SizedBox(height: AppSizes.paddingM),

          CustomTextField(
            label: 'Contact Phone',
            hint: '+1 234 567 8900',
            controller: _emergencyPhoneController,
            keyboardType: TextInputType.phone,
          ).animate().fadeIn(duration: 400.ms, delay: 550.ms),

          const SizedBox(height: AppSizes.paddingM),

          CustomTextField(
            label: 'Relationship',
            hint: 'e.g., Spouse, Parent',
            controller: _emergencyRelationController,
          ).animate().fadeIn(duration: 400.ms, delay: 600.ms),

          const SizedBox(height: AppSizes.paddingXL),

          // Complete button
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              return CustomButton(
                text: userProvider.isLoading ? 'Creating Account...' : 'Complete Sign Up',
                onPressed: userProvider.isLoading ? () {} : _handleSignUp,
                width: double.infinity,
              );
            },
          ).animate().fadeIn(duration: 400.ms, delay: 650.ms),

          const SizedBox(height: AppSizes.paddingM),

          // Skip button
          Center(
            child: TextButton(
              onPressed: () async {
                // Create account with basic info only
                final userProvider = context.read<UserProvider>();
                final success = await userProvider.signUp(
                  fullName: _nameController.text.trim(),
                  email: _emailController.text.trim(),
                  phoneNumber: _phoneController.text.trim(),
                  password: _passwordController.text,
                  dateOfBirth: _selectedDate,
                  gender: _selectedGender,
                  nationality: _selectedNationality,
                  preferredLanguage: _selectedPreferredLanguage,
                );

                if (success && mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                }
              },
              child: Text(
                'Skip for now',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary(context),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 700.ms),

          const SizedBox(height: AppSizes.paddingXL),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, IconData icon, Color color) {
    return Builder(
      builder: (context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingS),
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: AppSizes.paddingS),
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: AppSizes.paddingS),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
            decoration: BoxDecoration(
              color: AppTheme.backgroundCard(context),
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
              border: Border.all(color: AppTheme.divider(context)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: AppTheme.backgroundCard(context),
                hint: Text(
                  hint,
                  style: GoogleFonts.inter(
                    fontSize: 16,
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

  Widget _buildLanguagePicker() {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferred Language',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: AppSizes.paddingXS),
          Text(
            'Documents will be translated to this language',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: AppSizes.paddingS),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
            decoration: BoxDecoration(
              color: AppTheme.backgroundCard(context),
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
              border: Border.all(color: AppTheme.divider(context)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPreferredLanguage,
                isExpanded: true,
                dropdownColor: AppTheme.backgroundCard(context),
                icon: Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary(context)),
                items: UserModel.supportedLanguages.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Row(
                      children: [
                        const Icon(Icons.translate_rounded, size: 20, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          entry.value,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPreferredLanguage = value;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNationalityField() {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nationality',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: AppSizes.paddingS),
          GestureDetector(
            onTap: _showCountryPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingM,
                vertical: AppSizes.paddingM + 2,
              ),
              decoration: BoxDecoration(
                color: AppTheme.backgroundCard(context),
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
                border: Border.all(color: AppTheme.divider(context)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedNationality ?? 'Select Country',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: _selectedNationality != null
                            ? AppTheme.textPrimary(context)
                            : AppTheme.textMuted(context),
                      ),
                    ),
                  ),
                  Icon(Icons.search, color: AppTheme.textSecondary(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Searchable Country Picker Bottom Sheet
class _CountryPickerSheet extends StatefulWidget {
  final List<String> countries;
  final String? selectedCountry;
  final Function(String) onSelected;

  const _CountryPickerSheet({
    required this.countries,
    required this.selectedCountry,
    required this.onSelected,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredCountries = [];

  @override
  void initState() {
    super.initState();
    _filteredCountries = widget.countries;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = widget.countries;
      } else {
        _filteredCountries = widget.countries
            .where((country) => country.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.divider(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Text(
              'Select Country',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark(context),
              ),
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _filterCountries,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppTheme.textPrimary(context),
              ),
              decoration: InputDecoration(
                hintText: 'Search country...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppTheme.textMuted(context),
                ),
                prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary(context)),
                filled: true,
                fillColor: AppTheme.backgroundLight(context),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingM,
                  vertical: AppSizes.paddingM,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusL),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSizes.paddingS),

          // Country list
          Expanded(
            child: _filteredCountries.isEmpty
                ? Center(
                    child: Text(
                      'No countries found',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredCountries.length,
                    itemBuilder: (context, index) {
                      final country = _filteredCountries[index];
                      final isSelected = country == widget.selectedCountry;

                      return ListTile(
                        title: Text(
                          country,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? AppColors.primary : AppTheme.textDark(context),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: AppColors.primary)
                            : null,
                        onTap: () {
                          widget.onSelected(country);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
