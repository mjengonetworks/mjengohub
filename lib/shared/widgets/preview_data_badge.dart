// lib/shared/widgets/preview_data_badge.dart
//
// Shown next to a section header or over a card when its content is
// fallback/demo data rather than a live API response — e.g. when the host's
// bot-protection firewall 403s a request. Must always accompany fallback
// content so it's never mistaken for real civic data (project status,
// safety incidents, news).
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class PreviewDataBadge extends StatelessWidget {
  const PreviewDataBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Text(
        'PREVIEW',
        style: GoogleFonts.montserrat(
          fontSize: 8.5,
          fontWeight: FontWeight.w500,
          color: AppColors.warning,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
