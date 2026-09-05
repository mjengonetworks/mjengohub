// lib/shared/widgets/section_header.dart
//
// Shared "executive architectural" section header (Spec 1 + Spec 10): sharp
// high-contrast heading + optional subtitle + a right-aligned "View All"
// link with a plain arrow icon (no emoji/clipart). Used by every rebuilt
// homepage section and any other section that wants the same look.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'preview_data_badge.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;
  final String seeAllLabel;

  /// True when the section below is showing fallback/demo data because the
  /// live API returned nothing.
  final bool isDemo;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onSeeAll,
    this.seeAllLabel = 'View All',
    this.isDemo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.montserrat(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.headingSlate,
                        ),
                      ),
                    ),
                    if (isDemo) const Padding(padding: EdgeInsets.only(left: 8), child: PreviewDataBadge()),
                  ],
                ),
              ),
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        seeAllLabel,
                        style: GoogleFonts.montserrat(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentBlue,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_forward, size: 14, color: AppColors.accentBlue),
                    ],
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.captionSlate, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}
