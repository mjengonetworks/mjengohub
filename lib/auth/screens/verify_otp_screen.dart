import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/user_controller.dart';

// ── Palette (matches login_screen.dart) ───────────────────────────────────────
const Color _accent = Color(0xFF3B82F6);
const Color _bg = Color(0xFFFFFFFF);
const Color _inputBg = Color(0xFFF4F4FB);
const Color _inputBorder = Color(0xFFE8E8F0);
const Color _textDark = Color(0xFF1A1A2E);
const Color _textGray = Color(0xFF888888);

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({Key? key}) : super(key: key);

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final UserController _ctrl = Get.find<UserController>();
  final List<TextEditingController> _otpCtrls = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _foci = List.generate(6, (_) => FocusNode());

  late String _userId;
  late String _email;

  String get _maskedEmail {
    final at = _email.indexOf('@');
    if (at <= 1) return _email;
    final local = _email.substring(0, at);
    final domain = _email.substring(at);
    final stars = '*' * (local.length - 1).clamp(3, 6);
    return '${local[0]}$stars$domain';
  }

  Timer? _resendTimer;
  int _resendSeconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _userId = args['userId'] as String? ?? '';
    _email = args['email'] as String? ?? '';
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _foci[0].requestFocus(),
    );
  }

  @override
  void dispose() {
    for (final c in _otpCtrls) c.dispose();
    for (final f in _foci) f.dispose();
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
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  String get _otp => _otpCtrls.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length < 6) {
      Get.snackbar(
        'Invalid Code',
        'Please enter the 6-digit code.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 10,
      );
      return;
    }
    HapticFeedback.lightImpact();
    await _ctrl.verifyEmailOtp(userId: _userId, otp: _otp);
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    HapticFeedback.lightImpact();
    final ok = await _ctrl.resendEmailOtp(userId: _userId);
    if (ok) {
      for (final c in _otpCtrls) c.clear();
      _foci[0].requestFocus();
      _startResendTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),

            const SizedBox(height: 40),

            // ── Heading ───────────────────────────────────────────────
            Text(
              'Verify\nEmail',
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
                    text: _maskedEmail,
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

            // ── Error box ─────────────────────────────────────────────
            Obx(() {
              final msg = _ctrl.errorMessage;
              if (msg.isEmpty) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
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
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // ── OTP boxes ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) => _buildOtpBox(i)),
            ),

            const SizedBox(height: 32),

            // ── Verify button ─────────────────────────────────────────
            Obx(
              () => SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _ctrl.isLoading ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    disabledBackgroundColor: _accent.withOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _ctrl.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.verified_outlined,
                              color: Colors.white,
                              size: 17,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Verify Email',
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 24),

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
                                color: _accent,
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
                              color: _accent,
                            ),
                          ),
                        ],
                      ),
                    ),
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

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: _OtpDigitField(
        controller: _otpCtrls[index],
        focusNode: _foci[index],
        onFilled: (val) {
          if (val.isNotEmpty && index < 5) _foci[index + 1].requestFocus();
          if (val.isEmpty && index > 0) _foci[index - 1].requestFocus();
          if (index == 5 && val.isNotEmpty && _otp.length == 6) _verify();
        },
      ),
    );
  }
}

// ── OTP digit field ────────────────────────────────────────────────────────────

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
          color: focused ? _accent : _inputBorder,
          width: focused ? 2 : 1.5,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: _accent.withOpacity(0.12),
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

// ── Shared widgets ─────────────────────────────────────────────────────────────

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
