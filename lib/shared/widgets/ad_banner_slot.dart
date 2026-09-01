import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdBannerSlot extends StatelessWidget {
  final String slotId;
  final double height;

  const AdBannerSlot({
    Key? key,
    this.slotId = 'mjengo-feed-ad',
    this.height = 100,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SPONSORED / ADVERTISEMENT',
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF9CA3AF),
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Partner with Mjengo Hub',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
