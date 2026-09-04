// lib/profile/screens/submissions_screen.dart
//
// "My Submissions" — a tabbed view of the user's own content (articles,
// public/private projects, incidents, comments), reachable from the Profile
// screen. Backed by api.py's `GET /auth/me/{projects,articles,incidents,
// comments}` (added specifically for this screen — the public list endpoints
// don't accept an author/user filter and there was no per-user comments
// endpoint at all until now).
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../comments/services/comments_service.dart';
import '../../incidents/models/incident_model.dart';
import '../../incidents/services/incidents_service.dart';
import '../../news/models/article_model.dart';
import '../../news/services/news_api_service.dart';
import '../../news/widgets/net_image.dart';
import '../../point/routes/app_routes.dart';
import '../../projects/models/project_model.dart';
import '../../projects/screens/project_detail_screen.dart';
import '../../projects/services/projects_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/coming_soon.dart';
import '../../shared/widgets/responsive.dart';

class SubmissionsScreen extends StatefulWidget {
  /// Index into [_SubmissionsScreenState._tabLabels] to open directly on —
  /// lets Profile screen's preview cards' "View All" jump straight to the
  /// relevant tab instead of always landing on Articles.
  final int initialTab;
  const SubmissionsScreen({super.key, this.initialTab = 0});

  @override
  State<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabLabels = ['Articles', 'Public Projects', 'Private Projects', 'Incidents', 'Comments'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabLabels.length,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, _tabLabels.length - 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        title: Text(
          'My Submissions',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textDark),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.accentBlue,
          unselectedLabelColor: AppColors.textSubtle,
          indicatorColor: AppColors.accentBlue,
          labelStyle: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: _tabLabels.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: ContentWidth(
        maxWidth: 700,
        child: TabBarView(
          controller: _tabController,
          children: const [
            _MyArticlesTab(),
            _MyProjectsTab(projectType: 'infrastructure'),
            _MyProjectsTab(projectType: 'private_development'),
            _MyIncidentsTab(),
            _MyCommentsTab(),
          ],
        ),
      ),
    );
  }
}

// ── Shared list chrome ────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return ComingSoonPlaceholder(icon: icon, title: 'Nothing here yet', message: message);
  }
}

class _MiniTile extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MiniTile({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 56,
                height: 56,
                child: NetImage(url: imageUrl, fit: BoxFit.cover, placeholderColor: const Color(0xFF1E3A5F)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(fontSize: 11.5, color: AppColors.textSubtle),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

Widget _statusPill(String label, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: GoogleFonts.montserrat(fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
    );

// ── Articles ───────────────────────────────────────────────────────────────

class _MyArticlesTab extends StatefulWidget {
  const _MyArticlesTab();
  @override
  State<_MyArticlesTab> createState() => _MyArticlesTabState();
}

class _MyArticlesTabState extends State<_MyArticlesTab> {
  final _service = NewsApiService();
  late final Future<List<Article>> _future = _service.getMyArticles();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Article>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final items = snap.data!;
        if (items.isEmpty) {
          return const _EmptyState(icon: Icons.article_outlined, message: 'Articles you\'ve authored will show up here.');
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
          itemBuilder: (_, i) {
            final a = items[i];
            return _MiniTile(
              imageUrl: a.imageUrl,
              title: a.title,
              subtitle: a.timeAgo,
              onTap: () => Get.toNamed(AppRoutes.articleDetail, arguments: a.slug),
            );
          },
        );
      },
    );
  }
}

// ── Projects (Public / Private) ──────────────────────────────────────────

class _MyProjectsTab extends StatefulWidget {
  final String projectType;
  const _MyProjectsTab({required this.projectType});
  @override
  State<_MyProjectsTab> createState() => _MyProjectsTabState();
}

class _MyProjectsTabState extends State<_MyProjectsTab> {
  final _service = ProjectsService();
  late final Future<List<Project>> _future = _service.getMyProjects();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Project>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final items = snap.data!.where((p) => p.projectType == widget.projectType).toList();
        if (items.isEmpty) {
          return const _EmptyState(
            icon: Icons.corporate_fare_rounded,
            message: 'Projects you\'ve submitted will show up here once you add one.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
          itemBuilder: (_, i) {
            final p = items[i];
            return _MiniTile(
              imageUrl: p.imageUrl,
              title: p.title,
              subtitle: p.county ?? p.location ?? p.statusLabel,
              trailing: _statusPill(
                p.status == 'planned' ? 'PENDING REVIEW' : p.statusLabel.toUpperCase(),
                AppColors.warning,
              ),
              onTap: () => Get.to(() => ProjectDetailScreen(slug: p.slug), transition: Transition.cupertino),
            );
          },
        );
      },
    );
  }
}

// ── Incidents ─────────────────────────────────────────────────────────────

class _MyIncidentsTab extends StatefulWidget {
  const _MyIncidentsTab();
  @override
  State<_MyIncidentsTab> createState() => _MyIncidentsTabState();
}

class _MyIncidentsTabState extends State<_MyIncidentsTab> {
  final _service = IncidentsService();
  late final Future<List<Incident>> _future = _service.getMyIncidents();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Incident>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final items = snap.data!;
        if (items.isEmpty) {
          return const _EmptyState(
            icon: Icons.report_gmailerrorred_rounded,
            message: 'Road safety and site safety incidents you\'ve reported will show up here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
          itemBuilder: (_, i) {
            final inc = items[i];
            return _MiniTile(
              imageUrl: inc.imageUrl,
              title: inc.title,
              subtitle: inc.location ?? inc.severity,
              onTap: () => Get.toNamed(AppRoutes.incidentDetail, arguments: inc.slug),
            );
          },
        );
      },
    );
  }
}

// ── Comments ──────────────────────────────────────────────────────────────

class _MyCommentsTab extends StatefulWidget {
  const _MyCommentsTab();
  @override
  State<_MyCommentsTab> createState() => _MyCommentsTabState();
}

class _MyCommentsTabState extends State<_MyCommentsTab> {
  final _service = CommentsService();
  late final Future<List<MyComment>> _future = _service.getMyComments();

  static const _typeLabels = {
    'project': 'Project',
    'article': 'Article',
    'incident': 'Incident',
    'mental_health_post': 'Mshikamano',
  };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MyComment>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final items = snap.data!;
        if (items.isEmpty) {
          return const _EmptyState(icon: Icons.mode_comment_outlined, message: 'Your comments and discussions will show up here.');
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
          itemBuilder: (_, i) {
            final c = items[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _statusPill(_typeLabels[c.commentableType] ?? c.commentableType, AppColors.accentBlue),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_upward_rounded, size: 12, color: AppColors.success),
                      Text('${c.upvotes}', style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.textSubtle)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(fontSize: 12.5, color: AppColors.textDark, height: 1.4),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
