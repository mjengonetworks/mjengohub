// screens/two_factor_screen.dart
//
// Handles two distinct flows:
//   1. MFA Challenge  – shown during sign-in when Firebase returns
//      multi-factor-auth-required. Route: /mfa-verify
//
//   2. MFA Enrollment – shown from Security settings to add 2FA.
//      Route: /mfa-enroll
//
// Both screens share the same OTP input widget and design language.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/user_controller.dart';

// ── Palette (matches login_screen.dart) ───────────────────────────────────────
const Color _primary = Color(0xFF3B82F6);
const Color _bg = Color(0xFFFFFFFF);
const Color _inputBg = Color(0xFFF4F4FB);
const Color _inputBorder = Color(0xFFE8E8F0);
const Color _textDark = Color(0xFF1A1A2E);
const Color _textGray = Color(0xFF888888);
const Color _success = Color(0xFF22C55E);
const Color _errorRed = Color(0xFFDC2626);

// ─────────────────────────────────────────────────────────────────────────────
// MFA CHALLENGE SCREEN  (sign-in second factor)
// ─────────────────────────────────────────────────────────────────────────────

class MfaVerifyScreen extends StatefulWidget {
  const MfaVerifyScreen({Key? key}) : super(key: key);

  @override
  State<MfaVerifyScreen> createState() => _MfaVerifyScreenState();
}

