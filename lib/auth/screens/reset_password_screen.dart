import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/user_controller.dart';

const Color _primary     = Color(0xFF3B82F6);
const Color _primaryDeep = Color(0xFF1D4ED8);
const Color _scaffoldBg  = Color(0xFFFFFFFF);
const Color _inputBg     = Color(0xFFF3F4F6);
const Color _textDark    = Color(0xFF111827);
const Color _textGray    = Color(0xFF6B7280);
const Color _inputBorder = Color(0xFFE5E7EB);

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final UserController _ctrl = Get.find<UserController>();

  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.clearError());
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    Widget content = Column(
      children: [
        // ── Blue blob header ─────────────────────────────────────────
        _BlobHeader(emailSent: _emailSent, onBack: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
        }),
        // ── Scrollable form ──────────────────────────────────────────
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
                const SizedBox(height: 28),
                Text(
                  _emailSent
                      ? 'Check your inbox'
                      : 'No worries! Enter your email and we\'ll send you a reset link.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: _textGray,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 28),
                if (!_emailSent) ...[
                  _buildForm(),
                ] else ...[
                  _buildSuccessCard(),
                  const SizedBox(height: 20),
                  _buildResendButton(),
                ],
                const SizedBox(height: 28),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(fontSize: 13, color: _textGray),
                        children: [
                          const TextSpan(text: 'Remember it? '),
                          TextSpan(
                            text: 'Back to login',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _primary,
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

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel('Email'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.poppins(fontSize: 14, color: _textDark),
            decoration: InputDecoration(
              hintText: 'you@example.com',
              hintStyle: GoogleFonts.poppins(fontSize: 14, color: _textGray),
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
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter your email';
              if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v))
                return 'Enter a valid email';
              return null;
            },
            onChanged: (_) {
              if (_ctrl.errorMessage.isNotEmpty) _ctrl.clearError();
            },
          ),
          Obx(() {
            final msg = _ctrl.errorMessage;
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
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          Obx(() => SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _ctrl.isLoading ? null : _sendReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _primary.withOpacity(0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _ctrl.isLoading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      'Send Reset Link',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
            child: const Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            'Email sent!',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We sent a reset link to:',
            style: GoogleFonts.poppins(fontSize: 13, color: _textGray),
          ),
          const SizedBox(height: 4),
          Text(
            _maskEmail(_emailController.text),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check your inbox and spam folder.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, color: _textGray),
          ),
        ],
      ),
    );
  }

  Widget _buildResendButton() {
    return Obx(() => SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: _ctrl.isLoading ? null : _resend,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: _ctrl.isLoading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(_primary),
                ),
              )
            : Text(
                'Resend Email',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _primary,
                ),
              ),
      ),
    ));
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1].split('.');
    final maskedName = name.length <= 2
        ? '*' * name.length
        : '${name[0]}${'*' * (name.length - 1)}';
    final maskedDomain =
        '${domain[0][0]}${'*' * (domain[0].length - 1)}.${domain.sublist(1).join('.')}';
    return '$maskedName@$maskedDomain';
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    final success = await _ctrl.resetPassword(email: _emailController.text.trim());
    if (success && mounted) setState(() => _emailSent = true);
  }

  Future<void> _resend() async {
    HapticFeedback.lightImpact();
    final success = await _ctrl.resetPassword(email: _emailController.text.trim());
    if (success && mounted) {
      Get.snackbar(
        'Sent',
        'Reset link sent again to ${_maskEmail(_emailController.text)}',
        backgroundColor: _primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 10,
      );
    }
  }
}

// ─── Blue Blob Header ─────────────────────────────────────────────────────────

class _BlobHeader extends StatelessWidget {
  final bool emailSent;
  final VoidCallback onBack;
  const _BlobHeader({required this.emailSent, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: 220 + topPadding,
      child: Stack(
        children: [
          // Blue gradient blob
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
          // Back button top left
          Positioned(
            top: topPadding + 16,
            left: 24,
            child: GestureDetector(
              onTap: onBack,
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
            ),
          ),
          // Centred heading
          Positioned(
            bottom: 28,
            left: 28,
            right: 28,
            child: Text(
              emailSent ? 'Email Sent' : 'Forgot\nPassword?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 38,
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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _textGray,
      ),
    );
  }
}
