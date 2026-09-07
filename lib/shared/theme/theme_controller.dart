// lib/shared/theme/theme_controller.dart
//
// Appearance preference, relocated from any header/nav control into Profile
// Settings per the website's own appearance switch (profile_settings.html's
// "Dark Mode" toggle, backed by the 'mh-theme' localStorage key). Persists
// via shared_preferences so it survives app restarts.
//
// Was a plain bool (Dark on/off). Upgraded to a 3-way System Default/Light/
// Dark preference, matching the website's actual choice set — a binary
// toggle can't express "follow the OS", which `ThemeMode.system` already
// supports natively in Flutter.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreference { system, light, dark }

class ThemeController extends GetxController {
  static const String _prefsKey = 'mjengo_theme_preference';
  // Previous binary key — read once for migration so an existing user's
  // choice carries over instead of silently resetting to System Default.
  static const String _legacyBoolKey = 'mjengo_dark_mode';

  final Rx<AppThemePreference> _preference = AppThemePreference.system.obs;

  AppThemePreference get preference => _preference.value;
  bool get isDarkMode => _preference.value == AppThemePreference.dark;

  ThemeMode get themeMode {
    switch (_preference.value) {
      case AppThemePreference.system: return ThemeMode.system;
      case AppThemePreference.light: return ThemeMode.light;
      case AppThemePreference.dark: return ThemeMode.dark;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null) {
        _preference.value = AppThemePreference.values.firstWhere(
          (p) => p.name == saved,
          orElse: () => AppThemePreference.system,
        );
        return;
      }
      // Migrate the old binary preference if it's the only thing set.
      final legacyDark = prefs.getBool(_legacyBoolKey);
      if (legacyDark != null) {
        _preference.value = legacyDark ? AppThemePreference.dark : AppThemePreference.light;
      }
    } catch (_) {}
  }

  Future<void> setPreference(AppThemePreference value) async {
    _preference.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, value.name);
    } catch (_) {}
  }

  /// Kept for any pre-existing binary call sites — maps to Dark/Light only,
  /// never sets System Default.
  Future<void> setDarkMode(bool value) =>
      setPreference(value ? AppThemePreference.dark : AppThemePreference.light);
}
