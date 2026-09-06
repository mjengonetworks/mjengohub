// lib/shared/screens/about_screen.dart
//
// The website has no standalone "About Us" page today — its nav links to an
// external redirect for the parent company. This screen fills that gap with
// content sourced from the platform's own scope (the six trackers, footer
// blurb, entity details) rather than inventing anything.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../widgets/legal_doc_screen.dart';
import '../widgets/responsive.dart';
import 'advertise_screen.dart';
import 'support_us_screen.dart';
import '../../profile/contact_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  static const _trackers = [
    ('Infrastructure Tracker', "Kenya's roads, bridges & public infrastructure projects"),
    ('Private Developments', 'Commercial & residential developments across the country'),
    ('Built History', "Kenya's architectural & infrastructure heritage"),
    ('Africa & World', 'Landmark projects across the continent and beyond'),
    ('Site Safety', 'A database of construction-site safety incidents'),
    ('Merch', 'Mjengo Hub branded gear'),
  ];

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
          'About Us',
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
                  'Mjengo Hub',
                  style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.headingSlate, height: 1.2),
                ),
                const SizedBox(height: 10),
                Text(
                  "Kenya's leading construction industry platform — news and expert analysis, "
                  'live Infrastructure and Private Developments trackers, road and site safety, '
                  'and a community for professionals and the public alike.',
                  style: GoogleFonts.montserrat(fontSize: 14.5, fontWeight: FontWeight.w400, color: AppColors.bodyCharcoal, height: 1.55),
                ),
                const SizedBox(height: 28),

                _heading('What We Cover'),
                const SizedBox(height: 12),
                for (final t in _trackers) _trackerRow(t.$1, t.$2),

                const SizedBox(height: 28),
                _heading('Community Submissions'),
                const SizedBox(height: 10),
                Text(
                  'Beyond editorial coverage, Mjengo Hub is built with its community: readers submit '
                  'projects for tracking, file infrastructure and site-safety reports, write reviews, '
                  'and contribute to Mshikamano, our mental-health support space for industry '
                  'professionals. Verified contributions earn points and reviewer standing through our '
                  'gamification system.',
                  style: GoogleFonts.montserrat(fontSize: 14.5, color: AppColors.bodyCharcoal, height: 1.55),
                ),

                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kDocCalloutBg,
                    border: Border.all(color: AppColors.borderSlate),
                    borderRadius: BorderRadius.circular(AppRadius.sharp),
                  ),
                  child: Text(
                    'Tracker data and cost indices on Mjengo Hub are published for journalistic and '
                    'informational purposes only. They are not legal or engineering certifications, and '
                    'not a guarantee relating to tender procurement or contract award.',
                    style: GoogleFonts.montserrat(fontSize: 14.5, color: AppColors.bodyCharcoal, height: 1.55),
                  ),
                ),

                const SizedBox(height: 28),
                _heading('The Company'),
                const SizedBox(height: 10),
                Text(
                  'Mjengo Hub is operated by Mjengo Networks Limited, a company registered in Nairobi, '
                  'Kenya.',
                  style: GoogleFonts.montserrat(fontSize: 14.5, color: AppColors.bodyCharcoal, height: 1.55),
                ),

                const SizedBox(height: 28),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _linkButton(
                      icon: Icons.campaign_outlined,
                      label: 'Partner With Us',
                      onTap: () => Get.to(() => const AdvertiseScreen()),
                    ),
                    _linkButton(
                      icon: Icons.favorite_border_rounded,
                      label: 'Support Us',
                      onTap: () => Get.to(() => const SupportUsScreen()),
                    ),
                    _linkButton(
                      icon: Icons.mail_outline_rounded,
                      label: 'Contact Us',
                      onTap: () => Get.to(() => const ContactScreen()),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Container(height: 1, color: AppColors.borderSlate),
                const SizedBox(height: 16),
                Text(
                  'mjengohub.co.ke/about',
                  style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.captionSlate),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heading(String text) => Text(
        text,
        style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.headingSlate),
      );

  Widget _trackerRow(String title, String subtitle) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6, right: 10),
              width: 4,
              height: 4,
              decoration: const BoxDecoration(color: AppColors.captionSlate, shape: BoxShape.circle),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.montserrat(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.headingSlate)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.captionSlate, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _linkButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.borderSlate),
          borderRadius: BorderRadius.circular(AppRadius.sharp),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.captionSlate),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.headingSlate)),
          ],
        ),
      ),
    );
  }
}
