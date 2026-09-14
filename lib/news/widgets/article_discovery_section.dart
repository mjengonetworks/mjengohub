// lib/news/widgets/article_discovery_section.dart
//
// Post-article discovery widgets: Related News, Trending Articles, Latest
// Articles, and a Project Tracker showcase strip — everything below the
// article body / comments on ArticleDetailScreen.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/main_navigation.dart';
import '../../point/routes/app_routes.dart';
import '../../projects/models/project_model.dart';
import '../../projects/screens/project_detail_screen.dart';
import '../../projects/services/projects_service.dart';
import '../../projects/widgets/projects_map_view.dart' show statusMarkerColor;
import '../../shared/theme/app_theme.dart';
import '../controllers/discover_controller.dart';
import '../models/article_model.dart';
import '../services/news_api_service.dart';
import 'net_image.dart';

/// Small dedicated-tracker discovery card — used both interleaved mid-body
/// and again at the end of the article. There is no article↔project link in
/// the backend (no "projects mentioned in this article" data exists), so
/// this deliberately stays generic ("Explore Projects") rather than
/// fabricating a claim the API can't back up.
class RelatedTrackersCard extends StatelessWidget {
  const RelatedTrackersCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.projects),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.deepNavy,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.corporate_fare_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore Active Developments',
                      style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track infrastructure and private projects across Kenya',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArticleDiscoverySection extends StatefulWidget {
  final Article article;
  const ArticleDiscoverySection({super.key, required this.article});

  @override
  State<ArticleDiscoverySection> createState() =>
      _ArticleDiscoverySectionState();
}

class _ArticleDiscoverySectionState extends State<ArticleDiscoverySection> {
  final _newsService = NewsApiService();
  final _projectsService = ProjectsService();

