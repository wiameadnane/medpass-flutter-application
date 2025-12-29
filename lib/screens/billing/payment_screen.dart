import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common_widgets.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  final _postalCodeController = TextEditingController();

  int _selectedPaymentMethod = 0;
  String _selectedCountry = 'United States';

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) return;
    await _processPayment();
  }

  // Demo payment - skips form validation
  Future<void> _handleDemoPayment() async {
    await _processPayment();
  }

  Future<void> _processPayment() async {
    final userProvider = context.read<UserProvider>();
    final success = await userProvider.upgradeToPremium();

    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      AppSnackBar.showSuccess(context, 'Successfully upgraded to Premium!');
    }
  }

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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Center(
                  child: Text(
                    AppStrings.proceedToPay,
                    style: GoogleFonts.dmSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms),

                const SizedBox(height: AppSizes.paddingM),

                // User name
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    return Center(
                      child: Text(
                        userProvider.user?.fullName ?? 'User',
                        style: GoogleFonts.dmSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark(context),
                        ),
                      ),
                    );
                  },
                ).animate().fadeIn(duration: 500.ms, delay: 50.ms),

                const SizedBox(height: AppSizes.paddingM),

                // Payment Info header
                Text(
                  'PAYMENT INFO',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textDark(context),
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

                const SizedBox(height: AppSizes.paddingS),
                Divider(color: AppTheme.divider(context)),
                const SizedBox(height: AppSizes.paddingL),

                // Payment method tabs
                Row(
                  children: [
                    _buildPaymentMethodTab(0, 'Card', Icons.credit_card),
                    const SizedBox(width: AppSizes.paddingS),
                    _buildPaymentMethodTab(1, 'PayPal', Icons.paypal),
                    const SizedBox(width: AppSizes.paddingS),
                    _buildPaymentMethodTab(2, 'Apple', Icons.apple),
                  ],
                ).animate().fadeIn(duration: 500.ms, delay: 150.ms),

                const SizedBox(height: AppSizes.paddingL),

                // Card number field
                _buildInputField(
                  label: 'Card number',
                  controller: _cardNumberController,
                  hint: '1234 1234 1234 1234',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                    _CardNumberFormatter(),
                  ],
                ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

                const SizedBox(height: AppSizes.paddingM),

                // Expiry and CVC row
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        label: 'Expiry',
                        controller: _expiryController,
                        hint: 'MM / YY',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                          _ExpiryDateFormatter(),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingM),
                    Expanded(
                      child: _buildInputField(
                        label: 'CVC',
                        controller: _cvcController,
                        hint: 'CVC',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms, delay: 250.ms),

                const SizedBox(height: AppSizes.paddingM),

                // Country and Postal code row
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Country',
                        value: _selectedCountry,
                        items: ['United States', 'France', 'Morocco', 'Germany', 'UK'],
                        onChanged: (value) {
                          setState(() {
                            _selectedCountry = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingM),
                    Expanded(
                      child: _buildInputField(
                        label: 'Postal code',
                        controller: _postalCodeController,
                        hint: '90210',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

                const SizedBox(height: AppSizes.paddingXL),

                // Pay button (skips validation for demo)
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    return GestureDetector(
                      onTap: userProvider.isLoading ? null : _handleDemoPayment,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSizes.paddingM),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppSizes.radiusL),
                        ),
                        child: Center(
                          child: Text(
                            userProvider.isLoading ? 'Processing...' : 'Pay \$12.00',
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ).animate().fadeIn(duration: 500.ms, delay: 350.ms),

                const SizedBox(height: AppSizes.paddingM),

                // Cancel button
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Go back',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark(context),
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTab(int index, String label, IconData icon) {
    final isSelected = _selectedPaymentMethod == index;
    return Builder(
      builder: (context) => Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedPaymentMethod = index;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingM),
            decoration: BoxDecoration(
              color: AppTheme.backgroundCard(context),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppTheme.divider(context),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadow(context),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppTheme.textSecondary(context),
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primary : AppTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark(context),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted(context),
              ),
              filled: true,
              fillColor: AppTheme.backgroundCard(context),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingM,
                vertical: AppSizes.paddingM,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
                borderSide: BorderSide(color: AppTheme.divider(context), width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
                borderSide: BorderSide(color: AppTheme.divider(context), width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
            decoration: BoxDecoration(
              color: AppTheme.backgroundCard(context),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
              border: Border.all(color: AppTheme.divider(context), width: 2),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: AppTheme.backgroundCard(context),
                icon: Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary(context)),
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark(context),
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

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) {
        buffer.write(' ');
      }
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' / ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && i + 1 != text.length) {
        buffer.write(' / ');
      }
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
