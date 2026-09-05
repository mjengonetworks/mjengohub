import '../navigation/main_navigation.dart';
import '../shared/widgets/ad_banner_slot.dart';
// lib/home/home_screen.dart
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../news/controllers/home_news_controller.dart';
import '../news/models/article_model.dart';
import '../news/widgets/breaking_news_card.dart';
// featured_article_card.dart is imported for PageDotIndicator (hero
// carousel dots), not FeaturedArticleCard itself — this screen doesn't use
// that card.
import '../news/widgets/featured_article_card.dart' show PageDotIndicator;
import '../news/widgets/net_image.dart';
import '../point/routes/app_routes.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/badges.dart';
import '../shared/widgets/leaderboard_widget.dart';
import '../shared/widgets/partners_carousel.dart';
import '../shared/widgets/preview_data_badge.dart';
import '../shared/widgets/scroll_to_top_fab.dart';
import '../shared/widgets/section_header.dart';
import 'widgets/home_extra_sections.dart';

/// Opens a genuine external website in an in-app browser (Chrome Custom Tabs
/// on Android, SFSafariViewController on iOS) instead of handing off to the
/// system browser — the user never perceives leaving the app, matching how
/// X/Twitter's own in-app links behave. Native app hand-offs (Maps, the app
/// stores, share intents, YouTube) intentionally don't go through this —
/// those are genuinely better served by their own native app.
Future<void> _launchExternalUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeNewsController>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Obx(() {
        if (ctrl.isLoading.value) {
          return _loadingState();
        }
        if (ctrl.featuredArticles.isEmpty && ctrl.breakingNews.isEmpty) {
          return _errorState(ctrl);
        }
        return ScrollToTopFab(
          controller: _scrollController,
          child: _content(context, ctrl),
        );
      }),
    );
  }

  // ── Main content — Spec 10's exact 27-section sequence ─────────────────────

  Widget _content(BuildContext context, HomeNewsController ctrl) {
    // Hero scrolls away with the rest of the page (matches the website,
    // where it's just the first section of a normal document flow) instead
    // of staying pinned above a small scrollable remainder.
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Hero: auto-playing photo carousel, 3:2 aspect ratio,
            // minimal sharp search input, no decorative clipart. ───────────
            AspectRatio(
              aspectRatio: 3 / 2,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      // Admin-managed hero photos (GET site/hero-images) are
                      // the primary source, ordered by sort_order. Falls
                      // back to featured-article images if the admin hasn't
                      // configured any hero photos, so the carousel is never
                      // empty.
                      Obx(() {
                        final heroes = ctrl.heroImages;
                        final articles = ctrl.featuredArticles;
                        final slideCount = heroes.isNotEmpty ? heroes.length : articles.length;

                        if (slideCount == 0) {
                          return const _HeroSlide(imageUrl: null);
                        }

                        return CarouselSlider.builder(
                          itemCount: slideCount,
                          itemBuilder: (context, i, realIndex) {
                            if (heroes.isNotEmpty) {
                              final h = heroes[i];
                              return _HeroSlide(imageUrl: h.image, fallbackImageUrl: h.fallbackImage);
                            }
                            final article = articles[i];
                            return _HeroSlide(
                              imageUrl: article.imageUrl,
                              onTap: () => _openArticle(article),
                            );
                          },
                          options: CarouselOptions(
                            height: constraints.maxHeight,
                            viewportFraction: 1.0,
                            autoPlay: slideCount > 1,
                            autoPlayInterval: const Duration(seconds: 5),
                            onPageChanged: (index, reason) => ctrl.onPageChanged(index),
                          ),
                        );
                      }),

                      // Static headline + search CTA, constant across every slide —
                      // mirrors the website's `.mj-hero-title` / `.mj-hero-search`
                      // (templates/homepage.html), which sits over a rotating photo
                      // carousel the same way.
                      const Positioned(
                        left: 20,
                        right: 20,
                        top: 0,
                        bottom: 60,
                        child: Center(child: _HeroHeadline()),
                      ),

                      // Page dot indicators (bottom-right of hero) — flat line
                      // dashes, matching the website's `.mj-hero-dot`.
                      Positioned(
                        bottom: 14,
                        right: 20,
                        child: Obx(() {
                          final slideCount = ctrl.heroImages.isNotEmpty
                              ? ctrl.heroImages.length
                              : ctrl.featuredArticles.length;
                          return slideCount > 1
                              ? PageDotIndicator(count: slideCount, current: ctrl.featuredIndex.value)
                              : const SizedBox.shrink();
                        }),
                      ),

                      // Submit a Project CTA (bottom-left of hero, high-contrast)
                      Positioned(
                        bottom: 12,
                        left: 16,
                        child: SubmitProjectButton(
                          onTap: () => Get.toNamed(AppRoutes.submitProject),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // ── 2. Latest Construction News (top 4 + Read More) ─────────────
            const SizedBox(height: 18),
            _breakingHeader(ctrl),
            const SizedBox(height: 12),
            SizedBox(height: 220, child: _breakingList(ctrl)),

            // ── 3. Browse Articles by Category (directly beneath news) ──────
            const SizedBox(height: 12),
            const CategoryPillsBar(),

            // ── 4. Partner Banner (Slot 1) ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: const AdBannerSlot(slotNumber: 1),
            ),

            // ── 5. Latest Infrastructure Projects ────────────────────────────
            const FeaturedProjectsSection(
              featured: false,
              title: 'Latest Infrastructure Projects',
              subtitle: 'Roads, bridges and major public infrastructure tracked across Kenya',
            ),

            // ── 6. Mjengo Networks preview card ──────────────────────────────
            const SizedBox(height: 18),
            const MjengoNetworksBanner(),

            // ── 7. Latest Private Projects ───────────────────────────────────
            const SizedBox(height: 18),
            const PrivateDevelopmentsShowcaseSection(featured: false, title: 'Latest Private Projects'),

            // ── 8. Partner Banner (Slot 2) ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: const AdBannerSlot(slotNumber: 2),
            ),

            // ── 9. Share Barabara preview card ───────────────────────────────
            const ShareBarabaraBanner(),

            // ── 10. Featured Articles & Analysis (top 3-4) ───────────────────
            const SizedBox(height: 18),
            Obx(() {
              final articles = ctrl.featuredArticles.toList();
              return FeaturedArticlesAnalysisSection(
                articles: articles,
                onOpen: _openArticle,
                onSeeAll: () => Get.find<MainNavController>().currentIndex.value = MainNavController.tabNews,
              );
            }),

            // ── 11. Media Page Preview ───────────────────────────────────────
            const SizedBox(height: 18),
            const MediaPreviewBanner(),

            // ── 12. Mjengo Hub on YouTube ─────────────────────────────────────
            const SizedBox(height: 18),
            const YoutubeCarouselSection(),

            // ── 13. Partner Banner (Slot 3) ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: const AdBannerSlot(slotNumber: 3),
            ),

            // ── 14. Africa & World Showcase ──────────────────────────────────
            const AfricaWorldPreviewSection(),

            // ── 15. Merch Page Preview (Slot 1) ──────────────────────────────
            const SizedBox(height: 18),
            const MerchPreviewSection(title: 'Merch Preview'),

            // ── 16. Built History Showcase ───────────────────────────────────
            const SizedBox(height: 18),
            const BuiltHistoryPreviewSection(),

            // ── 17. Featured Public Projects ─────────────────────────────────
            const SizedBox(height: 18),
            const FeaturedProjectsSection(
              featured: true,
              title: 'Featured Public Projects',
              subtitle: 'Editor-picked public infrastructure making the biggest impact',
            ),

            // ── 18. Site Safety Page Preview ─────────────────────────────────
            const SizedBox(height: 18),
            const SafetyIncidentsSection(),

            // ── 19. Featured Private Projects ────────────────────────────────
            const SizedBox(height: 18),
            const PrivateDevelopmentsShowcaseSection(featured: true, title: 'Featured Private Projects'),

            // ── 20. Mjengo Hub Merch Page Preview (Slot 2) ───────────────────
            const SizedBox(height: 18),
            const MerchPreviewSection(title: 'Mjengo Hub Merch'),

            // ── 21. Partner Banner (Slot 4) ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: const AdBannerSlot(slotNumber: 4),
            ),

            // ── 22. Browse Projects by Category ──────────────────────────────
            const BrowseProjectsByCategorySection(),

            // ── 23. More News & Articles (Part 1) ────────────────────────────
            const SizedBox(height: 18),
            const MoreNewsSection(title: 'More News & Articles', page: 2),

            // ── 24. Partner Banner (Slot 5) — between Part 1 and Part 2 ──────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: const AdBannerSlot(slotNumber: 5),
            ),

            // ── 25. More News & Articles (Part 2) ────────────────────────────
            const MoreNewsSection(title: 'More News & Articles', page: 3),

            // ── 26. Join Our Community ───────────────────────────────────────
            const SizedBox(height: 18),
            const CommunitySection(),

            // ── 27. Our Partners Carousel ────────────────────────────────────
            const SizedBox(height: 18),
            const SectionHeader(title: 'Our Partners'),
            const SizedBox(height: 10),
            const PartnersCarousel(),

            // ── App-only utilities below the 27-section sequence ─────────────
            const SizedBox(height: 20),
            const _PartnerWithUsBanner(),

            const SizedBox(height: 24),
            const _ExploreSectionsWidget(),

            const SizedBox(height: 18),
            const SocialLinksGrid(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Latest Construction News header ─────────────────────────────────────────

  Widget _breakingHeader(HomeNewsController ctrl) {
    return Obx(() => SectionHeader(
          title: 'Latest Construction News',
          isDemo: ctrl.isShowingDemoData.value,
          seeAllLabel: 'Read More',
          onSeeAll: () => Get.find<MainNavController>().currentIndex.value = MainNavController.tabNews,
        ));
  }

  // ── Latest Construction News horizontal list (capped at 4) ─────────────────

  Widget _breakingList(HomeNewsController ctrl) {
    return Obx(() {
      if (ctrl.breakingNews.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'No breaking news at the moment.',
            style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.captionSlate),
          ),
        );
      }
      final items = ctrl.breakingNews.take(4).toList();
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final article = items[i];
          return BreakingNewsCard(
            article: article,
            onTap: () => _openArticle(article),
            showPreviewBadge: ctrl.isShowingDemoData.value,
          );
        },
      );
    });
  }

  // ── Loading state ────────────────────────────────────────────────────────────

  Widget _loadingState() {
    return Column(
      children: [
        AspectRatio(aspectRatio: 3 / 2, child: Container(color: AppColors.headingSlate)),
        const Expanded(
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.headingSlate),
              strokeWidth: 2,
            ),
          ),
        ),
      ],
    );
  }

  // ── Error state ──────────────────────────────────────────────────────────────

  Widget _errorState(HomeNewsController ctrl) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 52, color: AppColors.borderSlate),
            const SizedBox(height: 16),
            Text(
              ctrl.errorMessage.value.isNotEmpty
                  ? ctrl.errorMessage.value
                  : 'No content available right now. Pull to refresh.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 14, color: AppColors.captionSlate),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: ctrl.fetchHomeData,
              child: Text('Retry', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  void _openArticle(Article article) {
    Get.toNamed(AppRoutes.articleDetail, arguments: article.slug);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  EXPLORE SECTIONS WIDGET  –  compact horizontal icon pills
// ─────────────────────────────────────────────────────────────────────────────

class _ExploreSectionsWidget extends StatelessWidget {
  const _ExploreSectionsWidget();

  static const _sections = [
    _SectionData(
      label: 'Projects',
      icon: Icons.corporate_fare_rounded,
      route: '/projects',
    ),
    _SectionData(
      label: 'Saved',
      icon: Icons.bookmark_rounded,
      route: '/saved-items',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _sections
            .expand((s) => [
                  _ExploreIconPill(data: s),
                  if (s != _sections.last) const SizedBox(width: 24),
                ])
            .toList(),
      ),
    );
  }
}

class _SectionData {
  final String label;
  final IconData icon;
  final String route;
  final bool isExternal;
  const _SectionData({
    required this.label,
    required this.icon,
    required this.route,
    this.isExternal = false,
  });
}

class _ExploreIconPill extends StatelessWidget {
  final _SectionData data;
  const _ExploreIconPill({required this.data});

  static const _bubbleBg = Color(0xFFEFF6FF);
  static const _iconColor = Color(0xFF2563EB);

  Future<void> _handleTap() async {
    if (data.isExternal) {
      await _launchExternalUrl(data.route);
    } else {
      Get.toNamed(data.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _bubbleBg,
              borderRadius: BorderRadius.circular(AppRadius.sharpLg),
            ),
            child: Icon(data.icon, color: _iconColor, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            data.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.headingSlate,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HERO SLIDE — background image only (no per-slide text); the headline and
//  search CTA are a constant overlay rendered once above the PageView.
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSlide extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackImageUrl;
  final VoidCallback? onTap;
  const _HeroSlide({required this.imageUrl, this.fallbackImageUrl, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NetImage(
            url: imageUrl,
            fit: BoxFit.cover,
            placeholderColor: const Color(0xFF1F2937),
            // Retries on the working host if the CDN URL 404s — see
            // HeroImage.fallbackImage for why this is needed.
            errorBuilder: fallbackImageUrl != null
                ? (_) => NetImage(
                      url: fallbackImageUrl,
                      fit: BoxFit.cover,
                      placeholderColor: const Color(0xFF1F2937),
                    )
                : null,
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66000000), Color(0x99000000)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HERO HEADLINE + SEARCH CTA — minimal sharp search input, no clipart.
// ─────────────────────────────────────────────────────────────────────────────

class _HeroHeadline extends StatelessWidget {
  const _HeroHeadline();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Elevating and Documenting the Built Environment in Kenya and Beyond',
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.search),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.sharpLg),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search, size: 17, color: AppColors.captionSlate),
                const SizedBox(width: 8),
                Text(
                  'Search articles, news, projects, safety incidents...',
                  style: GoogleFonts.montserrat(fontSize: 12.5, color: AppColors.captionSlate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Partner With Us promo banner — closes the homepage feed, routes to the
//  Advertise pitch deck (AdvertiseScreen).
// ─────────────────────────────────────────────────────────────────────────────

class _PartnerWithUsBanner extends StatelessWidget {
  const _PartnerWithUsBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.advertise),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.deepNavy,
            borderRadius: BorderRadius.circular(AppRadius.sharp),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.sharp)),
                child: const Icon(Icons.handshake_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Partner With Us', style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w500, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('Advertise, sponsor a project, or reach our audience',
                        style: GoogleFonts.montserrat(fontSize: 11, color: Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
