import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../point/routes/app_routes.dart';
import '../../profile/privacy_policy_screen.dart';
import '../../profile/terms_conditions_screen.dart';
import '../controllers/mjengo_auth_controller.dart';

// ── Palette ────────────────────────────────────────────────────────────────────
const Color _accent      = Color(0xFF3B82F6);
const Color _bg          = Color(0xFFFFFFFF);
const Color _inputBg     = Color(0xFFF4F4FB);
const Color _inputBorder = Color(0xFFE8E8F0);
const Color _textDark    = Color(0xFF1A1A2E);
const Color _textGray    = Color(0xFF475569);

// ── Screen ─────────────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  final bool startOnSignUp;
  const LoginScreen({Key? key, this.startOnSignUp = false}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late bool _onSignUp;

  @override
  void initState() {
    super.initState();
    _onSignUp = widget.startOnSignUp;
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final size   = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;

    Widget body = SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          left: 28,
          right: 28,
          bottom: MediaQuery.of(context).viewInsets.bottom + 40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: topPad > 0 ? 8 : 24),

            // ── Logo ─────────────────────────────────────────────────
            Image.asset(
              'assets/mjengo_hub_logo.png',
              height: 42,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 40),

            // ── Heading ───────────────────────────────────────────────
            Text(
              _onSignUp ? 'Create\nAccount' : 'Sign In',
              style: GoogleFonts.montserrat(
                fontSize: 36,
                fontWeight: FontWeight.w500,
                color: _textDark,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _onSignUp
                  ? 'Join Mjengo Hub — your construction blog.'
                  : 'Welcome back. Good to see you again.',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: _textGray,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 36),

            // ── Form ─────────────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _onSignUp
                  ? _SignUpForm(key: const ValueKey('signup'))
                  : _LoginForm(key: const ValueKey('login')),
            ),

            
          ],
        ),
      ),
    );

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F4FB),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Scaffold(backgroundColor: _bg, body: body),
            ),
          ),
        ),
      );
    }

    return Scaffold(backgroundColor: _bg, body: body);
  }
}

// ── Login Form ─────────────────────────────────────────────────────────────────

class _LoginForm extends StatefulWidget {
  const _LoginForm({Key? key}) : super(key: key);

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  bool  _obscure   = true;

  MjengoAuthController get _ctrl => Get.find<MjengoAuthController>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email
          _Label('Email'),
          const SizedBox(height: 8),
          _Field(
            controller: _emailCtrl,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Enter your email' : null,
            onChanged: (_) {
              if (_ctrl.errorMessage.isNotEmpty) _ctrl.clearError();
            },
          ),

          const SizedBox(height: 18),

