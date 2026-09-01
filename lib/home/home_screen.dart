import '../shared/widgets/ad_banner_slot.dart';
// lib/home/home_screen.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/controllers/mjengo_auth_controller.dart';
import '../news/controllers/home_news_controller.dart';
import '../notifications/controllers/notifications_controller.dart';
import '../notifications/screens/notifications_screen.dart';
import '../news/models/article_model.dart';
import '../news/widgets/featured_article_card.dart';
import '../news/widgets/breaking_news_card.dart';
import '../news/widgets/net_image.dart';
import '../point/routes/app_routes.dart';
import '../shared/widgets/badges.dart';
import '../shared/widgets/preview_data_badge.dart';
import '../videos/controllers/videos_controller.dart';
import '../videos/models/video_model.dart';
import '../videos/screens/video_player_screen.dart';
import 'widgets/home_extra_sections.dart';

Future<void> _launchExternalUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeNewsController>();
    final topPad = MediaQuery.of(context).padding.top;
    final screenH = MediaQuery.of(context).size.height;

    // Hero height = 48 % of screen, clamped for small / large phones
    final heroH = (screenH * 0.48).clamp(280.0, 420.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Obx(() {
        if (ctrl.isLoading.value) {
          return _loadingState(heroH, topPad);
        }
        if (ctrl.featuredArticles.isEmpty && ctrl.breakingNews.isEmpty) {
          return _errorState(ctrl);
        }
        return _content(context, ctrl, heroH, topPad);
      }),
    );
  }

  // ── Main content ────────────────────────────────────────────────────────────

  Widget _content(
    BuildContext context,
    HomeNewsController ctrl,
    double heroH,
    double topPad,
  ) {
    return Column(
      children: [
        // ── Featured hero (fixed height, no scroll) ──────────────────────
        SizedBox(
          height: heroH,
          child: Stack(
            children: [
              // PageView of featured articles
              Obx(() => PageView.builder(
                    itemCount: ctrl.featuredArticles.length,
                    onPageChanged: ctrl.onPageChanged,
                    itemBuilder: (_, i) {
                      final article = ctrl.featuredArticles[i];
                      return FeaturedArticleCard(
                        article: article,
                        onTap: () => _openArticle(article),
                        showPreviewBadge: ctrl.isShowingDemoData.value,
                      );
                    },
                  )),

              // Header row: greeting (flexible, shrinks/ellipsizes first)
              // + action icons (fixed, pinned right) sharing one Row so
              // they can never overlap on narrow screens.
              Positioned(
                top: topPad + 8,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    Flexible(child: _greetingWidget()),
                    const Spacer(),
                    // ── Get Verified pill (Mjengo Hub Prime) ─────────────
                    GetVerifiedButton(
                      compact: true,
                      onTap: () => _launchExternalUrl('https://mjengohub.co.ke/verify'),
                    ),
                    const SizedBox(width: 8),
                    // ── Search ────────────────────────────────────────────
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.search),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.38),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ── Notification bell with badge ────────────────────
                    _NotificationBell(topPad: topPad),
                    const SizedBox(width: 8),
                    // ── Road Safety ─────────────────────────────────────
                    GestureDetector(
                      onTap: () => Get.toNamed('/share-barabara'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.report_problem_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Page dot indicators (bottom-right of hero) — flat line
              // dashes with clear vertical space above the greeting/search
              // row and below the hero edge, per the minimalist-indicator spec.
              Positioned(
                bottom: 30,
                right: 20,
                child: Obx(() => ctrl.featuredArticles.length > 1
                    ? PageDotIndicator(
                        count: ctrl.featuredArticles.length,
                        current: ctrl.featuredIndex.value,
                      )
                    : const SizedBox.shrink()),
              ),

              // Submit a Project CTA (bottom-left of hero, high-contrast)
              Positioned(
                bottom: 30,
                left: 16,
                child: SubmitProjectButton(
                  onTap: () => _launchExternalUrl('https://mjengohub.co.ke/projects/submit'),
                ),
              ),
            ],
          ),
        ),

        // ── Scrollable bottom section ─────────────────────────────────────
        Expanded(
          child: Container(
            color: Colors.white,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Explore Quick Actions ──────────────────────────────
                  const _ExploreSectionsWidget(),

                  // ── Breaking News (More News) ───────────────────────────
                  const SizedBox(height: 4),
                  _breakingHeader(ctrl),
                  const SizedBox(height: 14),
                  SizedBox(height: 220, child: _breakingList(ctrl)),

                  // Gap to "Follow Mjengo Hub" reduced ~70% (32px -> 10px)
                  const SizedBox(height: 10),
                  const AdBannerSlot(),
                    const SizedBox(height: 10),
                    const FollowMjengoHubSection(),

                  // ── Featured Projects (parity with the website's
                  // Latest/Featured Infrastructure & Private Projects) ──────
                  const SizedBox(height: 24),
                  const FeaturedProjectsSection(),

                  // ── Safety Incidents (parity with the website's Road
                  // Safety / Site Safety preview strips, but with real
                  // incident cards instead of a static CTA banner) ─────────
                  const SizedBox(height: 24),
                  const SafetyIncidentsSection(),

                  const SizedBox(height: 24),
                  Obx(() {
                    final articles = ctrl.featuredArticles.toList();
                    return FeaturedArticlesAnalysisSection(
                      articles: articles,
                      onOpen: _openArticle,
                      onSeeAll: () => Get.find<MainNavController>().currentIndex.value = 2,
                    );
                  }),

                  const SizedBox(height: 24),
                  const BrowseProjectsByCategorySection(),

                  // ── Latest Videos ──────────────────────────────────────
                  const _HomeVideosSection(),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ],
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

  // ── User greeting ────────────────────────────────────────────────────────────

  Widget _greetingWidget() {
    MjengoAuthController? userCtrl;
    try { userCtrl = Get.find<MjengoAuthController>(); } catch (_) {}

    if (userCtrl == null) return const SizedBox.shrink();

    return Obx(() {
      final user = userCtrl!.currentUser;
      final firstName = (user?.firstName?.trim().isNotEmpty == true
              ? user!.firstName!
              : user?.displayName?.split(' ').first ?? '')
          .trim();
      final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';
      final photoUrl = user?.photoURL;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.38),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar circle
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: NetImage(
                url: photoUrl,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_) => Center(
                  child: Text(initial,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Hello, ${firstName.isNotEmpty ? firstName : 'there'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Loading state ────────────────────────────────────────────────────────────

  Widget _loadingState(double heroH, double topPad) {
    return Column(
      children: [
        Container(height: heroH, color: const Color(0xFF1F2937)),
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
//  HOME VIDEOS SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _HomeVideosSection extends StatelessWidget {
  const _HomeVideosSection();

  static const _kYT = Color(0xFFFF0000);

  @override
  Widget build(BuildContext context) {
    // Safely find the controller — may not be ready if DI failed
    final VideosController? ctrl;
    try {
      ctrl = Get.find<VideosController>();
    } catch (_) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      // Don't render anything while loading or if empty
      if (ctrl!.isLoading.value) return const _VideosSectionShimmer();
      final videos = ctrl.videos.take(8).toList();
      if (videos.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: Color(0xFFEEEEF5), height: 32),
          ),

          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _kYT.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.play_circle_filled_rounded,
                          color: _kYT, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Latest Videos',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    // Navigate to Videos tab (index 2)
                    final navCtrl = Get.find<MainNavController>();
                    navCtrl.currentIndex.value = 3; // Videos
                  },
                  child: Text(
                    'See All',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Horizontal video list
          SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: videos.length,
              itemBuilder: (_, i) => _HomeVideoCard(video: videos[i]),
            ),
          ),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HOME VIDEO CARD (horizontal scroll item)
// ─────────────────────────────────────────────────────────────────────────────

class _HomeVideoCard extends StatelessWidget {
  final Video video;
  const _HomeVideoCard({required this.video});

  static const _kDark    = Color(0xFF1A1A2E);
  static const _kSubtext = Color(0xFF8888AA);
  static const _kYT      = Color(0xFFFF0000);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (kIsWeb) {
          _launchYouTube(video.youtubeUrl);
        } else {
          Get.to(
            () => VideoPlayerScreen(video: video),
            transition: Transition.cupertino,
          );
        }
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEF5)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: SizedBox(
                height: 108,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image
                    _VideoThumbnail(url: video.thumbnailUrl),

                    // Dark gradient at bottom
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 36,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0x88000000)],
                          ),
                        ),
                      ),
                    ),

                    // Play button
                    Center(
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.40),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),

                    // Duration badge
                    if (video.duration != null)
                      Positioned(
                        bottom: 5,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            video.duration!,
                            style: GoogleFonts.montserrat(
                              fontSize: 9.5,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Text section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kDark,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    // Views + YT icon
                    Row(
                      children: [
                        const Icon(Icons.visibility_rounded,
                            size: 10, color: _kSubtext),
                        const SizedBox(width: 3),
                        Text(
                          _formatViews(video.viewCount),
                          style: GoogleFonts.montserrat(
                              fontSize: 9.5, color: _kSubtext),
                        ),
                        const Spacer(),
                        const Icon(Icons.play_circle_filled_rounded,
                            size: 13, color: _kYT),
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

// ─────────────────────────────────────────────────────────────────────────────
//  Thumbnail helper
// ─────────────────────────────────────────────────────────────────────────────

class _VideoThumbnail extends StatelessWidget {
  final String? url;
  const _VideoThumbnail({this.url});

  @override
  Widget build(BuildContext context) {
    return NetImage(
      url: url,
      fit: BoxFit.cover,
      placeholderColor: const Color(0xFFEEEEF5),
      placeholderIcon: Icons.videocam_rounded,
      placeholderIconColor: const Color(0xFFCCCCDD),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Loading shimmer placeholder
// ─────────────────────────────────────────────────────────────────────────────

class _VideosSectionShimmer extends StatelessWidget {
  const _VideosSectionShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Divider(color: Color(0xFFEEEEF5), height: 32),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEF5),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 120, height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEF5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 4,
            itemBuilder: (_, __) => Container(
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEF5),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _launchYouTube(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

String _formatViews(int views) {
  if (views >= 1000000) return '${(views / 1000000).toStringAsFixed(1)}M';
  if (views >= 1000) return '${(views / 1000).toStringAsFixed(1)}K';
  return '$views';
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
      _SectionData(
        label: 'Report Hazard',
        icon: Icons.warning_amber_rounded,
        route: '/report-incident',
      ),
      _SectionData(
        label: 'ShareBarabara',
        icon: Icons.alt_route_rounded,
        route: 'https://sharebarabara.co.ke',
        isExternal: true,
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
      final uri = Uri.parse(data.route);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
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


