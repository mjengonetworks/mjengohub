// lib/shared/theme/app_theme.dart
//
// Central design tokens for the native Mjengo Hub product experience.
import 'package:flutter/material.dart';

class AppColors {
  // Compatibility aliases
  static const Color primary = Color(0xFF0F2E4D);
  static const Color accent = Color(0xFF0284C7);
  // Was 0xFF8888AA (a washed-out lavender-gray) -- raised to slate-600 for
  // legible secondary/caption text app-wide. Same value as captionSlate
  // below; kept as a separate token since callers already reference both
  // textLight/textSubtle and captionSlate by name.
  static const Color textLight = Color(0xFF475569);

  AppColors._();

  // Brand blue — matches --primary-blue / --secondary-blue in main.css
  static const Color primaryBlue = Color(0xFF0F2E4D);
  static const Color secondaryBlue = Color(0xFF0A2540);
  static const Color darkBlue = Color(0xFF0A2540);
  static const Color deepNavy = Color(0xFF0A2540);

  // App accent (existing in-app blue, kept for continuity with current screens)
  static const Color accentBlue = Color(0xFF0284C7);

  static const Color surface = Colors.white;
  static const Color background = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  // Was 0xFF8888AA -- see textLight's comment above, same fix.
  static const Color textSubtle = Color(0xFF475569);
  static const Color divider = Color(0xFFE2E8F0);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color roadAmber = Color(0xFFD97706);
  static const Color canvas = Color(0xFFF8FAFC);
  static const Color mutedCanvas = Color(0xFFF1F5F9);

  // Very light ice-blue tint for the persistent top app bar — avoids a flat
  // white bar while staying subtle enough not to compete with content.
  static const Color headerTint = Color(0xFFF0F7FF);

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
  static const Color captionSlate = Color(0xFF64748B);

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

/// Dark-mode palette, based on the website's own footer slate treatment
/// (deep navy slate base, `#1E293B` elevated cards, `#334155` borders) — not
/// pure black, so typography/icons/badges/card boundaries stay legible.
///
/// This is infrastructure, not a completed app-wide dark mode: `ThemeData`
/// (`main.dart`'s `darkTheme`) is wired to these tokens so default Material
/// widgets (dialogs, switches, the base scaffold/card colors) respond
/// correctly to [ThemeController]'s Dark setting, but the large majority of
/// screens in this codebase hardcode `AppColors.*`/`Colors.white` rather
/// than reading `Theme.of(context)`, so most screens will not visually
/// change yet — converting every screen to theme-aware colors is a much
/// larger follow-up, out of scope here.
class AppColorsDark {
  AppColorsDark._();

  static const Color background = Color(0xFF0B1120);
  static const Color surface = Color(0xFF0F172A);
  static const Color card = Color(0xFF1E293B);
  static const Color border = Color(0xFF334155);
  static const Color headingText = Color(0xFFF8FAFC);
  static const Color bodyText = Color(0xFFF8FAFC);
  static const Color secondaryText = Color(0xFF94A3B8);
}

class AppRadius {
  AppRadius._();
  static const double pill = 999;
  static const double card = 16;
  static const double chip = 10;

  // Sharp architectural corners for the newer design-system pass — used by
  // rebuilt home-screen sections and new Spec-1 widgets rather than the
  // rounder `card`/`chip` values above, which existing screens keep using.
  static const double sharp = 4;
  static const double sharpLg = 6;
}
