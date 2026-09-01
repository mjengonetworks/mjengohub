// lib/shared/widgets/coming_soon.dart
//
// Shared gating UI for features whose backend route doesn't exist yet
// (gamification, referrals, copyright claims, avatar/cover upload, private
// project filtering — see CLAUDE.md's "Known gaps"). Used instead of firing
// a request that's guaranteed to 404, so the UI degrades honestly rather
// than silently failing.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Small pill tag marking a feature as not live yet.
class ComingSoonBadge extends StatelessWidget {
  const ComingSoonBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.textSubtle.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        'COMING SOON',
        style: GoogleFonts.montserrat(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: AppColors.textSubtle,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Full-body placeholder for a screen whose backend route isn't implemented
/// yet, so it isn't worth wiring up a network call that would just 404.
class ComingSoonPlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const ComingSoonPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.textSubtle),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: AppColors.textSubtle,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick snackbar for a tap target (upload, claim button, …) whose backend
/// route isn't implemented yet — shown instead of firing the doomed request.
void showComingSoonSnack(String message) {
  Get.snackbar(
    'Coming soon',
    message,
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(16),
    borderRadius: 10,
    duration: const Duration(seconds: 3),
  );
}
