import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../point/routes/app_routes.dart';
import '../controllers/mjengo_auth_controller.dart';

const Color _primary      = Color(0xFF3B82F6);
const Color _primaryDeep  = Color(0xFF1D4ED8);
const Color _scaffoldBg   = Color(0xFFFFFFFF);
const Color _inputBg      = Color(0xFFF3F4F6);
const Color _textLight    = Color(0xFFFFFFFF);
const Color _textGray     = Color(0xFF6B7280);
const Color _inputBorder  = Color(0xFFE5E7EB);
const Color _textDark     = Color(0xFF111827);

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
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;

    Widget content = Column(
      children: [
        // ── Header blob ─────────────────────────────────────────────
        _BlobHeader(
          onSignUp: _onSignUp,
          onSignUpTap: () => setState(() => _onSignUp = true),
          onSignInTap: () => setState(() => _onSignUp = false),
        ),
        // ── Scrollable form ─────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 28,
              right: 28,
              bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                if (_onSignUp) _SignUpForm() else _LoginForm(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFFEFF6FF),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Scaffold(
                backgroundColor: _scaffoldBg,
                body: content,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: content,
    );
  }
}

// ─── Blob Header ──────────────────────────────────────────────────────────────

class _BlobHeader extends StatelessWidget {
  final bool onSignUp;
  final VoidCallback onSignUpTap;
  final VoidCallback onSignInTap;
  const _BlobHeader({
    required this.onSignUp,
    required this.onSignUpTap,
    required this.onSignInTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: 240 + topPadding,
      child: Stack(
        children: [
          // Blue organic blob background
          Positioned.fill(
            child: ClipPath(
              clipper: _BlobClipper(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          // Top row: logo + Sign Up / Sign In toggle
          Positioned(
            top: topPadding + 16,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Opposite screen link
                GestureDetector(
                  onTap: onSignUp ? onSignInTap : onSignUpTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          onSignUp ? Icons.login_rounded : Icons.person_add_alt_1_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          onSignUp ? 'Sign In' : 'Sign Up',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Large heading
          Positioned(
            bottom: 28,
            left: 28,
            right: 28,
            child: Text(
              onSignUp ? 'Create\nAccount' : 'Sign In',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 42,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlobClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.78);
    path.cubicTo(
      size.width * 0.10, size.height * 0.95,
      size.width * 0.30, size.height * 0.88,
      size.width * 0.50, size.height * 0.93,
    );
    path.cubicTo(
      size.width * 0.70, size.height * 0.98,
      size.width * 0.85, size.height * 0.80,
      size.width,        size.height * 0.88,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_BlobClipper oldClipper) => false;
}

// ─── Login Form ───────────────────────────────────────────────────────────────

class _LoginForm extends StatefulWidget {
  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  bool _obscure    = true;

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
          _FieldLabel('Email'),
          const SizedBox(height: 8),
          _DarkField(
            controller: _emailCtrl,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || v.isEmpty) ? 'Enter your email' : null,
            onChanged: (_) { if (_ctrl.errorMessage.isNotEmpty) _ctrl.clearError(); },
          ),
          const SizedBox(height: 18),
          _FieldLabel('Password'),
          const SizedBox(height: 8),
          _DarkField(
            controller: _passCtrl,
            hint: '••••••••••••',
            obscureText: _obscure,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: _textGray, size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
            onChanged: (_) { if (_ctrl.errorMessage.isNotEmpty) _ctrl.clearError(); },
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.resetPassword),
              child: Text(
                'Forgot Password?',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _primary,
                ),
              ),
            ),
          ),
          _ErrorBox(),
          const SizedBox(height: 24),
          _GradientButton(label: 'Sign In', onPressed: _login),
          const SizedBox(height: 24),
          _Divider(),
          const SizedBox(height: 20),
          _GoogleButton(onTap: () async {
            HapticFeedback.lightImpact();
            await _ctrl.signInWithGoogle();
          }),
          const SizedBox(height: 24),
          Center(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.montserrat(fontSize: 13, color: _textGray),
                children: [
                  const TextSpan(text: "Don't have an account? "),
                  TextSpan(
                    text: 'Sign up',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _primary,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        final state = context.findAncestorStateOfType<_LoginScreenState>();
                        state?.setState(() => state._onSignUp = true);
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
      rememberMe: false,
    );
  }
}

// ─── Sign Up Form ─────────────────────────────────────────────────────────────

class _SignUpForm extends StatefulWidget {
  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passCtrl      = TextEditingController();
  final _formKey       = GlobalKey<FormState>();
  bool _obscure        = true;
  bool _acceptTerms    = false;
  String _password     = '';

  MjengoAuthController get _ctrl => Get.find<MjengoAuthController>();

  @override
  void dispose() {
    _firstNameCtrl.dispose(); _lastNameCtrl.dispose();
    _emailCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('First Name'),
                    const SizedBox(height: 8),
                    _DarkField(
                      controller: _firstNameCtrl,
                      hint: 'John',
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Last Name'),
                    const SizedBox(height: 8),
                    _DarkField(
                      controller: _lastNameCtrl,
                      hint: 'Doe',
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _FieldLabel('Email'),
          const SizedBox(height: 8),
          _DarkField(
            controller: _emailCtrl,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter your email';
              if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v))
                return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 18),
          _FieldLabel('Password'),
          const SizedBox(height: 8),
          _DarkField(
            controller: _passCtrl,
            hint: '••••••••••••',
            obscureText: _obscure,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: _textGray, size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            onChanged: (v) {
              setState(() => _password = v);
              if (_ctrl.errorMessage.isNotEmpty) _ctrl.clearError();
            },
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter a password';
              if (v.length < 8) return 'Must be at least 8 characters';
              if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Need an uppercase letter';
              if (!RegExp(r'[a-z]').hasMatch(v)) return 'Need a lowercase letter';
              if (!RegExp(r'[0-9]').hasMatch(v)) return 'Need a number';
              if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(v)) return 'Need a special character';
              return null;
            },
          ),
          if (_password.isNotEmpty) ...[
            const SizedBox(height: 10),
            _PasswordStrengthBar(password: _password),
          ],
          const SizedBox(height: 18),
          _TermsCheckbox(
            value: _acceptTerms,
            onChanged: (v) => setState(() => _acceptTerms = v),
          ),
          _ErrorBox(),
          const SizedBox(height: 24),
          _GradientButton(label: 'Create Account', onPressed: _createAccount),
          const SizedBox(height: 24),
          _Divider(),
          const SizedBox(height: 20),
          _GoogleButton(onTap: () async {
            HapticFeedback.lightImpact();
            await _ctrl.signInWithGoogle();
          }),
          const SizedBox(height: 24),
          Center(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.montserrat(fontSize: 13, color: _textGray),
                children: [
                  const TextSpan(text: 'Already have an account? '),
                  TextSpan(
                    text: 'Sign in',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _primary,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        final state = context.findAncestorStateOfType<_LoginScreenState>();
                        state?.setState(() => state._onSignUp = false);
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
        'Please accept the Terms of Service and Privacy Policy',
        backgroundColor: Colors.red.shade500,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 10,
      );
      return;
    }
    HapticFeedback.lightImpact();
    await _ctrl.signUpWithEmail(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      displayName: '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _textGray,
      ),
    );
  }
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const _DarkField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _inputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _GradientButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = Get.find<MjengoAuthController>().isLoading;
      return GestureDetector(
        onTap: loading ? null : onPressed,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: loading ? _primary.withOpacity(0.6) : _primary,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!loading) ...[
                const Icon(Icons.login_rounded, color: _textLight, size: 18),
                const SizedBox(width: 8),
              ],
              loading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(_textLight),
                      ),
                    )
                  : Text(
                      label,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _textLight,
                      ),
                    ),
            ],
          ),
        ),
      );
    });
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: _inputBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or Sign In with',
            style: GoogleFonts.montserrat(fontSize: 12, color: _textGray),
          ),
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
      return Center(
        child: GestureDetector(
          onTap: loading ? null : onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _inputBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(_textGray),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(14),
                    child: Image.asset('assets/google-icon.png'),
                  ),
          ),
        ),
      );
    });
  }
}

class _ErrorBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final msg = Get.find<MjengoAuthController>().errorMessage;
      if (msg.isEmpty) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.montserrat(fontSize: 12, color: Colors.red.shade700),
              ),
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
          onTap: () { HapticFeedback.selectionClick(); onChanged(!value); },
          child: Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: value ? _primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value ? _primary : _inputBorder,
                width: 1.5,
              ),
            ),
            child: value ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.montserrat(fontSize: 12, color: _textGray, height: 1.5),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: _primary,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () {},
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: _primary,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () {},
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
    final label = score <= 1 ? 'Weak' : score <= 3 ? 'Fair' : score == 4 ? 'Good' : 'Strong';
    final color = score <= 1
        ? Colors.red.shade400
        : score <= 3
            ? Colors.orange.shade400
            : score == 4
                ? _primary
                : const Color(0xFF22C55E);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
              height: 3,
              decoration: BoxDecoration(
                color: i < score ? color : _inputBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          )),
        ),
        const SizedBox(height: 5),
        Text(
          'Strength: $label',
          style: GoogleFonts.montserrat(fontSize: 11, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
