// lib/shared/widgets/leaderboard_widget.dart
//
// Two reusable leaderboard widgets backed by `GET /contributors`
// (ContributorsService): `LeaderboardPreview` (a fuller card — Points/
// Projects toggle, top 5, "View More" button; used on Media Hub and Merch)
// and `MicroLeaderboardStrip` (a 1-row/2-column compact ticker; used on the
// Profile screen and the homepage). Both link out to ContributorsScreen and
// tap through to PublicProfileScreen per row.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../point/models/contributors_model.dart';
import '../../point/routes/app_routes.dart';
import '../../point/services/contributors_service.dart';
import '../../news/widgets/net_image.dart';
import '../../profile/screens/public_profile_screen.dart';
import '../theme/app_theme.dart';

void _openProfile(int userId) => Get.to(() => PublicProfileScreen(userId: userId));

// ── Fuller card (Media Hub / Merch) ──────────────────────────────────────

class LeaderboardPreview extends StatefulWidget {
  final LeaderboardWindow window;
  const LeaderboardPreview({super.key, this.window = LeaderboardWindow.past7Days});

  @override
  State<LeaderboardPreview> createState() => _LeaderboardPreviewState();
}

class _LeaderboardPreviewState extends State<LeaderboardPreview> {
  final _service = ContributorsService();
  late Future<CommunityLeaderboards> _future = _service.getContributors(window: widget.window, limit: 5);
  bool _showProjects = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CommunityLeaderboards>(
      future: _future,
      builder: (context, snap) {
        final boards = snap.data;
        final rows = boards == null ? const <LeaderboardRow>[] : (_showProjects ? boards.projects.profiles : boards.points.profiles);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.accentBlue.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${widget.window.label} Top Contributors',
                      style: GoogleFonts.montserrat(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  _MetricToggle(showProjects: _showProjects, onChanged: (v) => setState(() => _showProjects = v)),
                ],
              ),
              const SizedBox(height: 12),
              if (snap.connectionState != ConnectionState.done)
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
              else if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('No contributors yet this period.', style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textSubtle)),
                )
              else
                ...rows.take(5).toList().asMap().entries.map((e) => _LeaderboardRowTile(rank: e.key + 1, row: e.value)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.contributors),
                child: Center(
                  child: Text('View More',
                      style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.accentBlue)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricToggle extends StatelessWidget {
  final bool showProjects;
  final ValueChanged<bool> onChanged;
  const _MetricToggle({required this.showProjects, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget pill(String label, bool active, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: active ? AppColors.accentBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 10.5, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.textSubtle)),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          pill('Points', !showProjects, () => onChanged(false)),
          pill('Projects', showProjects, () => onChanged(true)),
        ],
      ),
    );
  }
}

class _LeaderboardRowTile extends StatelessWidget {
  final int rank;
  final LeaderboardRow row;
  const _LeaderboardRowTile({required this.rank, required this.row});

  static const _medalColors = {1: Color(0xFFFBBF24), 2: Color(0xFFB0B7C3), 3: Color(0xFFCD7F32)};

  @override
  Widget build(BuildContext context) {
    final medal = _medalColors[rank];
    return InkWell(
      onTap: () => _openProfile(row.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: medal != null
                  ? Icon(Icons.emoji_events_rounded, color: medal, size: 18)
                  : Text('$rank', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSubtle)),
            ),
            ClipOval(
              child: SizedBox(
                width: 28,
                height: 28,
                child: NetImage(url: row.avatar, fit: BoxFit.cover, placeholderColor: const Color(0xFF1E3A5F)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(row.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            ),
            Text('${row.value}', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accentBlue)),
          ],
        ),
      ),
    );
  }
}

// ── Micro strip (Profile screen bottom / Homepage) ──────────────────────

/// 1-row/2-column ticker: top point gainer + top project contributor for
/// the week, side by side — occupies minimal vertical space by design.
class MicroLeaderboardStrip extends StatefulWidget {
  const MicroLeaderboardStrip({super.key});

  @override
  State<MicroLeaderboardStrip> createState() => _MicroLeaderboardStripState();
}

class _MicroLeaderboardStripState extends State<MicroLeaderboardStrip> {
  final _service = ContributorsService();
  late final Future<CommunityLeaderboards> _future =
      _service.getContributors(window: LeaderboardWindow.past7Days, limit: 1);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CommunityLeaderboards>(
      future: _future,
      builder: (context, snap) {
        final boards = snap.data;
        final topPoints = boards?.points.profiles.isNotEmpty == true ? boards!.points.profiles.first : null;
        final topProject = boards?.projects.profiles.isNotEmpty == true ? boards!.projects.profiles.first : null;
        if (topPoints == null && topProject == null) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.contributors),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: Color(0xFFFBBF24), size: 16),
                const SizedBox(width: 8),
                Expanded(child: _MicroEntry(label: 'Top Points', row: topPoints)),
                Container(width: 1, height: 22, color: AppColors.divider, margin: const EdgeInsets.symmetric(horizontal: 10)),
                Expanded(child: _MicroEntry(label: 'Top Contributor', row: topProject)),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFBBBBBB), size: 18),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MicroEntry extends StatelessWidget {
  final String label;
  final LeaderboardRow? row;
  const _MicroEntry({required this.label, required this.row});

  @override
  Widget build(BuildContext context) {
    if (row == null) {
      return Text('—', style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.textSubtle));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.montserrat(fontSize: 9, color: AppColors.textSubtle)),
        Text(row!.name, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      ],
    );
  }
}
