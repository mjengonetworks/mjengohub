// lib/profile/contact_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../shared/theme/app_theme.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({Key? key}) : super(key: key);

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  // ── Palette ────────────────────────────────────────────────────────────────
  static const Color _bg        = Color(0xFFF4F4FB);
  static const Color _surface   = Colors.white;
  static const Color _primary   = Color(0xFF1A1A2E);
  static const Color _secondary = Color(0xFF475569);
  static const Color _divider   = Color(0xFFEEEEF5);
  static const Color _accent    = Color(0xFF6C63FF);
  static const Color _body      = Color(0xFF444444);

  // ── Form state ─────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl   = TextEditingController();
  final _lastCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _messageCtrl = TextEditingController();
  String? _inquiryType;
  bool _sending = false;
  bool _sent    = false;

  static const _inquiryTypes = [
    'Advertising & Partnerships',
    'Professional Construction Services',
    'General Inquiry',
    'Feedback or Suggestions',
    'Other',
  ];

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  // ── URL helpers ────────────────────────────────────────────────────────────

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) return;
    // Genuine web pages (maps, social profiles) open in-app like the rest of
    // the app's external links; tel:/mailto: intents have no "page" to
    // browse, so those still hand off to the native dialer/mail client.
    final isWebLink = uri.scheme == 'http' || uri.scheme == 'https';
    await launchUrl(uri, mode: isWebLink ? LaunchMode.inAppBrowserView : LaunchMode.externalApplication);
  }

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);

    final name    = '${_firstCtrl.text.trim()} ${_lastCtrl.text.trim()}';
    final subject = '[Mjengo Hub] ${_inquiryType ?? 'General Inquiry'}';
    final body    = 'Name: $name\nEmail: ${_emailCtrl.text.trim()}'
        '${_phoneCtrl.text.trim().isNotEmpty ? '\nPhone: ${_phoneCtrl.text.trim()}' : ''}'
        '\n\n${_messageCtrl.text.trim()}';

    final uri = Uri(
      scheme: 'mailto',
      path: 'info@mjengohub.com',
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    await launchUrl(uri);

    setState(() {
      _sending = false;
      _sent    = true;
    });

    _formKey.currentState!.reset();
    _firstCtrl.clear();
    _lastCtrl.clear();
    _emailCtrl.clear();
    _phoneCtrl.clear();
    _messageCtrl.clear();
    setState(() => _inquiryType = null);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          SizedBox(height: topPad),
          _topBar(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _heroCard(),
                  const SizedBox(height: 16),
                  _contactMethods(),
                  const SizedBox(height: 16),
                  _infoStrip(),
                  const SizedBox(height: 16),
                  _socialCard(),
                  const SizedBox(height: 16),
                  _formCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _topBar(BuildContext context) {
    return Container(
      color: _surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back_rounded, color: _primary, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'Contact & Support',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: _primary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero card ──────────────────────────────────────────────────────────────

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sharpLg),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF2C2C4E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MJENGO HUB',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.8,
              color: _accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get in Touch',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reach out for advertising enquiries, construction services, or any questions. We respond within 24 hours.',
            style: GoogleFonts.montserrat(
              fontSize: 12.5,
              color: Colors.white.withOpacity(0.65),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Contact method cards ───────────────────────────────────────────────────

  Widget _contactMethods() {
    return Column(
      children: [
        _methodCard(
          icon: Icons.email_outlined,
          title: 'Email Us',
          subtitle: 'We\'ll respond within 24 hours',
          value: 'info@mjengohub.com',
          onTap: () => _launch('mailto:info@mjengohub.com'),
        ),
        const SizedBox(height: 10),
        _methodCard(
          icon: Icons.phone_outlined,
          title: 'Call Us',
          subtitle: 'Speak with our experts directly',
          value: '+254 701 951 682',
          onTap: () => _launch('tel:+254701951682'),
        ),
        const SizedBox(height: 10),
        _methodCard(
          icon: Icons.location_on_outlined,
          title: 'Visit Our Office',
          subtitle: 'Come see us in person',
          value: 'Nairobi, Kenya',
          onTap: () => _launch('https://maps.google.com/?q=Nairobi,Kenya'),
        ),
      ],
    );
  }

  Widget _methodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _divider, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: _accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.montserrat(
                          fontSize: 13, fontWeight: FontWeight.w500, color: _primary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.montserrat(fontSize: 11, color: _secondary)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: GoogleFonts.montserrat(
                          fontSize: 12.5, fontWeight: FontWeight.w600, color: _accent)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: _secondary.withOpacity(0.5), size: 20),
          ],
        ),
      ),
    );
  }

  // ── Info strip ─────────────────────────────────────────────────────────────

  Widget _infoStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _stripItem(Icons.access_time_rounded, 'Response', 'Under 24 hrs'),
          _stripDivider(),
          _stripItem(Icons.calendar_today_rounded, 'Hours', 'Mon–Sat 8–6pm'),
          _stripDivider(),
          _stripItem(Icons.place_rounded, 'Location', 'Nairobi, Kenya'),
        ],
      ),
    );
  }

  Widget _stripItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: _accent),
          const SizedBox(height: 5),
          Text(label,
              style: GoogleFonts.montserrat(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.5),
                  letterSpacing: 0.5)),
          const SizedBox(height: 3),
          Text(value,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _stripDivider() => Container(
      width: 0.8, height: 40, color: Colors.white.withOpacity(0.12));

  // ── Social card ────────────────────────────────────────────────────────────

  Widget _socialCard() {
    const socials = [
      ('LinkedIn',  Icons.work_outline_rounded,      'https://www.linkedin.com/in/mjengohub'),
      ('Facebook',  Icons.facebook_rounded,           'https://www.facebook.com/share/1HPY3N93XK/'),
      ('Twitter',   Icons.close_rounded,              'https://x.com/mjengohub'),
      ('Instagram', Icons.camera_alt_outlined,        'https://instagram.com/mjengohub'),
      ('YouTube',   Icons.play_circle_outline_rounded,'https://www.youtube.com/@mjengohubke'),
      ('TikTok',    Icons.music_note_rounded,         'https://tiktok.com/@mjengohubke'),
      ('WhatsApp',  Icons.chat_outlined,              'https://whatsapp.com/channel/0029VaYauR9JkK9FLwHSCH2k'),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Follow Us',
              style: GoogleFonts.montserrat(
                  fontSize: 13, fontWeight: FontWeight.w500, color: _primary)),
          const SizedBox(height: 4),
          Text('Stay updated with industry news and tips.',
              style: GoogleFonts.montserrat(fontSize: 11.5, color: _secondary)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: socials
                .map((s) => _socialChip(s.$1, s.$2, s.$3))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _socialChip(String label, IconData icon, String url) {
    return GestureDetector(
      onTap: () => _launch(url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _divider, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: _accent),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 11.5, fontWeight: FontWeight.w600, color: _primary)),
          ],
        ),
      ),
    );
  }

  // ── Contact form ───────────────────────────────────────────────────────────

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider, width: 0.8),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send Us a Message',
                style: GoogleFonts.montserrat(
                    fontSize: 16, fontWeight: FontWeight.w500, color: _primary)),
            const SizedBox(height: 4),
            Text('We\'ll get back to you shortly.',
                style: GoogleFonts.montserrat(fontSize: 12, color: _secondary)),
            const SizedBox(height: 16),
            const Divider(color: _divider, height: 1, thickness: 0.8),
            const SizedBox(height: 18),

            // ── Success banner ────────────────────────────────────────
            if (_sent) ...[
              _successBanner(),
              const SizedBox(height: 16),
            ],

            // ── Name row ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(child: _field('First Name', _firstCtrl, required: true)),
                const SizedBox(width: 12),
                Expanded(child: _field('Last Name', _lastCtrl, required: true)),
              ],
            ),
            const SizedBox(height: 14),

            // ── Email ─────────────────────────────────────────────────
            _field('Email Address', _emailCtrl,
                required: true,
                keyboard: TextInputType.emailAddress,
                validator: (v) {
              final val = v?.trim() ?? '';
              if (val.isEmpty) return 'Required';
              if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(val)) {
                return 'Enter a valid email';
              }
              return null;
            }),
            const SizedBox(height: 14),

            // ── Phone ─────────────────────────────────────────────────
            _field('Phone Number (optional)', _phoneCtrl,
                keyboard: TextInputType.phone),
            const SizedBox(height: 14),

            // ── Inquiry type dropdown ─────────────────────────────────
            _dropdownField(),
            const SizedBox(height: 14),

            // ── Message ───────────────────────────────────────────────
            _field('Message', _messageCtrl,
                required: true, maxLines: 4,
                hint: 'Tell us about your project or enquiry…'),
            const SizedBox(height: 20),

            // ── Submit ────────────────────────────────────────────────
            _submitButton(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, size: 12, color: _secondary),
                const SizedBox(width: 4),
                Text('Your information is safe and never shared.',
                    style: GoogleFonts.montserrat(fontSize: 10.5, color: _secondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.montserrat(
                fontSize: 11.5, fontWeight: FontWeight.w600, color: _primary),
            children: required
                ? [
                    TextSpan(
                      text: '  *',
                      style: GoogleFonts.montserrat(
                          color: _accent, fontWeight: FontWeight.w500),
                    )
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          maxLines: maxLines,
          style: GoogleFonts.montserrat(fontSize: 13, color: _primary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.montserrat(fontSize: 12.5, color: const Color(0xFF475569)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: _bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _accent.withOpacity(0.6), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            errorStyle: GoogleFonts.montserrat(fontSize: 10.5),
          ),
          validator: validator ??
              (required
                  ? (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null
                  : null),
        ),
      ],
    );
  }

  Widget _dropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Inquiry Type',
            style: GoogleFonts.montserrat(
                fontSize: 11.5, fontWeight: FontWeight.w600, color: _primary),
            children: [
              TextSpan(
                text: '  *',
                style: GoogleFonts.montserrat(
                    color: _accent, fontWeight: FontWeight.w500),
              )
            ],
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _inquiryType,
          hint: Text('Select an option…',
              style: GoogleFonts.montserrat(
                  fontSize: 12.5, color: const Color(0xFF475569))),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: _secondary, size: 20),
          style: GoogleFonts.montserrat(fontSize: 13, color: _primary),
          dropdownColor: _surface,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: _bg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _divider)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _divider)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _accent.withOpacity(0.6), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.redAccent)),
            errorStyle: GoogleFonts.montserrat(fontSize: 10.5),
          ),
          items: _inquiryTypes
              .map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t,
                        style: GoogleFonts.montserrat(
                            fontSize: 13, color: _primary)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _inquiryType = v),
          validator: (v) => v == null ? 'Please select a type' : null,
        ),
      ],
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _sending ? null : _sendEmail,
        icon: _sending
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.send_rounded, size: 17, color: Colors.white),
        label: Text(
          _sending ? 'Sending…' : 'Send Message',
          style: GoogleFonts.montserrat(
              fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          disabledBackgroundColor: _accent.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _successBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F9EE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF86EFAC), width: 0.8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: Color(0xFF16A34A), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your email client has been opened. Thank you for reaching out!',
              style: GoogleFonts.montserrat(
                  fontSize: 12, color: const Color(0xFF15803D), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
