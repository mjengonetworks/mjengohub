// lib/profile/screens/points_screen.dart
//
// Points breakdown dashboard — total + level card from the cached UserModel
// (instant, no network wait), per-source breakdown and activity log fetched
// live from `GET points/summary` / `GET points/log` (GamificationService).
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
  final _api = GamificationService();

  PointsSummary? _summary;
  List<PointsLogEntry> _log = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([_api.getPointsSummary(), _api.getPointsLog()]);
    if (!mounted) return;
    setState(() {
      _summary = results[0] as PointsSummary?;
      _log = results[1] as List<PointsLogEntry>;
      _loading = false;
    });
  }

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
        title: Text('Your Points', style: GoogleFonts.montserrat(color: AppColors.textDark, fontWeight: FontWeight.w500)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                        Text('$points', style: GoogleFonts.montserrat(fontSize: 34, fontWeight: FontWeight.w500, color: AppColors.textDark)),
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
              Text('Breakdown', style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textDark)),
              const SizedBox(height: 10),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(color: AppColors.accentBlue)),
                )
              else if (_summary == null)
                Text(
                  'Could not load your points breakdown right now.',
                  style: GoogleFonts.montserrat(fontSize: 12.5, color: AppColors.textSubtle),
                )
              else ...[
                _BreakdownGrid(summary: _summary!),
                const SizedBox(height: 24),
                Text('Recent Activity', style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                const SizedBox(height: 10),
                if (_log.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.sharpLg)),
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 36, color: AppColors.textSubtle),
                        const SizedBox(height: 10),
                        Text('No points activity yet', style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSubtle)),
                      ],
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.sharpLg)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (int i = 0; i < _log.length; i++) ...[
                          _LogRow(entry: _log[i]),
                          if (i < _log.length - 1) const Divider(height: 1, color: AppColors.divider),
                        ],
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreakdownGrid extends StatelessWidget {
  final PointsSummary summary;
  const _BreakdownGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Reviews', summary.fromReviews, Icons.rate_review_rounded),
      ('Upvotes received', summary.fromUpvotes, Icons.thumb_up_rounded),
      ('Referral signups', summary.fromReferralSignups, Icons.person_add_rounded),
      ('Referrals went Prime', summary.fromReferralPrime, Icons.workspace_premium_rounded),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: items.map((item) {
        final (label, value, icon) = item;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: AppColors.accentBlue),
              const Spacer(),
              Text('$value', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textDark)),
              Text(label, style: GoogleFonts.montserrat(fontSize: 10.5, color: AppColors.textSubtle), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LogRow extends StatelessWidget {
  final PointsLogEntry entry;
  const _LogRow({required this.entry});

  IconData get _icon {
    switch (entry.source) {
      case 'review': return Icons.rate_review_rounded;
      case 'upvote': return Icons.thumb_up_rounded;
      case 'referral_signup': return Icons.person_add_rounded;
      case 'referral_prime': return Icons.workspace_premium_rounded;
      default: return Icons.stars_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: AppColors.accentBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(_icon, size: 16, color: AppColors.accentBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.description?.isNotEmpty == true ? entry.description! : entry.sourceLabel,
                    style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                if (entry.createdAt != null)
                  Text(_timeAgo(entry.createdAt!), style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.textSubtle)),
              ],
            ),
          ),
          Text('+${entry.points}', style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.success)),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