          // Password
          _Label('Password'),
          const SizedBox(height: 8),
          _Field(
            controller: _passCtrl,
            hint: '••••••••',
            obscureText: _obscure,
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _textGray,
                size: 20,
              ),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Enter your password' : null,
            onChanged: (_) {
              if (_ctrl.errorMessage.isNotEmpty) _ctrl.clearError();
            },
          ),

          const SizedBox(height: 10),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.resetPassword),
              child: Text(
                'Forgot Password?',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _accent,
                ),
              ),
            ),
          ),

          // Error
          _ErrorBox(),

          const SizedBox(height: 28),

          // Sign In button
          _PrimaryButton(
            label: 'Sign In',
            icon: Icons.login_rounded,
            onPressed: _login,
          ),

          const SizedBox(height: 28),
          _OrDivider(label: 'or Sign In with'),
          const SizedBox(height: 22),

          // Google
          _GoogleButton(onTap: () async {
            HapticFeedback.lightImpact();
            await _ctrl.signInWithGoogle();
          }),

          const SizedBox(height: 28),

          // Sign up link
          Center(
            child: RichText(
              text: TextSpan(
                style:
                    GoogleFonts.montserrat(fontSize: 13, color: _textGray),
                children: [
                  const TextSpan(text: "Don't have an account? "),
                  TextSpan(
                    text: 'Sign up',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _accent,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        final s = context
                            .findAncestorStateOfType<_LoginScreenState>();
                        s?.setState(() => s._onSignUp = true);
                      },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    await _ctrl.signInWithEmail(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
  }
}

// ── Sign Up Form ───────────────────────────────────────────────────────────────

class _SignUpForm extends StatefulWidget {
  const _SignUpForm({Key? key}) : super(key: key);

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  bool  _obscure      = true;
  bool  _acceptTerms  = false;
  String _password    = '';

  MjengoAuthController get _ctrl => Get.find<MjengoAuthController>();

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('First Name'),
                    const SizedBox(height: 8),
                    _Field(
                      controller: _firstCtrl,
                      hint: 'John',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('Last Name'),
                    const SizedBox(height: 8),
                    _Field(
                      controller: _lastCtrl,
                      hint: 'Kamau',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Email
          _Label('Email'),
          const SizedBox(height: 8),
          _Field(
            controller: _emailCtrl,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter your email';
              if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                return 'Enter a valid email';
              }
              return null;
            },
            onChanged: (_) {
              if (_ctrl.errorMessage.isNotEmpty) _ctrl.clearError();
            },
          ),

          const SizedBox(height: 18),

          // Password
          _Label('Password'),
          const SizedBox(height: 8),
          _Field(
            controller: _passCtrl,
            hint: '••••••••',
            obscureText: _obscure,
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _textGray,
                size: 20,
              ),
            ),
            onChanged: (v) {
              setState(() => _password = v);
              if (_ctrl.errorMessage.isNotEmpty) _ctrl.clearError();
            },
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter a password';
              if (v.length < 8) return 'At least 8 characters';
              if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Add an uppercase letter';
              if (!RegExp(r'[0-9]').hasMatch(v)) return 'Add a number';
              return null;
            },
          ),

          // Strength bar
          if (_password.isNotEmpty) ...[
            const SizedBox(height: 10),
            _PasswordStrengthBar(password: _password),
          ],

          const SizedBox(height: 18),

          // Terms
          _TermsCheckbox(
            value: _acceptTerms,
            onChanged: (v) => setState(() => _acceptTerms = v),
          ),

          // Error
          _ErrorBox(),

          const SizedBox(height: 28),

          // Create Account button
          _PrimaryButton(
            label: 'Create Account',
            icon: Icons.person_add_outlined,
            onPressed: _createAccount,
          ),

          const SizedBox(height: 28),
          _OrDivider(label: 'or Sign Up with'),
          const SizedBox(height: 22),

          // Google
          _GoogleButton(onTap: () async {
            HapticFeedback.lightImpact();
            await _ctrl.signInWithGoogle();
          }),

          const SizedBox(height: 28),

          // Sign in link
          Center(
            child: RichText(
              text: TextSpan(
                style:
                    GoogleFonts.montserrat(fontSize: 13, color: _textGray),
                children: [
                  const TextSpan(text: 'Already have an account? '),
                  TextSpan(
                    text: 'Sign in',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _accent,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        final s = context
                            .findAncestorStateOfType<_LoginScreenState>();
                        s?.setState(() => s._onSignUp = false);
                      },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      Get.snackbar(
        'Terms required',
        'Please accept the Terms & Privacy Policy to continue.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    HapticFeedback.lightImpact();
    await _ctrl.signUpWithEmail(
      firstName: _firstCtrl.text.trim(),
      lastName: _lastCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      displayName: '${_firstCtrl.text.trim()} ${_lastCtrl.text.trim()}',
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: _textDark,
        ),
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const _Field({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.montserrat(fontSize: 14, color: _textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(fontSize: 14, color: _textGray),
        filled: true,
        fillColor: _inputBg,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: _textGray)
            : null,
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffixIcon,
              )
            : null,
        suffixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _inputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        errorStyle: GoogleFonts.montserrat(fontSize: 11),
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  const _PrimaryButton(
      {required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = Get.find<MjengoAuthController>().isLoading;
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            disabledBackgroundColor: _accent.withOpacity(0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      );
    });
  }
}

class _OrDivider extends StatelessWidget {
  final String label;
  const _OrDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: _inputBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(label,
              style:
                  GoogleFonts.montserrat(fontSize: 12, color: _textGray)),
        ),
        Expanded(child: Container(height: 1, color: _inputBorder)),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = Get.find<MjengoAuthController>().isLoading;
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: loading ? null : onTap,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _inputBorder, width: 1.5),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _textGray),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Image.asset('assets/google-icon.png'),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Continue with Google',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                      ),
                    ),
                  ],
                ),
        ),
      );
    });
  }
}

class _GuestButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          Get.find<MjengoAuthController>().continueAsGuest();
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Text(
          'Continue as Guest',
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textGray,
            decoration: TextDecoration.underline,
            decorationColor: _textGray,
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final msg = Get.find<MjengoAuthController>().errorMessage;
      if (msg.isEmpty) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(msg,
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: Colors.red.shade700)),
            ),
          ],
        ),
      );
    });
  }
}

class _TermsCheckbox extends StatelessWidget {
  final bool value;
  final void Function(bool) onChanged;
  const _TermsCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(!value);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? _accent : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value ? _accent : _inputBorder,
                width: 1.5,
              ),
            ),
            child: value
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.montserrat(
                  fontSize: 12, color: _textGray, height: 1.5),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms & Conditions',
                  style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: _accent,
                      fontWeight: FontWeight.w600),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      HapticFeedback.lightImpact();
                      Get.to(() => const TermsConditionsScreen());
                    },
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: _accent,
                      fontWeight: FontWeight.w600),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      HapticFeedback.lightImpact();
                      Get.to(() => const PrivacyPolicyScreen());
                    },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  final String password;
  const _PasswordStrengthBar({required this.password});

  int _score(String p) {
    int s = 0;
    if (p.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'[a-z]').hasMatch(p)) s++;
    if (RegExp(r'[0-9]').hasMatch(p)) s++;
    if (RegExp(r'[^a-zA-Z0-9]').hasMatch(p)) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final score = _score(password);
    final label = score <= 1
        ? 'Weak'
        : score <= 3
            ? 'Fair'
            : score == 4
                ? 'Good'
                : 'Strong';
    final color = score <= 1
        ? Colors.redAccent
        : score <= 3
            ? Colors.orange
            : score == 4
                ? _accent
                : const Color(0xFF22C55E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            5,
            (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                height: 3,
                decoration: BoxDecoration(
                  color: i < score ? color : _inputBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Strength: $label',
          style: GoogleFonts.montserrat(
              fontSize: 11, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
