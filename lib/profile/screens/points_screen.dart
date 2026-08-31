// lib/profile/screens/points_screen.dart
//
// Points breakdown dashboard: reviewer level, progress to next tier, and a
// per-source summary card (net upvotes, referrals, reviews) matching the
// website's /profile `points_by_source` view.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/controllers/mjengo_auth_controller.dart';
import '../../point/models/points_models.dart';
import '../../point/services/gamification_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/badges.dart';

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> {
  final _service = GamificationService();
  PointsSummary? _summary;
  List<PointsLogEntry> _log = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = Get.find<MjengoAuthController>();
    final fetchedSummary = await _service.getPointsSummary();
    final fetchedLog = await _service.getPointsLog();
    if (!mounted) return;
    setState(() {
      _summary = fetchedSummary ?? PointsSummary(totalPoints: auth.currentUser?.points ?? 0);
      _log = fetchedLog;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final points = _summary?.totalPoints ?? 0;
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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentBlue))
          : SingleChildScrollView(
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
                  Text('Breakdown', style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(height: 10),
                  _BreakdownRow(icon: Icons.rate_review_rounded, label: 'Project reviews', value: _summary?.fromReviews ?? 0),
                  _BreakdownRow(icon: Icons.thumb_up_rounded, label: 'Net upvotes received', value: _summary?.fromUpvotes ?? 0),
                  _BreakdownRow(icon: Icons.person_add_rounded, label: 'Referral signups', value: _summary?.fromReferralSignups ?? 0),
                  _BreakdownRow(icon: Icons.workspace_premium_rounded, label: 'Referrals who went Prime', value: _summary?.fromReferralPrime ?? 0),
                  if (_log.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Recent Activity', style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    const SizedBox(height: 10),
                    ..._log.take(20).map((e) => _LogRow(entry: e)),
                  ],
                ],
              ),
            ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  const _BreakdownRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: AppColors.accentBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 17, color: AppColors.accentBlue),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textDark))),
          Text('+$value', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.success)),
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  final PointsLogEntry entry;
  const _LogRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final positive = entry.points >= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(entry.description?.isNotEmpty == true ? entry.description! : entry.sourceLabel,
                style: GoogleFonts.montserrat(fontSize: 12.5, color: AppColors.textDark)),
          ),
          Text(
            '${positive ? '+' : ''}${entry.points}',
            style: GoogleFonts.montserrat(
                fontSize: 12.5, fontWeight: FontWeight.w700, color: positive ? AppColors.success : AppColors.danger),
          ),
        ],
      ),
    );
  }
}
