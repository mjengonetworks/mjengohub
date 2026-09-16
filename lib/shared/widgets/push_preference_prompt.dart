// lib/shared/widgets/push_preference_prompt.dart
//
// One-time follow-up shown right after the OS notification-permission
// dialog is granted: "Notifications enabled! Customize which updates you'd
// like to receive." Shown at most once per app install (tracked in
// shared_preferences) so it doesn't nag on every cold start.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/controllers/mjengo_auth_controller.dart';
import '../../point/routes/app_routes.dart';
import '../../profile/screens/notification_settings_screen.dart';
import '../theme/app_theme.dart';

class PushPreferencePrompt {
  static const _shownKey = 'push_preference_prompt_shown';

  static Future<void> maybeShowAfterGrant() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_shownKey) == true) return;
    await prefs.setBool(_shownKey, true);

    final context = Get.context;
    if (context == null) return;
    // Give the app a moment to settle onto its first real screen before
    // popping a sheet over it.
    await Future.delayed(const Duration(seconds: 2));
    if (Get.context == null) return;
    showModalBottomSheet<void>(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (_) => const _PushPreferenceSheet(),
    );
  }
}

class _PushPreferenceSheet extends StatelessWidget {
  const _PushPreferenceSheet();

  void _manage(BuildContext context) {
    Navigator.pop(context);
    final auth = Get.find<MjengoAuthController>();
    if (!auth.isAuthenticated) {
      Get.toNamed(AppRoutes.login);
      return;
    }
    Get.to(() => const NotificationSettingsScreen());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sharpLg),
          border: Border.all(color: AppColors.borderSlate),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.accentBlue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Notifications enabled!',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.headingSlate,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Customize which updates you'd like to receive.",
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: AppColors.textSubtle,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderSlate),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sharp),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Dismiss',
                      style: GoogleFonts.montserrat(
                        color: AppColors.headingSlate,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sharp),
                      ),
                    ),
                    onPressed: () => _manage(context),
                    child: Text(
                      'Manage Preferences',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
