// lib/profile/widgets/profile_content_previews.dart
//
// Compact preview cards for the Profile screen's content hierarchy: ecosystem
// links, my project submissions (count), my followed projects, my articles,
// my comments, and site safety submissions — each a max-5 preview + "View
// All" into the fuller list. Backed by the `GET /auth/me/*` routes added
// specifically for this screen.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/models/user_model.dart';
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
import '../screens/followed_projects_screen.dart';
import '../screens/submissions_screen.dart';

Future<void> _launchExternal(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
}

// ── Section chrome shared by every preview card below ───────────────────────

class _PreviewSection extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;
  final Widget child;
  const _PreviewSection({required this.title, this.onViewAll, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              if (onViewAll != null)
                GestureDetector(
                  onTap: onViewAll,
                  child: Text('View All',
                      style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.accentBlue)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _RowTile({required this.imageUrl, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 44,
                height: 44,
                child: NetImage(url: imageUrl, fit: BoxFit.cover, placeholderColor: const Color(0xFF1E3A5F)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.textSubtle)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _emptyLine(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textSubtle)),
    );

// ── Ecosystem links ──────────────────────────────────────────────────────

class EcosystemLinksRow extends StatelessWidget {
  final UserModel? user;
  const EcosystemLinksRow({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final mjengoUrl = user?.mjengoNetworksUrl;
    final barabaraUrl = user?.shareBarabaraUrl;
    if ((mjengoUrl == null || mjengoUrl.isEmpty) && (barabaraUrl == null || barabaraUrl.isEmpty)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          if (mjengoUrl != null && mjengoUrl.isNotEmpty)
            _EcosystemChip(label: 'Mjengo Networks', icon: Icons.hub_rounded, onTap: () => _launchExternal(mjengoUrl)),
          if (barabaraUrl != null && barabaraUrl.isNotEmpty)
            _EcosystemChip(
                label: 'Share Barabara', icon: Icons.directions_car_filled_rounded, onTap: () => _launchExternal(barabaraUrl)),
        ],
      ),
    );
  }
}

class _EcosystemChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _EcosystemChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accentBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.accentBlue),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.accentBlue)),
          ],
        ),
      ),
    );
  }
}

// ── My Project Submissions (count row) ──────────────────────────────────

class MyProjectSubmissionsRow extends StatefulWidget {
  const MyProjectSubmissionsRow({super.key});
  @override
  State<MyProjectSubmissionsRow> createState() => _MyProjectSubmissionsRowState();
}

class _MyProjectSubmissionsRowState extends State<MyProjectSubmissionsRow> {
  final _service = ProjectsService();
  late final Future<List<Project>> _future = _service.getMyProjects(perPage: 50);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Project>>(
      future: _future,
      builder: (context, snap) {
        final count = snap.data?.length;
        return InkWell(
          onTap: () => Get.to(() => const SubmissionsScreen(initialTab: 1)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: AppColors.accentBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.corporate_fare_rounded, size: 20, color: AppColors.accentBlue),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text('My Project Submissions',
                      style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                ),
                Text(count == null ? '…' : '$count',
                    style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSubtle)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFBBBBBB), size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── My Followed Projects ─────────────────────────────────────────────────

class MyFollowedProjectsPreview extends StatefulWidget {
  const MyFollowedProjectsPreview({super.key});
  @override
  State<MyFollowedProjectsPreview> createState() => _MyFollowedProjectsPreviewState();
}

class _MyFollowedProjectsPreviewState extends State<MyFollowedProjectsPreview> {
  final _service = ProjectsService();
  late final Future<List<Project>> _future = _service.getFollowedProjects(perPage: 5);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Project>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final items = snap.data!;
        return _PreviewSection(
          title: 'My Followed Projects',
          onViewAll: items.isEmpty ? null : () => Get.to(() => const FollowedProjectsScreen()),
          child: items.isEmpty
              ? _emptyLine('Tap the bell on any project to follow its updates.')
              : Column(
                  children: items
                      .map((p) => _RowTile(
                            imageUrl: p.imageUrl,
                            title: p.title,
                            subtitle: p.county ?? p.location ?? p.statusLabel,
                            onTap: () => Get.to(() => ProjectDetailScreen(slug: p.slug), transition: Transition.cupertino),
                          ))
                      .toList(),
                ),
        );
      },
    );
  }
}

// ── My Articles ───────────────────────────────────────────────────────────

class MyArticlesPreview extends StatefulWidget {
  const MyArticlesPreview({super.key});
  @override
  State<MyArticlesPreview> createState() => _MyArticlesPreviewState();
}

class _MyArticlesPreviewState extends State<MyArticlesPreview> {
  final _service = NewsApiService();
  late final Future<List<Article>> _future = _service.getMyArticles(perPage: 5);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Article>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final items = snap.data!;
        return _PreviewSection(
          title: 'My Articles',
          onViewAll: items.isEmpty ? null : () => Get.to(() => const SubmissionsScreen(initialTab: 0)),
          child: items.isEmpty
              ? _emptyLine('Articles you\'ve authored will show up here.')
              : Column(
                  children: items
                      .map((a) => _RowTile(
                            imageUrl: a.imageUrl,
                            title: a.title,
                            subtitle: a.timeAgo,
                            onTap: () => Get.toNamed(AppRoutes.articleDetail, arguments: a.slug),
                          ))
                      .toList(),
                ),
        );
      },
    );
  }
}

// ── My Comments ───────────────────────────────────────────────────────────

class MyCommentsPreview extends StatefulWidget {
  const MyCommentsPreview({super.key});
  @override
  State<MyCommentsPreview> createState() => _MyCommentsPreviewState();
}

class _MyCommentsPreviewState extends State<MyCommentsPreview> {
  final _service = CommentsService();
  late final Future<List<MyComment>> _future = _service.getMyComments(perPage: 5);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MyComment>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final items = snap.data!;
        return _PreviewSection(
          title: 'My Comments',
          onViewAll: items.isEmpty ? null : () => Get.to(() => const SubmissionsScreen(initialTab: 4)),
          child: items.isEmpty
              ? _emptyLine('Your comments and discussions will show up here.')
              : Column(
                  children: items
                      .map((c) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              c.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(fontSize: 12.5, color: AppColors.textDark, height: 1.4),
                            ),
                          ))
                      .toList(),
                ),
        );
      },
    );
  }
}

// ── Site Safety Submissions ─────────────────────────────────────────────

class SiteSafetySubmissionsCard extends StatefulWidget {
  const SiteSafetySubmissionsCard({super.key});
  @override
  State<SiteSafetySubmissionsCard> createState() => _SiteSafetySubmissionsCardState();
}

class _SiteSafetySubmissionsCardState extends State<SiteSafetySubmissionsCard> {
  final _service = IncidentsService();
  late final Future<List<Incident>> _future =
      _service.getMyIncidents(perPage: 50).then((l) => l.where((i) => !i.isRoadSafety).toList());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Incident>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final items = snap.data!;
        return _PreviewSection(
          title: 'Site Safety Submissions',
          onViewAll: items.isEmpty ? null : () => Get.to(() => const SubmissionsScreen(initialTab: 3)),
          child: items.isEmpty
              ? _emptyLine('Site safety incidents you\'ve reported will show up here.')
              : Column(
                  children: items
                      .take(5)
                      .map((i) => _RowTile(
                            imageUrl: i.imageUrl,
                            title: i.title,
                            subtitle: i.location ?? i.severity,
                            onTap: () => Get.toNamed(AppRoutes.incidentDetail, arguments: i.slug),
                          ))
                      .toList(),
                ),
        );
      },
    );
  }
}
