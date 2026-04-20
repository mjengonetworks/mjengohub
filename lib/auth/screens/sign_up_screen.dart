import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../controllers/user_controller.dart';
import '../../point/routes/app_routes.dart';
import '../widgets/responsive_auth_layout.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin, ResponsiveAuthMixin {
  final UserController _userController = Get.find<UserController>();

  // Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Country & phone picker state
  Country? _selectedCountry;
  String _completePhone = '';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // State variables
  bool _acceptTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0; // 0 = personal info, 1 = account details

  // Brand Colors - Green and Orange
  static const Color primaryGreen = Color(0xFF22C55E);
  static const Color darkGreen = Color(0xFF145A32);
  static const Color accentOrange = Color(0xFFF5A623);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B7280);
  static const Color inputBorder = Color(0xFFE5E7EB);
  static const Color backgroundWhite = Color(0xFFFAFAFA);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _userController.clearError();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveAuthLayout(
      showBackButton: true,
      onBack: _currentStep > 0 ? _goBack : () => Navigator.pop(context),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isLarge = isLargeScreen(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isLarge) const SizedBox(height: 20),
        // Back Button
        _buildBackButton(),
        SizedBox(height: isLarge ? 16 : 30),
        // Logo
        _buildLogo(),
        SizedBox(height: isLarge ? 24 : 40),
        // Title
        _buildTitle(context),
        const SizedBox(height: 8),
        // Subtitle
        _buildSubtitle(),
        const SizedBox(height: 24),
        // Step Indicator
        _buildStepIndicator(),
        const SizedBox(height: 24),
        // Form Content
        _buildFormContent(),
        SizedBox(height: isLarge ? 24 : MediaQuery.of(context).padding.bottom + 24),
      ],
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: _currentStep > 0 ? _goBack : () => Navigator.pop(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: inputBorder),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: textDark,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        'assets/icon.jpg',
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final fontSize = getResponsiveTitleSize(context);
    String title1 = 'Create';
    String title2 = 'Account!';

    if (_currentStep == 0) {
      title1 = 'Personal';
      title2 = 'Information';
    } else {
      title1 = 'Create';
      title2 = 'Password';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title1,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: textDark,
            height: 1.1,
          ),
        ),
        Text(
          title2,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: textDark,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle() {
    return Wrap(
      children: [
        Text(
          'Already have an account? / ',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: textGray,
          ),
        ),
        GestureDetector(
          onTap: _goToLogin,
          child: Text(
            'Login',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primaryGreen,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepDot(0, 'Info'),
        _buildStepLine(0),
        _buildStepDot(1, 'Password'),
      ],
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? primaryGreen : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? primaryGreen : inputBorder,
                width: 2,
              ),
            ),
            child: Center(
              child: isActive && !isCurrent
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                      '${step + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : textGray,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: isActive ? primaryGreen : textGray,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isActive = _currentStep > afterStep;
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isActive ? primaryGreen : inputBorder,
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _currentStep == 0
            ? _buildPersonalInfoStep()
            : _buildPasswordStep(),
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      key: const ValueKey(0),
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryGreen.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: primaryGreen, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'All users can buy and sell on Nefxi. Register as a shop later for verified business features.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Error display
        _buildErrorDisplay(),
        // Full Name
        _buildTextField(
          controller: _fullNameController,
          hint: 'Full Name',
          icon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your full name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // Email
        _buildTextField(
          controller: _emailController,
          hint: 'Email Address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!_isValidEmail(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // Phone with dial-code picker
        _buildIntlPhoneField(),
        const SizedBox(height: 16),
        // Country picker
        _buildCountryPickerField(),
        const SizedBox(height: 24),
        // Continue Button
        _buildContinueButton(
          onPressed: () {
            if (_fullNameController.text.isNotEmpty &&
                _emailController.text.isNotEmpty &&
                _completePhone.isNotEmpty &&
                _selectedCountry != null) {
              setState(() => _currentStep = 1);
            } else {
              Get.snackbar(
                'Missing Information',
                'Please fill in all fields and select your country',
                backgroundColor: Colors.red.shade500,
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
              );
            }
          },
        ),
        const SizedBox(height: 24),
        // Divider
        Row(
          children: [
            Expanded(child: Container(height: 1, color: inputBorder)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or sign up with',
                style: GoogleFonts.poppins(fontSize: 13, color: textGray),
              ),
            ),
            Expanded(child: Container(height: 1, color: inputBorder)),
          ],
        ),
        const SizedBox(height: 20),
        // Google Sign Up Button
        _buildGoogleSignUpButton(),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      key: const ValueKey(1),
      children: [
        // Error display
        _buildErrorDisplay(),
        // Password
        _buildPasswordField(
          controller: _passwordController,
          hint: 'Password',
          obscureText: _obscurePassword,
          onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a password';
            }
            if (value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // Confirm Password
        _buildPasswordField(
          controller: _confirmPasswordController,
          hint: 'Confirm Password',
          obscureText: _obscureConfirmPassword,
          onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        // Terms Checkbox
        _buildTermsCheckbox(),
        const SizedBox(height: 24),
        // Create Account Button
        _buildCreateAccountButton(),
      ],
    );
  }

  Widget _buildErrorDisplay() {
    return Obx(() => _userController.errorMessage.isNotEmpty
        ? Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red.shade400,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _userController.errorMessage,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink(),
    );
  }

  Widget _buildIntlPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: inputBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: IntlPhoneField(
        initialCountryCode: 'KE',
        style: GoogleFonts.poppins(color: textDark, fontSize: 15),
        dropdownTextStyle: GoogleFonts.poppins(color: textDark, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Phone Number',
          hintStyle: GoogleFonts.poppins(color: textGray, fontSize: 15),
          border: InputBorder.none,
          errorBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          counterText: '',
        ),
        dropdownIcon: const Icon(Icons.arrow_drop_down, color: textGray, size: 20),
        flagsButtonPadding: const EdgeInsets.only(right: 4),
        onChanged: (phone) => setState(() => _completePhone = phone.completeNumber),
        validator: (phone) {
          if (phone == null || phone.number.isEmpty) {
            return 'Please enter your phone number';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCountryPickerField() {
    return GestureDetector(
      onTap: () => showCountryPicker(
        context: context,
        showPhoneCode: false,
        countryListTheme: CountryListThemeData(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          inputDecoration: InputDecoration(
            hintText: 'Search country',
            hintStyle: GoogleFonts.poppins(fontSize: 14, color: textGray),
            prefixIcon: const Icon(Icons.search, color: textGray),
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: inputBorder),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          searchTextStyle: GoogleFonts.poppins(fontSize: 14, color: textDark),
        ),
        onSelect: (country) => setState(() => _selectedCountry = country),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedCountry != null ? primaryGreen.withOpacity(0.4) : inputBorder,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(Icons.flag_outlined, color: textGray, size: 20),
            const SizedBox(width: 12),
            if (_selectedCountry != null) ...[
              Text(_selectedCountry!.flagEmoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                _selectedCountry?.name ?? 'Select Country',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: _selectedCountry != null ? textDark : textGray,
                ),
              ),
            ),
            if (_selectedCountry != null)
              const Icon(Icons.check, color: primaryGreen, size: 20)
            else
              const Icon(Icons.chevron_right, color: textGray, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: inputBorder),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(
          color: textDark,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: textGray,
            fontSize: 15,
          ),
          prefixIcon: Icon(icon, color: textGray, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: controller.text.isNotEmpty
              ? Icon(Icons.check, color: primaryGreen, size: 20)
              : null,
        ),
        validator: validator,
        onChanged: (value) {
          setState(() {});
          if (_userController.errorMessage.isNotEmpty) {
            _userController.clearError();
          }
        },
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: inputBorder),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: GoogleFonts.poppins(
          color: textDark,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: textGray,
            fontSize: 15,
          ),
          prefixIcon: Icon(Icons.lock_outline, color: textGray, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: textGray,
              size: 20,
            ),
            onPressed: onToggle,
          ),
        ),
        validator: validator,
        onChanged: (value) {
          if (_userController.errorMessage.isNotEmpty) {
            _userController.clearError();
          }
        },
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _acceptTerms = !_acceptTerms);
          },
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _acceptTerms ? primaryGreen : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _acceptTerms ? primaryGreen : inputBorder,
                width: 2,
              ),
            ),
            child: _acceptTerms
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _acceptTerms = !_acceptTerms),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: textGray,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: GoogleFonts.poppins(
                      color: primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = _showTermsOfService,
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: GoogleFonts.poppins(
                      color: primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = _showPrivacyPolicy,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton({bool enabled = true, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? primaryGreen : inputBorder,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Continue',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.white : textGray,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward,
              size: 20,
              color: enabled ? Colors.white : textGray,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateAccountButton() {
    return Obx(() => SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _userController.isLoading ? null : _signUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _userController.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Create Account',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.check, size: 20, color: Colors.white),
                    ],
                  ),
          ),
        ));
  }

  Widget _buildGoogleSignUpButton() {
    return Obx(() => SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: _userController.isLoading ? null : _signUpWithGoogle,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: inputBorder, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(text: 'G', style: TextStyle(color: Color(0xFF4285F4))),
                      TextSpan(text: 'o', style: TextStyle(color: Color(0xFFEA4335))),
                      TextSpan(text: 'o', style: TextStyle(color: Color(0xFFFBBC05))),
                      TextSpan(text: 'g', style: TextStyle(color: Color(0xFF4285F4))),
                      TextSpan(text: 'l', style: TextStyle(color: Color(0xFF34A853))),
                      TextSpan(text: 'e', style: TextStyle(color: Color(0xFFEA4335))),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Continue with Google',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Future<void> _signUpWithGoogle() async {
    HapticFeedback.lightImpact();
    await _userController.signInWithGoogle();
  }

  void _goBack() {
    HapticFeedback.lightImpact();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      Get.snackbar(
        'Terms Required',
        'Please accept the Terms of Service and Privacy Policy',
        backgroundColor: Colors.red.shade500,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    HapticFeedback.lightImpact();

    // Split full name into first and last name
    final nameParts = _fullNameController.text.trim().split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    try {
      final success = await _userController.signUpWithEmail(
        firstName: firstName,
        lastName: lastName,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _fullNameController.text.trim(),
        phone: _completePhone.isNotEmpty ? _completePhone : null,
        country: _selectedCountry?.name ?? '',
      );

      if (success) {
        HapticFeedback.lightImpact();
        // Controller handles navigation and success message
        // If user selected seller, they can set up seller profile later
      }
    } catch (e) {
      print('Unexpected sign up error: $e');
    }
  }

  void _showTermsOfService() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: inputBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Terms of Service',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: primaryGreen),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Here would be your Terms of Service content. This is a placeholder for the actual terms and conditions that users need to agree to when creating an account.\n\nYou should replace this with your actual legal terms.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: textDark,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: inputBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Privacy Policy',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: primaryGreen),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Here would be your Privacy Policy content. This is a placeholder for the actual privacy policy that explains how user data is collected, used, and protected.\n\nYou should replace this with your actual privacy policy.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: textDark,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToLogin() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
