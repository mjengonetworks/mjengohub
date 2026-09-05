import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// One numbered partner-banner placeholder (homepage Spec-10 slots 1-5).
/// `slotNumber` is purely a debug/QA label — each slot is otherwise
/// identical until real partner-ad content is wired up server-side.
class AdBannerSlot extends StatelessWidget {
  final String slotId;
  final double height;
  final int? slotNumber;

  const AdBannerSlot({
    Key? key,
    this.slotId = 'mjengo-feed-ad',
    this.height = 90,
    this.slotNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppRadius.sharp),
        border: Border.all(color: AppColors.borderSlate),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              slotNumber != null ? 'SPONSORED — SLOT $slotNumber' : 'SPONSORED / ADVERTISEMENT',
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.captionSlate,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Partner with Mjengo Hub',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.headingSlate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
