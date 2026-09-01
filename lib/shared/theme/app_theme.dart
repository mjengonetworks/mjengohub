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
}

