// lib/shared/widgets/guest_gate_sheet.dart
//
// Single shared guest gate for any action that requires a signed-in user
// (posting a comment, suggesting a project edit/update, ...). Replaces the
// handful of ad hoc AlertDialogs previously duplicated per-screen
// (comments_section.dart, project_detail_screen.dart) with one bottom sheet.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/controllers/mjengo_auth_controller.dart';
import '../../point/routes/app_routes.dart';
import '../theme/app_theme.dart';

/// Runs [action] immediately if the user is signed in; otherwise shows a
/// bottom sheet with [message] and Sign In / Register actions and does not
/// run [action] (the caller retries after the user signs in, same as the
/// dialogs this replaces).
void requireAuth(
  BuildContext context,
  VoidCallback action, {
  String message = 'Sign in to continue',
}) {
  MjengoAuthController? auth;
  try {
    auth = Get.find<MjengoAuthController>();
  } catch (_) {
    auth = null;
  }

  if (auth?.isAuthenticated ?? false) {
    action();
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _GuestGateSheet(message: message),
  );
}

class _GuestGateSheet extends StatelessWidget {
  final String message;
  const _GuestGateSheet({required this.message});

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
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.borderSlate,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            Text(
              message,
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.headingSlate,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.headingSlate,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sharp),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Get.toNamed(AppRoutes.login);
                },
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
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.borderSlate),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sharp),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Get.toNamed(AppRoutes.signup);
                },
                child: Text(
                  'Register',
                  style: GoogleFonts.montserrat(
                    color: AppColors.headingSlate,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
