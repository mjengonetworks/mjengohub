// lib/shared/theme/app_theme.dart
//
// Central design tokens ported from the MjengoHub website's static/css/main.css
// (brand blue #4A90E2 -> #357abd, pill CTA shapes, badge palette) so the
// Flutter app and the web platform read as the same product.
import 'package:flutter/material.dart';

class AppColors {
  // Compatibility aliases
  static const Color primary = Color(0xFF2563EB);
  static const Color accent = Color(0xFF2563EB);
  static const Color textLight = Color(0xFF8888AA);

  AppColors._();

  // Brand blue — matches --primary-blue / --secondary-blue in main.css
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color secondaryBlue = Color(0xFF357ABD);
  static const Color darkBlue = Color(0xFF2968A3);
  static const Color deepNavy = Color(0xFF2C3E50);

  // App accent (existing in-app blue, kept for continuity with current screens)
  static const Color accentBlue = Color(0xFF2563EB);

  static const Color surface = Colors.white;
  static const Color background = Color(0xFFF0F4FF);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textSubtle = Color(0xFF8888AA);
  static const Color divider = Color(0xFFEEEEF5);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);

  // Mjengo Hub Prime badge blue
  static const Color primeBadge = Color(0xFF2C5AA0);

  // "Executive architectural" design-system pass: sharp-corner surfaces get
  // a crisp 1px slate border instead of a shadow, and high-contrast slate
  // text instead of the softer textDark/textSubtle pair above. Additive —
  // textDark/textSubtle/divider stay as-is for the many existing screens
  // that already rely on them; new/rebuilt UI (home screen sections, new
  // Spec-1 widgets) uses these instead.
  static const Color borderSlate = Color(0xFFE2E8F0);
  static const Color headingSlate = Color(0xFF0F172A);
  static const Color bodyCharcoal = Color(0xFF1E293B);
  static const Color captionSlate = Color(0xFF475569);

  static const LinearGradient verifiedPillGradient = LinearGradient(
    colors: [primaryBlue, secondaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primeGradient = LinearGradient(
    colors: [Color(0xFF2C5AA0), Color(0xFF1E3A5F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppRadius {
  AppRadius._();
  static const double pill = 999;
  static const double card = 14;
  static const double chip = 8;

  // Sharp architectural corners for the newer design-system pass — used by
  // rebuilt home-screen sections and new Spec-1 widgets rather than the
  // rounder `card`/`chip` values above, which existing screens keep using.
  static const double sharp = 4;
  static const double sharpLg = 6;
}

