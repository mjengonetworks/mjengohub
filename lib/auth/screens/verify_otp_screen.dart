import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/user_controller.dart';

const Color _primary = Color(0xFF22C55E);
const Color _textDark = Color(0xFF1A1A1A);
const Color _textGray = Color(0xFF6B7280);
const Color _inputBorder = Color(0xFFE5E7EB);

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({Key? key}) : super(key: key);

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final UserController _ctrl = Get.find<UserController>();
  final List<TextEditingController> _otpCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _foci = List.generate(6, (_) => FocusNode());

  late String _userId;
  late String _email;

  String get _maskedEmail {
    final at = _email.indexOf('@');
    if (at <= 1) return _email;
    final local = _email.substring(0, at);
    final domain = _email.substring(at);
    final visible = local.substring(0, 1);
    final stars = '*' * (local.length - 1).clamp(3, 6);
    return '$visible$stars$domain';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _foci[0].requestFocus());
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
      if (!mounted) { t.cancel(); return; }
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
      Get.snackbar('Invalid Code', 'Please enter the 6-digit code.',
          backgroundColor: Colors.red.shade500,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              // Back
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _inputBorder),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: _textDark, size: 18),
                ),
              ),
              const SizedBox(height: 32),
              // Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset('assets/icon.jpg', width: 50, height: 50,
                    fit: BoxFit.cover),
              ),
              const SizedBox(height: 24),
              Text('Check your\nEmail',
                  style: GoogleFonts.montserrat(
                      fontSize: 32, fontWeight: FontWeight.bold,
                      color: _textDark, height: 1.1)),
              const SizedBox(height: 12),
              Text(
                'We sent a 6-digit verification code to\n$_maskedEmail',
                style: GoogleFonts.montserrat(fontSize: 14, color: _textGray, height: 1.5),
              ),
              const SizedBox(height: 40),
              // Error
              Obx(() => _ctrl.errorMessage.isNotEmpty
                  ? Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(children: [
                        Icon(Icons.error_outline,
                            color: Colors.red.shade400, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_ctrl.errorMessage,
                              style: GoogleFonts.montserrat(
                                  fontSize: 13, color: Colors.red.shade700)),
                        ),
                      ]),
                    )
                  : const SizedBox.shrink()),
              // OTP fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _buildOtpBox(i)),
              ),
              const SizedBox(height: 40),
              // Verify button
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _ctrl.isLoading ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _ctrl.isLoading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white)))
                          : Text('Verify Email',
                              style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                    ),
                  )),
              const SizedBox(height: 24),
              // Resend
              Center(
                child: _canResend
                    ? GestureDetector(
                        onTap: _resend,
                        child: Text('Resend Code',
                            style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _primary)),
                      )
                    : Text(
                        'Resend code in ${_resendSeconds}s',
                        style: GoogleFonts.montserrat(
                            fontSize: 14, color: _textGray),
                      ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextFormField(
        controller: _otpCtrls[index],
        focusNode: _foci[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.montserrat(
            fontSize: 22, fontWeight: FontWeight.bold, color: _textDark),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _inputBorder, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primary, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _foci[index + 1].requestFocus();
          } else if (val.isEmpty && index > 0) {
            _foci[index - 1].requestFocus();
          }
          if (index == 5 && val.isNotEmpty && _otp.length == 6) {
            _verify();
          }
        },
      ),
    );
  }
}
