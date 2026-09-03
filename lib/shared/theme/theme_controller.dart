// lib/shared/theme/theme_controller.dart
//
// Light/Dark mode toggle, relocated from any header/nav control into
// Profile Settings per the website's own appearance switch
// (profile_settings.html's "Dark Mode" toggle, backed by the 'mh-theme'
// localStorage key). Persists the same binary choice via shared_preferences
// so it survives app restarts.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static const String _prefsKey = 'mjengo_dark_mode';

  final RxBool _isDarkMode = false.obs;

  bool get isDarkMode => _isDarkMode.value;
  ThemeMode get themeMode => _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    super.onInit();
    _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode.value = prefs.getBool(_prefsKey) ?? false;
    } catch (_) {}
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (_) {}
  }

  Future<void> toggle() => setDarkMode(!_isDarkMode.value);
}
