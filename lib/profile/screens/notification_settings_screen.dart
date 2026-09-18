// lib/profile/screens/notification_settings_screen.dart
//
// Dedicated "Notification Settings" destination inside Profile — separate
// from the contextual preference panel embedded in the notifications inbox
// (NotificationsScreen), but backed by the same NotificationsService/
// NotificationPreferences so both surfaces stay in sync.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/controllers/mjengo_auth_controller.dart';
import '../../notifications/models/notification_preferences.dart';
import '../../notifications/services/notifications_service.dart';
import '../../point/routes/app_routes.dart';
import '../../shared/theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _svc = NotificationsService();
  NotificationPreferences? _preferences;
  bool _loading = true;
  bool _saving = false;

  bool get _isAuthenticated => Get.find<MjengoAuthController>().isAuthenticated;

  @override
  void initState() {
    super.initState();
    if (_isAuthenticated) {
      _svc.getPreferences().then((p) {
        if (mounted)
          setState(() {
            _preferences = p;
            _loading = false;
          });
      });
    } else {
      _loading = false;
    }
  }

  Future<void> _update(NotificationPreferences next) async {
    setState(() {
      _preferences = next;
      _saving = true;
    });
    await _svc.updatePreferences(next);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        title: Text(
          'Notification Settings',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_isAuthenticated
          ? _SignInPrompt()
          : _buildToggles(_preferences ?? const NotificationPreferences()),
    );
  }

  Widget _buildToggles(NotificationPreferences prefs) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        if (_saving)
          const LinearProgressIndicator(
            minHeight: 2,
            color: AppColors.accentBlue,
          ),
        SwitchListTile(
          title: Text(
            'Breaking News & Major Projects',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
          subtitle: Text(
            'Major infrastructure milestones and breaking news alerts',
            style: GoogleFonts.montserrat(
              fontSize: 11.5,
              color: AppColors.textSubtle,
            ),
          ),
          value: prefs.breakingNewsMajorProjects,
          activeThumbColor: AppColors.accentBlue,
          onChanged: (v) =>
              _update(prefs.copyWith(breakingNewsMajorProjects: v)),
        ),
        SwitchListTile(
          title: Text(
            'Documented Progress Updates',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
          subtitle: Text(
            'New updates posted to projects you follow',
            style: GoogleFonts.montserrat(
              fontSize: 11.5,
              color: AppColors.textSubtle,
            ),
          ),
          value: prefs.documentedProgressUpdates,
          activeThumbColor: AppColors.accentBlue,
          onChanged: (v) =>
              _update(prefs.copyWith(documentedProgressUpdates: v)),
        ),
        SwitchListTile(
          title: Text(
            'Site Safety Alerts',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
          subtitle: Text(
            'Road safety and site safety incident reports',
            style: GoogleFonts.montserrat(
              fontSize: 11.5,
              color: AppColors.textSubtle,
            ),
          ),
          value: prefs.siteSafetyAlerts,
          activeThumbColor: AppColors.accentBlue,
          onChanged: (v) => _update(prefs.copyWith(siteSafetyAlerts: v)),
        ),
        const Divider(height: 24),
        SwitchListTile(
          title: Text(
            'All push notifications',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
          subtitle: Text(
            'Turn off to silence all push notifications regardless of category',
            style: GoogleFonts.montserrat(
              fontSize: 11.5,
              color: AppColors.textSubtle,
            ),
          ),
          value: prefs.pushEnabled,
          activeThumbColor: AppColors.accentBlue,
          onChanged: (v) => _update(prefs.copyWith(pushEnabled: v)),
        ),
      ],
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.sharpLg),
            border: Border.all(color: AppColors.borderSlate),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.notifications_outlined,
                size: 40,
                color: AppColors.textSubtle,
              ),
              const SizedBox(height: 14),
              Text(
                'Sign in to customize notifications',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.headingSlate,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose which updates you want to be notified about.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 12.5,
                  color: AppColors.textSubtle,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.headingSlate,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sharp),
                    ),
                  ),
                  onPressed: () => Get.toNamed(AppRoutes.login),
                  child: Text(
                    'Sign In',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
