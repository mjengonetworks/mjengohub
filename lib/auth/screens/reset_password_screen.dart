// lib/auth/screens/reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/mjengo_auth_controller.dart';
import '../../shared/theme/app_theme.dart';

// ── Palette (matches login_screen.dart) ───────────────────────────────────────
const Color _accent      = Color(0xFF3B82F6);
const Color _bg          = Color(0xFFFFFFFF);
const Color _inputBg     = Color(0xFFF4F4FB);
const Color _inputBorder = Color(0xFFE8E8F0);
const Color _textDark    = Color(0xFF1A1A2E);
const Color _textGray    = Color(0xFF475569);

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  late final MjengoAuthController _auth;

  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _auth = Get.find<MjengoAuthController>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _auth.clearError());
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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

            // ── Top row: logo + back ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/mjengo_hub_logo.png',
                  height: 42,
                  fit: BoxFit.contain,
                ),
                _BackPill(onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                }),
              ],
            ),

            const SizedBox(height: 40),

            // ── Heading ───────────────────────────────────────────────────
            Text(
              _emailSent ? 'Email\nSent!' : 'Forgot\nPassword?',
              style: GoogleFonts.montserrat(
                fontSize: 36,
                fontWeight: FontWeight.w500,
                color: _textDark,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _emailSent
                  ? 'Check your inbox for the reset link. It expires in 1 hour.'
                  : "No worries! Enter your email and we'll send you a reset link.",
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: _textGray,
                height: 1.55,
              ),
            ),

            const SizedBox(height: 36),

            // ── Content ───────────────────────────────────────────────────
            if (!_emailSent) ...[
              _buildForm(),
            ] else ...[
              _buildSuccessCard(),
              const SizedBox(height: 16),
              _buildResendButton(),
            ],

            const SizedBox(height: 28),

            // ── Back to login link ─────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.montserrat(
                        fontSize: 13, color: _textGray),
                    children: [
                      const TextSpan(text: 'Remember it? '),
                      TextSpan(
                        text: 'Back to login',
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

  // ── Form ───────────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label('Email'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _sendReset(),
            style: GoogleFonts.montserrat(fontSize: 14, color: _textDark),
            decoration: InputDecoration(
              hintText: 'you@example.com',
              hintStyle: GoogleFonts.montserrat(fontSize: 14, color: _textGray),
              prefixIcon: const Icon(Icons.email_outlined,
                  size: 18, color: _textGray),
              filled: true,
              fillColor: _inputBg,
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
                borderSide:
                    const BorderSide(color: Colors.redAccent, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Colors.redAccent, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              errorStyle: GoogleFonts.montserrat(fontSize: 11),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter your email';
              if (!RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(v)) {
                return 'Enter a valid email address';
              }
              return null;
            },
            onChanged: (_) {
              if (_auth.errorMessage.isNotEmpty) _auth.clearError();
            },
          ),

          // ── Error box ─────────────────────────────────────────────────
          Obx(() {
            final msg = _auth.errorMessage;
            if (msg.isEmpty) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(top: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    child: Text(
                      msg,
                      style: GoogleFonts.montserrat(
                          fontSize: 12, color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 28),

          // ── Send button ───────────────────────────────────────────────
          Obx(() => SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _auth.isLoading ? null : _sendReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    disabledBackgroundColor: _accent.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send_rounded,
                                color: Colors.white, size: 17),
                            const SizedBox(width: 8),
                            Text(
                              'Send Reset Link',
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              )),
        ],
      ),
    );
  }

  // ── Success card ───────────────────────────────────────────────────────────

  Widget _buildSuccessCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(AppRadius.sharpLg),
        border: Border.all(color: _accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration:
                const BoxDecoration(color: _accent, shape: BoxShape.circle),
            child: const Icon(Icons.mark_email_read_outlined,
                color: Colors.white, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            'Link sent!',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We sent a reset link to:',
            style: GoogleFonts.montserrat(fontSize: 13, color: _textGray),
          ),
          const SizedBox(height: 4),
          Text(
            _maskEmail(_emailCtrl.text),
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check your inbox and spam folder.\nThe link expires in 1 hour.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: _textGray,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Resend button ──────────────────────────────────────────────────────────

  Widget _buildResendButton() {
    return Obx(() => SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: _auth.isLoading ? null : _resend,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _accent, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _auth.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(_accent)),
                  )
                : Text(
                    'Resend Link',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _accent,
                    ),
                  ),
          ),
        ));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Masks most of the email — e.g. `john.doe@gmail.com` → `j***@g***.com`
  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final local  = parts[0];
    final domain = parts[1].split('.');

    final maskedLocal = local.isEmpty
        ? '*'
        : local.length <= 2
            ? '*' * local.length
            : '${local[0]}${'*' * (local.length - 1)}';

    final domainName   = domain[0];
    final maskedDomain = domainName.isEmpty
        ? '*'
        : domainName.length <= 2
            ? '*' * domainName.length
            : '${domainName[0]}${'*' * (domainName.length - 1)}';

    final tld = domain.sublist(1).join('.');
    return '$maskedLocal@$maskedDomain.$tld';
  }

  Future<void> _sendReset() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    final ok = await _auth.forgotPassword(email: _emailCtrl.text.trim());
    if (ok && mounted) setState(() => _emailSent = true);
  }

  Future<void> _resend() async {
    HapticFeedback.lightImpact();
    final ok = await _auth.forgotPassword(email: _emailCtrl.text.trim());
    if (ok && mounted) {
      Get.snackbar(
        'Sent',
        'Reset link sent again to ${_maskEmail(_emailCtrl.text)}',
        backgroundColor: _accent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 10,
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      );
    }
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

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
