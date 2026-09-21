// lib/profile/screens/public_profile_screen.dart
//
// Read-only public view of another user's profile — opened by tapping a
// name in the Contributors leaderboard (or elsewhere in the app). Backed by
// `GET /users/<id>`, a public-safe reduction of the current user's own
// `/auth/me` shape (no email/phone).
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../news/models/article_model.dart';
import '../../news/widgets/net_image.dart';
import '../../point/routes/app_routes.dart';
import '../../projects/models/project_model.dart';
import '../../projects/screens/project_detail_screen.dart';
import '../../shared/services/link_launcher.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/coming_soon.dart';
import '../../shared/widgets/responsive.dart';
import '../models/public_profile_model.dart';
import '../services/public_profile_service.dart';

class PublicProfileScreen extends StatefulWidget {
  final int userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final _service = PublicProfileService();
  late final Future<_ProfileData> _future = _load();

  Future<_ProfileData> _load() async {
    final results = await Future.wait([
      _service.getUser(widget.userId),
      _service.getUserComments(widget.userId),
    ]);
    return _ProfileData(
      profile: results[0] as PublicProfile?,
      comments: results[1] as List<PublicComment>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        title: Text(
          'Profile',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: FutureBuilder<_ProfileData>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData && snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = snap.data?.profile;
          if (profile == null) {
            return const ComingSoonPlaceholder(
              icon: Icons.person_off_rounded,
              title: 'Profile unavailable',
              message: 'This profile could not be loaded.',
            );
          }
          final comments = snap.data?.comments ?? const [];
          final categories = profile.categoriesWritten;
          // Order: Header → Associated Projects → Comments → Latest
          // Articles → Categories Written.
          return ContentWidth(
            maxWidth: 700,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(profile: profile),
                  if (profile.projects.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SectionHeader(
                      title: 'Associated Projects',
                      count: profile.projectCount,
                    ),
                    ...profile.projects.map((p) => _ProjectRow(project: p)),
                  ],
                  if (comments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SectionHeader(title: 'Comments', count: comments.length),
                    ...comments.map((c) => _CommentRow(comment: c)),
                  ],
                  if (profile.articles.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SectionHeader(
                      title: 'Latest Articles',
                      count: profile.articleCount,
                    ),
                    ...profile.articles.map((a) => _ArticleRow(article: a)),
                  ],
                  if (categories.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SectionHeader(
                      title: 'Categories Written',
                      count: categories.length,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories
                            .map((c) => _CategoryChip(label: c))
                            .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileData {
  final PublicProfile? profile;
  final List<PublicComment> comments;
  const _ProfileData({required this.profile, required this.comments});
}

class _Header extends StatelessWidget {
  final PublicProfile profile;
  const _Header({required this.profile});

  @override
  Widget build(BuildContext context) {
    final hasCover =
        profile.coverImage != null && profile.coverImage!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 110,
          decoration: BoxDecoration(
            gradient: hasCover ? null : AppColors.verifiedPillGradient,
            image: hasCover
                ? DecorationImage(
                    image: NetworkImage(profile.coverImage!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Transform.translate(
            offset: const Offset(0, -36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipOval(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: NetImage(
                      url: profile.avatar,
                      fit: BoxFit.cover,
                      placeholderColor: const Color(0xFF1E3A5F),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Text(
                      profile.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (profile.isVerified) const PrimeBadge(),
                    if (profile.role != null &&
                        profile.role!.toUpperCase() != 'USER')
                      RoleBadge(role: profile.role!),
                  ],
                ),
                const SizedBox(height: 6),
                ReviewerLevelBadge(points: profile.points),
                if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    profile.bio!,
                    style: GoogleFonts.montserrat(
                      fontSize: 12.5,
                      color: AppColors.textDark,
                      height: 1.5,
                    ),
                  ),
                ],
                if ((profile.mjengoNetworksUrl?.isNotEmpty ?? false) ||
                    (profile.shareBarabaraUrl?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (profile.mjengoNetworksUrl?.isNotEmpty ?? false)
                        _LinkChip(
                          label: 'Mjengo Networks',
                          onTap: () => LinkLauncher.openLink(
                            context,
                            profile.mjengoNetworksUrl!,
                          ),
                        ),
                      if (profile.shareBarabaraUrl?.isNotEmpty ?? false)
                        _LinkChip(
                          label: 'Share Barabara',
                          onTap: () => LinkLauncher.openLink(
                            context,
                            profile.shareBarabaraUrl!,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LinkChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LinkChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accentBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.accentBlue,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        '$title ($count)',
        style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  final Project project;
  const _ProjectRow({required this.project});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 44,
          height: 44,
          child: NetImage(
            url: project.imageUrl,
            fit: BoxFit.cover,
            placeholderColor: const Color(0xFF1E3A5F),
          ),
        ),
      ),
      title: Text(
        project.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        project.statusLabel,
        style: GoogleFonts.montserrat(
          fontSize: 11,
          color: AppColors.textSubtle,
        ),
      ),
      onTap: () => Get.to(
        () => ProjectDetailScreen(slug: project.slug),
        transition: Transition.cupertino,
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  final PublicComment comment;
  const _CommentRow({required this.comment});

  String get _onLabel {
    switch (comment.commentableType) {
      case 'article':
        return 'on an article';
      case 'project':
        return 'on a project';
      case 'incident':
        return 'on a safety report';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comment.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: 12.5,
              color: AppColors.textDark,
              height: 1.4,
            ),
          ),
          if (_onLabel.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              _onLabel,
              style: GoogleFonts.montserrat(
                fontSize: 10.5,
                color: AppColors.textSubtle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AppColors.accentBlue,
        ),
      ),
    );
  }
}

class _ArticleRow extends StatelessWidget {
  final Article article;
  const _ArticleRow({required this.article});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 44,
          height: 44,
          child: NetImage(url: article.imageUrl, fit: BoxFit.cover),
        ),
      ),
      title: Text(
        article.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        article.timeAgo,
        style: GoogleFonts.montserrat(
          fontSize: 11,
          color: AppColors.textSubtle,
        ),
      ),
      onTap: () =>
          Get.toNamed(AppRoutes.articleDetail, arguments: article.slug),
    );
  }
}
