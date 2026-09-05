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
import '../../projects/services/projects_service.dart';
import '../../projects/widgets/tracker_project_card.dart';
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
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.corporate_fare_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Explore Active Developments', style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('Track infrastructure and private projects across Kenya',
                        style: GoogleFonts.montserrat(fontSize: 11, color: Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
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
  State<ArticleDiscoverySection> createState() => _ArticleDiscoverySectionState();
}

class _ArticleDiscoverySectionState extends State<ArticleDiscoverySection> {
  final _newsService = NewsApiService();
  final _projectsService = ProjectsService();

  List<Article> _related = [];
  List<Article> _trending = [];
  List<Article> _latest = [];
  List<Project> _showcaseProjects = [];
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
      _projectsService.getProjects(projectType: 'infrastructure', featured: true, perPage: 4),
    ]);
    if (!mounted) return;
    final related = (results[0] as List<Article>).where((a) => a.slug != widget.article.slug).toList();
    final trendingSource = (results[1] as List<Article>).where((a) => a.slug != widget.article.slug).toList()
      ..sort((a, b) => b.viewCount.compareTo(a.viewCount));
    setState(() {
      _related = related.take(4).toList();
      _trending = trendingSource.take(4).toList();
      _latest = (results[2] as List<Article>).where((a) => a.slug != widget.article.slug).take(4).toList();
      _showcaseProjects = results[3] as List<Project>;
      _loading = false;
    });
  }

  void _openArticle(Article a) => Get.toNamed(AppRoutes.articleDetail, arguments: a.slug);

  /// "View All" / "Read More" targets all resolve to the News tab -- there's
  /// no dedicated trending/related-only screen, same destination the
  /// homepage's own "More News & Articles" sections already route to.
  void _viewAllNews() => Get.find<MainNavController>().currentIndex.value = MainNavController.tabNews;

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
        // Latest Articles comes first, directly below the article content,
        // followed by Trending -- both capped at 4 cards with a centered
        // "View All" button, matching the homepage's section pattern.
        if (_latest.isNotEmpty) ...[
          _SectionHeading('Latest Articles'),
          const SizedBox(height: 10),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _latest.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _RelatedArticleCard(article: _latest[i], onTap: () => _openArticle(_latest[i])),
            ),
          ),
          const SizedBox(height: 12),
          _ViewAllButton(label: 'View All Latest Articles', onTap: _viewAllNews),
          const SizedBox(height: 24),
        ],

        if (_trending.isNotEmpty) ...[
          _SectionHeading('Trending Articles'),
          const SizedBox(height: 6),
          ..._trending.asMap().entries.map((e) => _TrendingRow(rank: e.key + 1, article: e.value, onTap: () => _openArticle(e.value))),
          const SizedBox(height: 6),
          _ViewAllButton(label: 'View All Trending Articles', onTap: _viewAllNews),
          const SizedBox(height: 24),
        ],

        if (_related.isNotEmpty) ...[
          _SectionHeading('Related News & Articles'),
          const SizedBox(height: 10),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _related.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _RelatedArticleCard(article: _related[i], onTap: () => _openArticle(_related[i])),
            ),
          ),
          const SizedBox(height: 12),
          _ViewAllButton(label: 'View All Related Articles', onTap: _viewAllRelated),
          const SizedBox(height: 24),
        ],

        if (_showcaseProjects.isNotEmpty) ...[
          _SectionHeading('Explore Projects'),
          const SizedBox(height: 10),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _showcaseProjects.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => TrackerProjectCard(project: _showcaseProjects[i], width: 190),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
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
              Text(label, style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.headingSlate)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, size: 14, color: AppColors.headingSlate),
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
      child: Text(title, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
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
        width: 200,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: NetImage(url: article.imageUrl, fit: BoxFit.cover, width: double.infinity, placeholderColor: const Color(0xFF1F2937)),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textDark, height: 1.3)),
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
  const _TrendingRow({required this.rank, required this.article, required this.onTap});

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
              child: Text('$rank',
                  style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.accentBlue)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark, height: 1.35)),
            ),
          ],
        ),
      ),
    );
  }
}

