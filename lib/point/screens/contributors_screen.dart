// lib/point/screens/contributors_screen.dart
//
// Dedicated leaderboards screen: timeframe tabs (7d/30d/all-time), Points/
// Projects metric toggle, Profiles/Pages sub-toggle. Backed by
// `GET /contributors`. Pages always renders its real empty state — the
// schema has no points/submission mechanism for Page entities yet.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../news/widgets/net_image.dart';
import '../../profile/screens/public_profile_screen.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/coming_soon.dart';
import '../../shared/widgets/responsive.dart';
import '../../shared/widgets/scroll_to_top_fab.dart';
import '../models/contributors_model.dart';
import '../services/contributors_service.dart';

class ContributorsScreen extends StatefulWidget {
  const ContributorsScreen({super.key});

  @override
  State<ContributorsScreen> createState() => _ContributorsScreenState();
}

class _ContributorsScreenState extends State<ContributorsScreen> with SingleTickerProviderStateMixin {
  final _service = ContributorsService();
  final _scrollController = ScrollController();
  late final TabController _windowTab;

  LeaderboardWindow _window = LeaderboardWindow.past7Days;
  bool _showProjects = false;
  bool _showPages = false;

  Future<CommunityLeaderboards>? _future;

  static const _windows = LeaderboardWindow.values;

  @override
  void initState() {
    super.initState();
    _windowTab = TabController(length: _windows.length, vsync: this);
    _windowTab.addListener(() {
      if (_windowTab.indexIsChanging) return;
      setState(() {
        _window = _windows[_windowTab.index];
        _future = _service.getContributors(window: _window, limit: 25);
      });
    });
    _future = _service.getContributors(window: _window, limit: 25);
  }

  @override
  void dispose() {
    _windowTab.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        title: Text('Top Contributors', style: GoogleFonts.montserrat(fontWeight: FontWeight.w500, fontSize: 16, color: AppColors.textDark)),
        bottom: TabBar(
          controller: _windowTab,
          labelColor: AppColors.accentBlue,
          unselectedLabelColor: AppColors.textSubtle,
          indicatorColor: AppColors.accentBlue,
          labelStyle: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w500),
          tabs: _windows.map((w) => Tab(text: w.label)).toList(),
        ),
      ),
      body: ScrollToTopFab(
        controller: _scrollController,
        child: ContentWidth(
        maxWidth: 700,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SegmentedToggle(
                    left: 'Top Points',
                    right: 'Top Projects',
                    isRight: _showProjects,
                    onChanged: (v) => setState(() => _showProjects = v),
                  ),
                  _SegmentedToggle(
                    left: 'Profiles',
                    right: 'Pages',
                    isRight: _showPages,
                    onChanged: (v) => setState(() => _showPages = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<CommunityLeaderboards>(
                future: _future,
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final metric = _showProjects ? snap.data!.projects : snap.data!.points;
                  final rows = _showPages ? metric.pages : metric.profiles;
                  if (rows.isEmpty) {
                    return ComingSoonPlaceholder(
                      icon: _showPages ? Icons.apartment_rounded : Icons.emoji_events_outlined,
                      title: _showPages ? 'No Pages yet' : 'No contributors yet',
                      message: _showPages
                          ? 'Pages (companies/organizations) don\'t yet earn points or submit content — this tab will populate once that ships.'
                          : 'Be the first to earn points or submit a project this period.',
                    );
                  }
                  return ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (_, i) => _RankedRow(rank: i + 1, row: rows[i], isProjects: _showProjects),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _SegmentedToggle extends StatelessWidget {
  final String left;
  final String right;
  final bool isRight;
  final ValueChanged<bool> onChanged;
  const _SegmentedToggle({required this.left, required this.right, required this.isRight, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget pill(String label, bool active, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: active ? AppColors.accentBlue : Colors.transparent, borderRadius: BorderRadius.circular(999)),
            child: Text(label,
                style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w500, color: active ? Colors.white : AppColors.textSubtle)),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.divider)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [pill(left, !isRight, () => onChanged(false)), pill(right, isRight, () => onChanged(true))]),
    );
  }
}

class _RankedRow extends StatelessWidget {
  final int rank;
  final LeaderboardRow row;
  final bool isProjects;
  const _RankedRow({required this.rank, required this.row, required this.isProjects});

  static const _medalColors = {1: Color(0xFFFBBF24), 2: Color(0xFFB0B7C3), 3: Color(0xFFCD7F32)};

  @override
  Widget build(BuildContext context) {
    final medal = _medalColors[rank];
    return ListTile(
      onTap: () => Get.to(() => PublicProfileScreen(userId: row.id)),
      contentPadding: EdgeInsets.zero,
      leading: SizedBox(
        width: 56,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              child: medal != null
                  ? Icon(Icons.emoji_events_rounded, color: medal, size: 20)
                  : Text('$rank', style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSubtle)),
            ),
            ClipOval(
              child: SizedBox(width: 36, height: 36, child: NetImage(url: row.avatar, fit: BoxFit.cover, placeholderColor: const Color(0xFF1E3A5F))),
            ),
          ],
        ),
      ),
      title: Text(row.name, style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.textDark)),
      trailing: Text('${row.value} ${isProjects ? "projects" : "pts"}',
          style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.accentBlue)),
    );
  }
}
