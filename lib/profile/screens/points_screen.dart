// lib/profile/screens/points_screen.dart
//
// Points breakdown dashboard. Bound to local-only state: `points/summary`
// and `points/log` don't exist on the backend yet (see
// GamificationService), and the User model has no `points` column either,
// so there's no per-source breakdown or activity log to fetch. Shows the
// local fallback (reviewer level math is pure client-side) plus a "coming
// soon" notice instead of firing requests that are guaranteed to 404.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/controllers/mjengo_auth_controller.dart';
import '../../point/models/points_models.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/coming_soon.dart';

class PointsScreen extends StatelessWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final points = Get.find<MjengoAuthController>().currentUser?.points ?? 0;
    final level = ReviewerLevel.forPoints(points);
    final progress = level.progressToNext(points);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text('Your Points', style: GoogleFonts.montserrat(color: AppColors.textDark, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$points', style: GoogleFonts.montserrat(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                      ReviewerLevelBadge(points: points),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('total reputation points', style: GoogleFonts.montserrat(fontSize: 12.5, color: AppColors.textSubtle)),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppColors.divider,
                      valueColor: const AlwaysStoppedAnimation(AppColors.accentBlue),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    level.pointsToNext != null
                        ? '${level.pointsToNext! - points} points to the next level'
                        : 'You\'ve reached the highest level — Legend!',
                    style: GoogleFonts.montserrat(fontSize: 11.5, color: AppColors.textSubtle),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Breakdown & Activity', style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(width: 8),
                const ComingSoonBadge(),
              ],
            ),
            const SizedBox(height: 10),
            const ComingSoonPlaceholder(
              icon: Icons.receipt_long_rounded,
              title: 'Points breakdown is coming soon',
              message: 'A per-source breakdown and recent activity log will '
                  'appear here once this is available.',
            ),
          ],
        ),
      ),
    );
  }
}