class _MfaVerifyScreenState extends State<MfaVerifyScreen>
    with SingleTickerProviderStateMixin {
  final UserController _ctrl = Get.find<UserController>();
  final List<TextEditingController> _ctrls = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _foci = List.generate(6, (_) => FocusNode());

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  Timer? _resendTimer;
  int _resendSeconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _foci[0].requestFocus(),
    );
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final f in _foci) f.dispose();
    _shakeCtrl.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  String get _code => _ctrls.map((c) => c.text).join();

  Future<void> _submit() async {
    if (_code.length < 6) return;
    HapticFeedback.lightImpact();
    _ctrl.clearError();
    final success = await _ctrl.completeMfaSignIn(_code);
    if (!success && mounted) {
      _shakeCtrl.forward(from: 0);
      HapticFeedback.heavyImpact();
      for (final c in _ctrls) c.clear();
      _foci[0].requestFocus();
    }
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    HapticFeedback.lightImpact();
    _ctrl.clearError();
    final ok = await _ctrl.resendMfaChallengeCode();
    if (ok && mounted) {
      _startResendTimer();
      Get.snackbar(
        'Code Sent',
        'A new verification code has been sent.',
        backgroundColor: _primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 10,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hint = _ctrl.mfaResolver?.hints
        .whereType<PhoneMultiFactorInfo>()
        .firstOrNull;
    final maskedPhone = _maskPhone(hint?.phoneNumber ?? '');
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

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
            const SizedBox(height: 16),

            // ── Top row: logo + back ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/mjengo_hub_logo.png',
                  height: 42,
                  fit: BoxFit.contain,
                ),
                _BackPill(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _ctrl.cancelMfaChallenge();
                    Get.back();
                  },
                ),
              ],
            ),

            const SizedBox(height: 36),

            // ── Shield icon ───────────────────────────────────────────
            _ShieldIcon(),

            const SizedBox(height: 24),

            Text(
              '2-Step\nVerification',
              style: GoogleFonts.montserrat(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: _textDark,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: _textGray,
                  height: 1.55,
                ),
                children: [
                  const TextSpan(text: 'Enter the 6-digit code sent to\n'),
                  TextSpan(
                    text: maskedPhone,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // ── OTP row (with shake) ──────────────────────────────────
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(
                  _shakeAnim.value *
                      8 *
                      ((_shakeAnim.value * 10).toInt().isEven ? 1 : -1),
                  0,
                ),
                child: child,
              ),
              child: _OtpInputRow(
                controllers: _ctrls,
                focusNodes: _foci,
                onCompleted: (_) => _submit(),
              ),
            ),

            const SizedBox(height: 16),
            _ErrorBox(ctrl: _ctrl),
            const SizedBox(height: 28),

            Obx(
              () => _PrimaryButton(
                label: 'Verify',
                loading: _ctrl.isLoading,
                onPressed: _submit,
              ),
            ),

            const SizedBox(height: 20),

            // ── Resend link ───────────────────────────────────────────
            Center(
              child: _canResend
                  ? GestureDetector(
                      onTap: _resend,
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: _textGray,
                          ),
                          children: [
                            const TextSpan(text: "Didn't receive it? "),
                            TextSpan(
                              text: 'Resend Code',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RichText(
                      text: TextSpan(
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: _textGray,
                        ),
                        children: [
                          const TextSpan(text: 'Resend code in '),
                          TextSpan(
                            text: '${_resendSeconds}s',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _primary,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 28),
            _InfoCard(
              text:
                  'This code expires in 10 minutes. '
                  "If you didn't request this, please secure your account.",
            ),
            const SizedBox(height: 24),
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

// ─────────────────────────────────────────────────────────────────────────────
// MFA ENROLL SCREEN  (enable 2FA from settings)
// ─────────────────────────────────────────────────────────────────────────────

class MfaEnrollScreen extends StatefulWidget {
  const MfaEnrollScreen({Key? key}) : super(key: key);

  @override
  State<MfaEnrollScreen> createState() => _MfaEnrollScreenState();
}

class _MfaEnrollScreenState extends State<MfaEnrollScreen>
    with SingleTickerProviderStateMixin {
  final UserController _ctrl = Get.find<UserController>();

  int _step = 0; // 0 = enter phone, 1 = enter OTP

  final _phoneCtrl = TextEditingController();
  final List<TextEditingController> _otpCtrls = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFoci = List.generate(6, (_) => FocusNode());

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  Timer? _resendTimer;
  int _resendSeconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
    _ctrl.clearError();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final f in _otpFoci) f.dispose();
    _shakeCtrl.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  Future<void> _sendCode() async {
    final phone = _phoneCtrl.text.trim();
    _ctrl.clearError();
    final ok = await _ctrl.startMfaEnrollment(phone);
    if (ok && mounted) {
      setState(() => _step = 1);
      _startResendTimer();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _otpFoci[0].requestFocus(),
      );
    }
  }

  Future<void> _verify() async {
    final code = _otpCtrls.map((c) => c.text).join();
    if (code.length < 6) return;
    HapticFeedback.lightImpact();
    _ctrl.clearError();
    final success = await _ctrl.completeMfaEnrollment(smsCode: code);
    if (success && mounted) {
      Get.back(result: true);
    } else if (mounted) {
      _shakeCtrl.forward(from: 0);
      HapticFeedback.heavyImpact();
      for (final c in _otpCtrls) c.clear();
      _otpFoci[0].requestFocus();
    }
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    _ctrl.clearError();
    final ok = await _ctrl.startMfaEnrollment(_phoneCtrl.text.trim());
    if (ok && mounted) {
      _startResendTimer();
      Get.snackbar(
        'Code Sent',
        'A new verification code has been sent.',
        backgroundColor: _primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 10,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            left: 28,
            right: 28,
            bottom: MediaQuery.of(context).viewInsets.bottom + 40,
          ),
          child: _step == 0 ? _buildPhoneStep() : _buildOtpStep(),
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // ── Top row: logo + back ────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'assets/mjengo_hub_logo.png',
              height: 42,
              fit: BoxFit.contain,
            ),
            _BackPill(
              onTap: () {
                HapticFeedback.lightImpact();
                Get.back();
              },
            ),
          ],
        ),

        const SizedBox(height: 40),

        Text(
          'Enable\n2-Step Auth',
          style: GoogleFonts.montserrat(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: _textDark,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Add an extra layer of security. We'll send an SMS code each time you sign in.",
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: _textGray,
            height: 1.55,
          ),
        ),

        const SizedBox(height: 36),

        _Label('Your Phone Number'),
        const SizedBox(height: 8),

        // Phone field with country prefix
        Container(
          decoration: BoxDecoration(
            color: _inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _inputBorder, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: _inputBorder)),
                ),
                child: Text(
                  '+254',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textDark,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.montserrat(fontSize: 14, color: _textDark),
                  decoration: InputDecoration(
                    hintText: 'Enter phone number',
                    hintStyle: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: _textGray,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (_) {
                    if (_ctrl.errorMessage.isNotEmpty) {
                      _ctrl.clearError();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Format: 712 345 678',
          style: GoogleFonts.montserrat(fontSize: 11, color: _textGray),
        ),

        _ErrorBox(ctrl: _ctrl),
        const SizedBox(height: 28),

        Obx(
          () => _PrimaryButton(
            label: 'Send Verification Code',
            loading: _ctrl.isLoading,
            onPressed: _sendCode,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // ── Top row: logo + back ────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'assets/mjengo_hub_logo.png',
              height: 42,
              fit: BoxFit.contain,
            ),
            _BackPill(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _step = 0;
                  _ctrl.clearError();
                });
              },
            ),
          ],
        ),

        const SizedBox(height: 40),

        Text(
          'Enter\nthe Code',
          style: GoogleFonts.montserrat(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: _textDark,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: _textGray,
              height: 1.55,
            ),
            children: [
              const TextSpan(text: 'We sent a 6-digit code to\n'),
              TextSpan(
                text: _maskPhone(_phoneCtrl.text.trim()),
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 36),

        AnimatedBuilder(
          animation: _shakeAnim,
          builder: (_, child) => Transform.translate(
            offset: Offset(
              _shakeAnim.value *
                  8 *
                  ((_shakeAnim.value * 10).toInt().isEven ? 1 : -1),
              0,
            ),
            child: child,
          ),
          child: _OtpInputRow(
            controllers: _otpCtrls,
            focusNodes: _otpFoci,
            onCompleted: (_) => _verify(),
          ),
        ),

        const SizedBox(height: 16),
        _ErrorBox(ctrl: _ctrl),
        const SizedBox(height: 28),

        Obx(
          () => _PrimaryButton(
            label: 'Enable 2FA',
            loading: _ctrl.isLoading,
            onPressed: _verify,
          ),
        ),

        const SizedBox(height: 20),

        Center(
          child: _canResend
              ? GestureDetector(
                  onTap: _resend,
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: _textGray,
                      ),
                      children: [
                        const TextSpan(text: "Didn't receive it? "),
                        TextSpan(
                          text: 'Resend Code',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RichText(
                  text: TextSpan(
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: _textGray,
                    ),
                    children: [
                      const TextSpan(text: 'Resend code in '),
                      TextSpan(
                        text: '${_resendSeconds}s',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _primary,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MFA MANAGE SCREEN  (view enrolled factors, remove)
// ─────────────────────────────────────────────────────────────────────────────

class MfaManageScreen extends StatelessWidget {
  const MfaManageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final UserController ctrl = Get.find<UserController>();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _BackButton(onTap: () => Get.back()),
              const SizedBox(height: 32),
              Text(
                'Security',
                style: GoogleFonts.montserrat(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your account security settings.',
                style: GoogleFonts.montserrat(fontSize: 13, color: _textGray),
              ),
              const SizedBox(height: 32),

              // ── 2FA Status Card ──────────────────────────────────────
              Obx(() {
                final enrolled = ctrl.mfaEnrolled;
                final factors = ctrl.enrolledMfaFactors;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Two-Factor Authentication'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: enrolled ? _success.withOpacity(0.06) : _inputBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: enrolled
                              ? _success.withOpacity(0.35)
                              : _inputBorder,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: enrolled
                                  ? _success.withOpacity(0.12)
                                  : _inputBorder.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              enrolled
                                  ? Icons.shield_rounded
                                  : Icons.shield_outlined,
                              color: enrolled ? _success : _textGray,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  enrolled
                                      ? '2FA is Active'
                                      : '2FA is Disabled',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _textDark,
                                  ),
                                ),
                                Text(
                                  enrolled
                                      ? 'Your account is protected with SMS verification.'
                                      : 'Enable 2FA to add an extra layer of security.',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: _textGray,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Enrolled factors ───────────────────────────────
                    if (enrolled && factors.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _SectionLabel('Enrolled Factors'),
                      const SizedBox(height: 10),
                      ...factors.map(
                        (factor) => _FactorTile(
                          factor: factor,
                          onRemove: () => _confirmRemove(context, ctrl, factor),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    Obx(
                      () => _PrimaryButton(
                        label: enrolled ? 'Add Another Factor' : 'Enable 2FA',
                        loading: ctrl.isLoading,
                        onPressed: () => Get.toNamed('/mfa-enroll'),
                        outlined: enrolled,
                      ),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 36),

              // ── Security tips ─────────────────────────────────────────
              _SectionLabel('Security Tips'),
              const SizedBox(height: 10),
              _SecurityTip(
                icon: Icons.lock_outline,
                title: 'Strong Password',
                body:
                    'Use a unique password with uppercase, numbers, and symbols.',
              ),
              const SizedBox(height: 10),
              _SecurityTip(
                icon: Icons.email_outlined,
                title: 'Verify Your Email',
                body: 'A verified email helps you recover your account.',
              ),
              const SizedBox(height: 10),
              _SecurityTip(
                icon: Icons.devices_outlined,
                title: 'Trusted Devices',
                body: 'Sign out from devices you no longer use.',
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    UserController ctrl,
    MultiFactorInfo factor,
  ) async {
    final phone = factor is PhoneMultiFactorInfo
        ? _maskPhone(factor.phoneNumber ?? '')
        : factor.displayName ?? 'this factor';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Disable 2FA',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        content: Text(
          'Remove $phone as a verification method? '
          'Your account will no longer require SMS codes on sign-in.',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: _textGray,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(
                color: _textGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Remove',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ctrl.unenrollMfaFactor(factor);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED PRIVATE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Pill-shaped back button — used in auth-flow screens (MfaVerify, MfaEnroll).
class _BackPill extends StatelessWidget {
  final VoidCallback onTap;
  const _BackPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _inputBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _inputBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back_rounded, size: 15, color: _textDark),
            const SizedBox(width: 5),
            Text(
              'Back',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Square back button — used in settings-style screens (MfaManage).
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _inputBorder, width: 1.5),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: _textDark,
          size: 18,
        ),
      ),
    );
  }
}

class _ShieldIcon extends StatelessWidget {
  final bool active;
  const _ShieldIcon({this.active = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: active
            ? _primary.withOpacity(0.08)
            : _inputBorder.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        active ? Icons.shield_rounded : Icons.shield_outlined,
        color: active ? _primary : _textGray,
        size: 32,
      ),
    );
  }
}

class _OtpInputRow extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(String code)? onCompleted;

  const _OtpInputRow({
    required this.controllers,
    required this.focusNodes,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 46,
          height: 56,
          child: _OtpDigitField(
            controller: controllers[i],
            focusNode: focusNodes[i],
            onFilled: (val) {
              if (val.isNotEmpty && i < 5) focusNodes[i + 1].requestFocus();
              if (val.isEmpty && i > 0) focusNodes[i - 1].requestFocus();
              final code = controllers.map((c) => c.text).join();
              if (code.length == 6) onCompleted?.call(code);
            },
          ),
        );
      }),
    );
  }
}

class _OtpDigitField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onFilled;

  const _OtpDigitField({
    required this.controller,
    required this.focusNode,
    required this.onFilled,
  });

  @override
  State<_OtpDigitField> createState() => _OtpDigitFieldState();
}

class _OtpDigitFieldState extends State<_OtpDigitField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final focused = widget.focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: focused ? Colors.white : _inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focused ? _primary : _inputBorder,
          width: focused ? 2 : 1.5,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: _primary.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        maxLength: 1,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _textDark,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: widget.onFilled,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  final bool outlined;

  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(_primary),
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primary.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final UserController ctrl;
  const _ErrorBox({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final msg = ctrl.errorMessage;
      if (msg.isEmpty) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.montserrat(fontSize: 12, color: Colors.red),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _InfoCard extends StatelessWidget {
  final String text;
  final IconData icon;
  const _InfoCard({required this.text, this.icon = Icons.security_outlined});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: _textDark,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: GoogleFonts.montserrat(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: _textGray,
      letterSpacing: 0.5,
    ),
  );
}

class _FactorTile extends StatelessWidget {
  final MultiFactorInfo factor;
  final VoidCallback onRemove;
  const _FactorTile({required this.factor, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isPhone = factor is PhoneMultiFactorInfo;
    final phone = isPhone
        ? _maskPhone((factor as PhoneMultiFactorInfo).phoneNumber ?? '')
        : factor.displayName ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _inputBorder, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPhone ? Icons.phone_android_rounded : Icons.security_rounded,
              color: _primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPhone ? 'Phone' : 'Authenticator',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                Text(
                  phone,
                  style: GoogleFonts.montserrat(fontSize: 12, color: _textGray),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                'Remove',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityTip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _SecurityTip({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _inputBorder, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: _primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                Text(
                  body,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: _textGray,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

String _maskPhone(String phone) {
  if (phone.length < 7) return phone;
  final visible = phone.substring(phone.length - 4);
  final prefixLen = phone.startsWith('+') ? 4 : 3;
  final start = phone.substring(0, phone.length > 6 ? prefixLen : 2);
  return '${start}****$visible';
}
