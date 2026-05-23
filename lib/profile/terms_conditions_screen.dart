// lib/profile/terms_conditions_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'contact_screen.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({Key? key}) : super(key: key);

  // ── Palette ───────────────────────────────────────────────────────────────
  static const Color _bg        = Color(0xFFF4F4FB);
  static const Color _surface   = Colors.white;
  static const Color _primary   = Color(0xFF1A1A2E);
  static const Color _secondary = Color(0xFF888888);
  static const Color _divider   = Color(0xFFEEEEF5);
  static const Color _accent    = Color(0xFF6C63FF);
  static const Color _body      = Color(0xFF444444);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          SizedBox(height: topPad),
          _buildTopBar(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _docHeader(),
                  const SizedBox(height: 24),
                  ..._buildSections(),
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

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
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
            'Terms & Conditions',
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

  // ── Doc header block ──────────────────────────────────────────────────────

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
            'Terms & Conditions',
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
            style: GoogleFonts.montserrat(fontSize: 12, color: _secondary),
          ),
        ],
      ),
    );
  }

  // ── Section list ──────────────────────────────────────────────────────────

  List<Widget> _buildSections() {
    return [
      _card('1. Introduction and Acceptance', [
        _para(
          'Welcome to Mjengo Hub ("we," "our," or "us"). These Terms and Conditions govern your use of mjengohub.co.ke and all related services, tools, and content provided by Mjengo Hub Ltd.',
        ),
        _para(
          'By accessing or using our website and services, you agree to be bound by these Terms. If you do not agree, you must not use our services.',
        ),
      ]),

      _card('2. About Our Services', [
        _para('Mjengo Hub is a comprehensive construction and blog platform providing:'),
        _bullets([
          'Professional construction services — architectural drawings, structural designs, BOQ preparation, interior design, and project management',
          'Digital construction tools — calculators for concrete, plaster, budgeting, and unit conversions',
          'Industry resources — construction news, articles, safety information, and educational content',
          'Educational content — tutorials, YouTube channel, and industry insights',
        ]),
      ]),

      _card('3. User Accounts', [
        _sub('3.1 Account Creation'),
        _para('When creating an account you agree to:'),
        _bullets([
          'Provide accurate, current, and complete information',
          'Maintain and update your account information',
          'Keep your login credentials secure and confidential',
          'Accept responsibility for all activities under your account',
          'Notify us immediately of any unauthorised use',
        ]),
        _sub('3.2 Account Termination'),
        _para(
          'We reserve the right to suspend or terminate your account at any time for violations of these Terms or at our sole discretion.',
        ),
      ]),

      _card('4. Use of Our Services', [
        _sub('4.1 Permitted Use'),
        _para(
          'You may use our services for lawful purposes related to construction, building, and professional development.',
        ),
        _sub('4.2 Prohibited Activities'),
        _para('You agree not to:'),
        _bullets([
          'Use our services for any illegal or unauthorised purpose',
          'Infringe on intellectual property rights of others',
          'Upload or transmit malicious code, viruses, or harmful content',
          'Attempt to gain unauthorised access to our systems',
          'Create fake accounts or impersonate others',
          'Scrape or extract data from our platform without permission',
          'Use our services to compete with us or create similar platforms',
        ]),
      ]),

      _card('5. Construction Services', [
        _sub('5.1 Service Delivery'),
        _para(
          'Our construction services are delivered by qualified professionals. Projects may be subject to changes in scope, material availability, weather conditions, and regulatory approvals.',
        ),
        _sub('5.2 Client Responsibilities'),
        _bullets([
          'Provide accurate project information and requirements',
          'Obtain necessary permits and approvals',
          'Ensure site accessibility and safety',
          'Make timely payments according to agreed terms',
          'Communicate changes or concerns promptly',
        ]),
        _sub('5.3 Professional Standards'),
        _para(
          'All construction services comply with Kenyan building codes, safety regulations, and industry standards. We maintain professional liability insurance and follow best practices.',
        ),
      ]),

      _card('6. Digital Tools & Calculators', [
        _sub('6.1 Tool Accuracy'),
        _para(
          'Our tools provide helpful estimates based on standard industry formulas. Results are estimates only and should be verified by qualified professionals. Actual requirements may vary.',
        ),
        _sub('6.2 Limitation of Liability for Tools'),
        _para(
          'We are not liable for any losses or damages resulting from the use of our digital tools. Users assume full responsibility for verifying calculations.',
        ),
      ]),

      _card('7. Payment Terms', [
        _sub('7.1 Service Fees'),
        _bullets([
          'Project deposits as specified in service agreements',
          'Progress payments based on project milestones',
          'Final payment upon project completion and approval',
        ]),
        _sub('7.2 Payment Methods'),
        _para(
          'We accept bank transfers, mobile money, and other secure payment options processed through trusted providers.',
        ),
        _sub('7.3 Late Payments'),
        _para(
          'Late payments may result in project delays and additional charges. We reserve the right to suspend services for overdue accounts.',
        ),
      ]),

      _card('8. Intellectual Property', [
        _sub('8.1 Our Content'),
        _para(
          'All platform content — text, images, logos, designs, software, and tools — is owned by Mjengo Hub or our licensors and is protected by intellectual property laws.',
        ),
        _sub('8.2 User Content'),
        _para(
          'When you submit content (reviews, comments, project details), you grant us a non-exclusive licence to use, display, and distribute such content for platform operations.',
        ),
        _sub('8.3 Design & Construction Documents'),
        _para(
          'Clients receive usage rights to completed designs for their specific projects. We retain intellectual property rights and may use project concepts for portfolio purposes with client consent.',
        ),
      ]),

      _card('9. Privacy & Data Protection', [
        _para(
          'Your privacy is important to us. Our collection, use, and protection of your personal information is governed by our Privacy Policy, which is incorporated into these Terms by reference.',
        ),
      ]),

      _card('10. Disclaimers & Liability', [
        _sub('10.1 Service Disclaimers'),
        _para('Our services are provided "as is." We make no warranties regarding:'),
        _bullets([
          'Uninterrupted or error-free service operation',
          'Accuracy or completeness of information',
          'Fitness for particular purposes',
          'Third-party content or services',
        ]),
        _sub('10.2 Limitation of Liability'),
        _para('To the maximum extent permitted by law, we are not liable for:'),
        _bullets([
          'Indirect, incidental, or consequential damages',
          'Loss of profits, data, or business opportunities',
          'Damages exceeding the amount paid for our services',
          'Force majeure events beyond our reasonable control',
        ]),
      ]),

      _card('11. Indemnification', [
        _para(
          'You agree to indemnify and hold harmless Mjengo Hub, its officers, employees, and agents from any claims, damages, or expenses arising from:',
        ),
        _bullets([
          'Your use of our services',
          'Violation of these Terms',
          'Infringement of third-party rights',
          'Your content or activities on our platform',
        ]),
      ]),

      _card('12. Third-Party Services', [
        _para('We are not responsible for:'),
        _bullets([
          'Third-party content, products, or services',
          'Privacy practices of external websites',
          'Accuracy or reliability of third-party information',
          'Transactions with third-party providers',
        ]),
        _para('Your interactions with third parties are solely between you and them.'),
      ]),

      _card('13. Dispute Resolution', [
        _sub('13.1 Informal Resolution'),
        _para(
          'We encourage resolving disputes through direct communication. Contact us at info@mjengohub.com to discuss any concerns.',
        ),
        _sub('13.2 Formal Resolution'),
        _bullets([
          'Mediation by a mutually agreed mediator',
          'Arbitration under Kenyan arbitration laws if mediation fails',
          'Court proceedings in Kenyan courts as a last resort',
        ]),
      ]),

      _card('14. Termination', [
        _para('Either party may terminate use of our services with appropriate notice. Upon termination:'),
        _bullets([
          'Your access to the platform will be discontinued',
          'Outstanding payments remain due',
          'Completed work and deliverables remain with the client',
          'Confidentiality obligations continue',
        ]),
      ]),

      _card('15. Changes to Terms', [
        _para('We may update these Terms from time to time, communicated via:'),
        _bullets([
          'Website notifications',
          'Email notifications for significant changes',
          'Updated "Last updated" date',
        ]),
        _para('Continued use of our services after changes indicates acceptance.'),
      ]),

      _card('16. Governing Law', [
        _para(
          'These Terms are governed by the laws of Kenya. All legal proceedings will be conducted in the courts of Kenya.',
        ),
      ]),

      _card('17. Severability', [
        _para(
          'If any provision of these Terms is found to be unenforceable, the remaining provisions continue in full force and effect.',
        ),
      ]),

      _card('18. Contact Us', [
        _contactRows(const [
          ('Company', 'Mjengo Hub Ltd'),
          ('Email',   'info@mjengohub.com'),
          ('Phone',   '+254 701 951 682'),
          ('Address', 'Nairobi, Kenya'),
          ('Website', 'mjengohub.co.ke'),
        ]),
        const SizedBox(height: 4),
        _para('We will respond to your enquiries promptly and professionally.'),
      ]),

      _card('19. Entire Agreement', [
        _para(
          'These Terms, together with our Privacy Policy and any service-specific agreements, constitute the entire agreement between you and Mjengo Hub regarding the use of our services.',
        ),
      ]),
    ];
  }

  // ── Card wrapper ──────────────────────────────────────────────────────────

  Widget _card(String title, List<Widget> children) {
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
          ...children,
        ],
      ),
    );
  }

  // ── Content helpers ───────────────────────────────────────────────────────

  Widget _para(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: _body,
            height: 1.65,
          ),
        ),
      );

  Widget _sub(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: _primary,
          ),
        ),
      );

  Widget _bullets(List<String> items) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items
              .map(
                (b) => Padding(
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
                          b,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: _body,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      );

  Widget _contactRows(List<(String, String)> rows) => Column(
        children: rows
            .map(
              (r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        r.$1,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        r.$2,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: _body,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      );

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
          _footerLink('Privacy Policy'),
          _dot(),
          _footerLink('Cookie Policy'),
          _dot(),
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

  Widget _dot() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text('•',
            style: GoogleFonts.montserrat(fontSize: 11, color: _divider)),
      );
}