  List<Article> _related = [];
  List<Article> _trending = [];
  List<Article> _latest = [];
  List<Project> _infrastructureProjects = [];
  List<Project> _privateProjects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final categorySlug = widget.article.category?.slug;
    final results = await Future.wait([
      // Related — same category, excluding this article.
      categorySlug != null
          ? _newsService.getArticles(categorySlug: categorySlug, perPage: 8)
          : Future.value(<Article>[]),
      // Trending — no dedicated "most viewed" sort exists for articles
      // server-side, so this is the latest batch re-sorted by view_count
      // client-side, a reasonable proxy rather than a true trending algorithm.
      _newsService.getArticles(perPage: 20),
      _newsService.getArticles(perPage: 6),
      _projectsService.getProjects(
        projectType: 'infrastructure',
        featured: true,
        perPage: 4,
      ),
      _projectsService.getProjects(
        projectType: 'private_development',
        perPage: 4,
      ),
    ]);
    if (!mounted) return;
    final related = (results[0] as List<Article>)
        .where((a) => a.slug != widget.article.slug)
        .toList();
    final trendingSource =
        (results[1] as List<Article>)
            .where((a) => a.slug != widget.article.slug)
            .toList()
          ..sort((a, b) => b.viewCount.compareTo(a.viewCount));
    setState(() {
      _related = related.take(4).toList();
      _trending = trendingSource.take(4).toList();
      _latest = (results[2] as List<Article>)
          .where((a) => a.slug != widget.article.slug)
          .take(4)
          .toList();
      _infrastructureProjects = results[3] as List<Project>;
      _privateProjects = results[4] as List<Project>;
      _loading = false;
    });
  }

  void _explorePrivateProjects() => Get.toNamed(AppRoutes.privateProjects);

  void _openArticle(Article a) =>
      Get.toNamed(AppRoutes.articleDetail, arguments: a.slug);

  /// "View All" / "Read More" targets all resolve to the News tab -- there's
  /// no dedicated trending/related-only screen, same destination the
  /// homepage's own "More News & Articles" sections already route to.
  void _viewAllNews() => Get.find<MainNavController>().currentIndex.value =
      MainNavController.tabNews;

  void _viewAllRelated() {
    final slug = widget.article.category?.slug;
    if (slug != null && Get.isRegistered<DiscoverController>()) {
      Get.find<DiscoverController>().selectCategory(slug);
    }
    _viewAllNews();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exact order requested: Related -> Latest -> Trending. Each capped
        // at 4 cards with a centered "View All" button.
        if (_related.isNotEmpty) ...[
          _SectionHeading('Related Articles'),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                for (final article in _related) ...[
                  _RelatedArticleCard(
                    article: article,
                    onTap: () => _openArticle(article),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ViewAllButton(
            label: 'View All Related Articles',
            onTap: _viewAllRelated,
          ),
          const SizedBox(height: 24),
        ],

        if (_latest.isNotEmpty) ...[
          _SectionHeading('Latest Articles'),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                for (final article in _latest) ...[
                  _RelatedArticleCard(
                    article: article,
                    onTap: () => _openArticle(article),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ViewAllButton(
            label: 'View All Latest Articles',
            onTap: _viewAllNews,
          ),
          const SizedBox(height: 24),
        ],

        if (_trending.isNotEmpty) ...[
          _SectionHeading('Trending Articles'),
          const SizedBox(height: 6),
          ..._trending.asMap().entries.map(
            (e) => _TrendingRow(
              rank: e.key + 1,
              article: e.value,
              onTap: () => _openArticle(e.value),
            ),
          ),
          const SizedBox(height: 6),
          _ViewAllButton(
            label: 'View All Trending Articles',
            onTap: _viewAllNews,
          ),
          const SizedBox(height: 24),
        ],

        if (_infrastructureProjects.isNotEmpty) ...[
          const _TrackerPill(
            label: 'INFRASTRUCTURE TRACKER',
            color: Color(0xFF0284C7),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                for (final project in _infrastructureProjects) ...[
                  _TrackerPreviewCard(project: project),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ViewAllButton(
            label: 'Explore Infrastructure Projects',
            onTap: () => Get.toNamed(AppRoutes.projects),
          ),
          const SizedBox(height: 24),
        ],

        if (_privateProjects.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Private Projects Tracker',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                GestureDetector(
                  onTap: _explorePrivateProjects,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Explore Private Projects',
                        style: GoogleFonts.montserrat(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentBlue,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: AppColors.accentBlue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                for (final project in _privateProjects) ...[
                  _TrackerPreviewCard(project: project),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

// ── "INFRASTRUCTURE TRACKER" style section pill ─────────────────────────────

class _TrackerPill extends StatelessWidget {
  final String label;
  final Color color;
  const _TrackerPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Mini tracker card: thumbnail, title, county/location badge, progress ───

class _TrackerPreviewCard extends StatelessWidget {
  final Project project;
  const _TrackerPreviewCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final place = project.county ?? project.location ?? project.country;
    return GestureDetector(
      onTap: () => Get.to(
        () => ProjectDetailScreen(slug: project.slug),
        transition: Transition.cupertino,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSlate),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 92,
              child: NetImage(
                url: project.imageUrl,
                fit: BoxFit.cover,
                placeholderColor: const Color(0xFF1E3A5F),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      project.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        if (place != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              place,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Builder(
                            builder: (_) {
                              final statusColor = statusMarkerColor(
                                project.status,
                              );
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  project.statusLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value:
                                  (project.progressPercent.clamp(0, 100)) / 100,
                              minHeight: 5,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${project.progressPercent.clamp(0, 100).round()}%',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Centered "View All" button (architectural sharp style) ─────────────────

class _ViewAllButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ViewAllButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.sharpLg),
            border: Border.all(color: AppColors.borderSlate),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.headingSlate,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward,
                size: 14,
                color: AppColors.headingSlate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  const _SectionHeading(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
        ),
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFF97316),
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

class _RelatedArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;
  const _RelatedArticleCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: NetImage(
                url: article.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholderColor: const Color(0xFF1F2937),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                article.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingRow extends StatelessWidget {
  final int rank;
  final Article article;
  final VoidCallback onTap;
  const _TrendingRow({
    required this.rank,
    required this.article,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '$rank',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accentBlue,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                article.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
