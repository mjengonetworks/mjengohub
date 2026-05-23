// lib/profile/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'terms_conditions_screen.dart';
import 'contact_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  // ── Palette (matches app theme) ───────────────────────────────────────────
  static const Color _bg          = Color(0xFFF4F4FB);
  static const Color _surface     = Colors.white;
  static const Color _primary     = Color(0xFF1A1A2E);
  static const Color _secondary   = Color(0xFF888888);
  static const Color _divider     = Color(0xFFEEEEF5);
  static const Color _accent      = Color(0xFF6C63FF);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          SizedBox(height: topPad),
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ── Doc header ─────────────────────────────────────────
                  _docHeader(),

                  const SizedBox(height: 24),

                  // ── Sections ───────────────────────────────────────────
                  _section(
                    '1. Introduction',
                    'Welcome to Mjengo Hub ("we," "our," or "us"). We are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our platform at mjengohub.co.ke.',
                  ),

                  _section(
                    '2. Information We Collect',
                    'We may collect personal information you voluntarily provide when you register for an account, subscribe to our newsletter, contact us, request quotes, or use our tools.\n\nThis may include your name, email address, phone number, professional details, project information, and payment details (processed securely via third-party providers).\n\nWe also automatically collect device and usage data such as IP address, browser type, pages visited, and device identifiers.',
                  ),

                  _section(
                    '3. How We Use Your Information',
                    null,
                    bullets: [
                      'Service Delivery — process quotes and fulfil your requests',
                      'Communication — respond to enquiries and provide support',
                      'Platform Improvement — analyse usage and improve functionality',
                      'Marketing — send industry updates with your consent',
                      'Legal Compliance — comply with applicable laws',
                      'Security — protect against fraud and unauthorised access',
                    ],
                  ),

                  _section(
                    '4. Information Sharing',
                    'We do not sell, trade, or rent your personal information. We may share it only with trusted service providers (hosting, payments, analytics), when required by law, or in the event of a business transfer or merger.',
                  ),

                  _section(
                    '5. Data Security',
                    'We implement SSL encryption, secure server infrastructure, regular security audits, access controls, and employee training. However, no internet transmission is 100% secure.',
                  ),

                  _section(
                    '6. Cookies & Tracking',
                    'Our platform uses cookies to remember your preferences, analyse traffic, and personalise content. You can control cookie settings in your device browser, though disabling them may affect some features.',
                  ),

                  _section(
                    '7. Your Rights',
                    null,
                    bullets: [
                      'Access — request a copy of your data',
                      'Correction — fix inaccurate information',
                      'Deletion — request removal of your data',
                      'Portability — receive your data in a portable format',
                      'Opt-out — unsubscribe from marketing at any time',
                    ],
                    note: 'To exercise these rights, contact us at info@mjengohub.com.',
                  ),

                  _section(
                    '8. Third-Party Links',
                    'Our platform may link to external sites. We are not responsible for the privacy practices of those sites and encourage you to review their policies independently.',
                  ),

                  _section(
                    "9. Children's Privacy",
                    'Our services are not intended for individuals under 18. We do not knowingly collect data from children. If we become aware of such data, we will delete it promptly.',
                  ),

                  _section(
                    '10. International Transfers',
                    'Your data may be transferred to and processed in countries outside Kenya. We ensure all transfers comply with applicable data protection laws.',
                  ),

                  _section(
                    '11. Policy Changes',
                    'We may update this policy from time to time. We will notify you by posting the updated policy and updating the "Last updated" date. Continued use of our services after changes constitutes acceptance.',
                  ),

                  _section(
                    '12. Contact Us',
                    null,
                    contactRows: const [
                      ('Company',  'Mjengo Hub Ltd'),
                      ('Email',    'info@mjengohub.com'),
                      ('Phone',    '+254 701 951 682'),
                      ('Address',  'Nairobi, Kenya'),
                      ('Website',  'mjengohub.co.ke'),
                    ],
                  ),

                  _section(
                    '13. Governing Law',
                    'This Privacy Policy is governed by the laws of Kenya. Any disputes arising from this policy are subject to the exclusive jurisdiction of the courts of Kenya.',
                  ),

                  // ── Footer ─────────────────────────────────────────────
                  const SizedBox(height: 8),
                  _footer(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header bar ──────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: _surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back_rounded,
                color: _primary, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'Privacy Policy',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Doc header (title block) ───────────────────────────────────────────────

  Widget _docHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MJENGO HUB',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: _accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Privacy Policy',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _primary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Last updated: July 28, 2025',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: _secondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section builder ────────────────────────────────────────────────────────

  Widget _section(
    String title,
    String? body, {
    List<String>? bullets,
    String? note,
    List<(String, String)>? contactRows,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            title.toUpperCase(),
            style: GoogleFonts.montserrat(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: _primary,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: _divider, height: 1, thickness: 0.8),
          const SizedBox(height: 12),

          // Body paragraph
          if (body != null) ...[
            Text(
              body,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: const Color(0xFF444444),
                height: 1.65,
              ),
            ),
          ],

          // Bullet list
          if (bullets != null) ...[
            ...bullets.map((b) => _bullet(b)),
          ],

          // Optional note below bullets
          if (note != null) ...[
            const SizedBox(height: 10),
            Text(
              note,
              style: GoogleFonts.montserrat(
                fontSize: 12.5,
                color: _secondary,
                height: 1.5,
              ),
            ),
          ],

          // Contact rows
          if (contactRows != null) ...[
            ...contactRows.map((row) => _contactRow(row.$1, row.$2)),
          ],
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 5, color: _accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: const Color(0xFF444444),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _primary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: const Color(0xFF444444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _footer(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _footerLink('Cookie Policy'),
          _footerDot(),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const TermsConditionsScreen(),
              ),
            ),
            child: _footerLink('Terms & Conditions'),
          ),
          _footerDot(),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ContactScreen()),
            ),
            child: _footerLink('Contact Us'),
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String label) => Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: _secondary,
          decoration: TextDecoration.underline,
          decorationColor: _secondary,
        ),
      );

  Widget _footerDot() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          '•',
          style: GoogleFonts.montserrat(fontSize: 11, color: _divider),
        ),
      );
}
