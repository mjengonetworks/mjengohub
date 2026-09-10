// lib/shared/screens/support_us_screen.dart
//
// The website's /support route runs a live M-Pesa/PayPal donation flow with
// no api.py equivalent (confirmed: donations have no JSON route). Rather than
// fake a payment flow the backend can't process, this mirrors the "why it
// matters" content and directs supporters to email/social, matching this
// app's established pattern for other backend gaps (Google sign-in, password
// reset, account deletion).
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../widgets/legal_doc_screen.dart';
import '../widgets/responsive.dart';

class SupportUsScreen extends StatelessWidget {
  const SupportUsScreen({super.key});

  static const _reasons = [
    ('Road Safety Campaign', 'Funds our Share Barabara road-safety awareness and incident reporting work.'),
    ('Industry News & Updates', 'Keeps our newsroom covering construction news, safety alerts, and project updates.'),
    ('Advocacy & Awareness', 'Amplifies our voice for better construction standards and sustainable building practices nationwide.'),
    ('Educational Content', 'Supports the tutorials, calculators, and safety resources we publish for free.'),
  ];

  Future<void> _emailUs() async {
    final uri = Uri.parse('mailto:info@mjengohub.com?subject=Supporting%20Mjengo%20Hub');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        foregroundColor: AppColors.headingSlate,
        titleSpacing: 0,
        title: Text(
          'Support Us',
          style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.headingSlate),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderSlate),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: ContentWidth(
          maxWidth: 760,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support Mjengo Hub',
                  style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.headingSlate, height: 1.2),
                ),
                const SizedBox(height: 10),
                Text(
                  'Every contribution, no matter the size, helps us continue promoting road safety and '
                  'delivering vital construction-industry news that protects lives.',
                  style: GoogleFonts.montserrat(fontSize: 14.5, color: AppColors.bodyCharcoal, height: 1.55),
                ),
                const SizedBox(height: 28),

                Text(
                  'Why Your Support Matters',
                  style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.headingSlate),
                ),
                const SizedBox(height: 14),
                for (final r in _reasons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.borderSlate),
                        borderRadius: BorderRadius.circular(AppRadius.sharp),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.$1, style: GoogleFonts.montserrat(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.headingSlate)),
                          const SizedBox(height: 4),
                          Text(r.$2, style: GoogleFonts.montserrat(fontSize: 14, color: AppColors.bodyCharcoal, height: 1.55)),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kDocCalloutBg,
                    border: Border.all(color: AppColors.borderSlate),
                    borderRadius: BorderRadius.circular(AppRadius.sharp),
                  ),
                  child: Text(
                    "In-app donations aren't set up yet — email us and we'll share how to contribute "
                    'via M-Pesa or another method.',
                    style: GoogleFonts.montserrat(fontSize: 14, color: AppColors.bodyCharcoal, height: 1.55),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _emailUs,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.headingSlate,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sharp)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.mail_outline_rounded, size: 18),
                    label: Text('Email Us to Support', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),

                const SizedBox(height: 24),
                Container(height: 1, color: AppColors.borderSlate),
                const SizedBox(height: 16),
                Text(
                  'mjengohub.co.ke/support',
                  style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.captionSlate),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
