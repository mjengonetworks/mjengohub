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
import '../shared/widgets/preview_data_badge.dart';
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

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
        return _content(context, ctrl);
      }),
    );
  }

  // ── Main content ────────────────────────────────────────────────────────────

  Widget _content(BuildContext context, HomeNewsController ctrl) {
    // Hero scrolls away with the rest of the page (matches the website,
    // where it's just the first section of a normal document flow) instead
    // of staying pinned above a small scrollable remainder.
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section order mirrors the website homepage's actual flow
            // (templates/homepage.html): Hero → latest news → banner ad
            // → projects → videos → featured articles → site safety →
            // Mjengo Networks, with app-only utilities pushed to the end
            // rather than interrupting that flow up top.

            // ── Featured hero: auto-playing photo carousel, 3:2 aspect
            // ratio — matches the website's own .mj-hero mobile breakpoint
            // exactly (static/css/main.css: "Shorter, more landscape aspect
            // ratio than the old 4:3 -- brings the hero's footprint down
            // closer to the other pages' hero sections instead of a tall
            // dedicated photo slab"). ───────────────────────────────────────
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

            // Homepage section order below is deliberately interleaved
            // rather than stacked monolithically by content type: platform
            // sections (projects/articles/trackers) alternate with
            // ecosystem cross-promotion banners and the two curated
            // showcases (Built History, Africa & World), closing with a
            // micro leaderboard and the remaining utility feed.

            // 2 — Mjengo Networks showcase banner
            const SizedBox(height: 24),
            const MjengoNetworksBanner(),

            // 3 — Latest News & Articles (Part 1) — immediately follows the
            // Mjengo Networks banner
            const SizedBox(height: 24),
            _breakingHeader(ctrl),
            const SizedBox(height: 14),
            SizedBox(height: 220, child: _breakingList(ctrl)),
            const SizedBox(height: 10),
            const AdBannerSlot(),

            // 4 — Featured Infrastructure Projects
            const SizedBox(height: 24),
            const FeaturedProjectsSection(),

            // 5 — Built History showcase preview
            const SizedBox(height: 24),
            const BuiltHistoryPreviewSection(),

            // 6 — Share Barabara showcase banner
            const SizedBox(height: 24),
            const ShareBarabaraBanner(),

            // 7 — Africa & World continental spotlight preview
            const SizedBox(height: 24),
            const AfricaWorldPreviewSection(),

            // 8 — Extended Articles & Analysis (Part 2)
            const SizedBox(height: 24),
            Obx(() {
              final articles = ctrl.featuredArticles.toList();
              return FeaturedArticlesAnalysisSection(
                articles: articles,
                onOpen: _openArticle,
                onSeeAll: () => Get.find<MainNavController>().currentIndex.value = 2,
              );
            }),

            // 9 — Private Developments showcase
            const SizedBox(height: 24),
            const PrivateDevelopmentsShowcaseSection(),

            // 10 — Micro top-contributors leaderboard
            const SizedBox(height: 24),
            const MicroLeaderboardStrip(),

            // 11 — Site Safety strip + Partner With Us pitch card, back to
            // back as one high-conversion closing pair (matches the
            // website's Site Safety Preview immediately followed by the
            // Advertise-with-Us strip near the foot of the page)
            const SizedBox(height: 24),
            const SafetyIncidentsSection(),

            const SizedBox(height: 20),
            const _PartnerWithUsBanner(),

            // ── Explore Quick Actions (app-only shortcuts, no website
            // equivalent — kept just above the footer) ───────────────────
            const SizedBox(height: 28),
            const _ExploreSectionsWidget(),

            // 12 — Footer & channel links
            const SizedBox(height: 24),
            const SocialLinksGrid(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Breaking News header ────────────────────────────────────────────────────

  Widget _breakingHeader(HomeNewsController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Breaking News',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              Obx(() => ctrl.isShowingDemoData.value
                  ? const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: PreviewDataBadge(),
                    )
                  : const SizedBox.shrink()),
            ],
          ),
          GestureDetector(
            onTap: () {
              final navCtrl = Get.find<MainNavController>();
              navCtrl.currentIndex.value = 2; // Discover
            },
            child: Text(
              'More',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Breaking News horizontal list ───────────────────────────────────────────

  Widget _breakingList(HomeNewsController ctrl) {
    return Obx(() {
      if (ctrl.breakingNews.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'No breaking news at the moment.',
            style: GoogleFonts.montserrat(
                fontSize: 13, color: const Color(0xFF9CA3AF)),
          ),
        );
      }
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: ctrl.breakingNews.length,
        itemBuilder: (_, i) {
          final article = ctrl.breakingNews[i];
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
        AspectRatio(aspectRatio: 3 / 2, child: Container(color: const Color(0xFF1F2937))),
        const Expanded(
          child: Center(
            child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(Color(0xFF111827)),
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
            const Icon(Icons.wifi_off_rounded,
                size: 52, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            Text(
              ctrl.errorMessage.value.isNotEmpty
                  ? ctrl.errorMessage.value
                  : 'No content available right now. Pull to refresh.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 14, color: const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: ctrl.fetchHomeData,
              child: Text('Retry',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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

  static const _bubbleBg  = Color(0xFFEFF6FF);
  static const _iconColor  = Color(0xFF2563EB);
  static const _labelColor = Color(0xFF111827);

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
              borderRadius: BorderRadius.circular(16),
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
              color: _labelColor,
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
//  HERO HEADLINE + SEARCH CTA — matches the website's `.mj-hero-title` /
//  `.mj-hero-search` copy and typography exactly (templates/homepage.html).
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
            fontWeight: FontWeight.w800,
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
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_rounded, size: 17, color: Color(0xFF6B7280)),
                const SizedBox(width: 8),
                Text(
                  'Search articles, news, projects, safety incidents...',
                  style: GoogleFonts.montserrat(fontSize: 12.5, color: const Color(0xFF6B7280)),
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
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.handshake_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Partner With Us', style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('Advertise, sponsor a project, or reach our audience',
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
