// lib/videos/screens/videos_screen.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../home/widgets/home_extra_sections.dart' show SocialLinksGrid;
import '../../news/widgets/net_image.dart';
import '../../shared/services/site_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/leaderboard_widget.dart';
import '../../shared/widgets/responsive.dart';
import '../../shared/widgets/scroll_to_top_fab.dart';
import '../controllers/videos_controller.dart';
import '../models/video_model.dart';
import 'video_player_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens — sharp architectural system (Spec: no round over-styling,
// no faint metadata colors).
// ─────────────────────────────────────────────────────────────────────────────
const _kDark = Color(0xFF0F172A);
const _kSubtext = Color(0xFF475569);
const _kBorder = Color(0xFFE2E8F0);
const _kYT = Color(0xFFFF0000);

// ═════════════════════════════════════════════════════════════════════════════
//  ROOT SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class VideosScreen extends StatefulWidget {
  const VideosScreen({Key? key}) : super(key: key);

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<VideosController>();

    return ScrollToTopFab(
      controller: _scrollController,
      child: Container(
        color: Colors.white,
        child: ContentWidth(
          maxWidth: 1100,
          child: Obx(() {
            if (ctrl.isLoading.value && ctrl.videos.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(_kDark)),
              );
            }

            // Hero = first featured video if one exists, else the newest
            // video overall; excluded from the grid below it so it isn't
            // shown twice.
            final hero = ctrl.featuredVideos.isNotEmpty
                ? ctrl.featuredVideos.first
                : (ctrl.videos.isNotEmpty ? ctrl.videos.first : null);
            final gridVideos = hero == null ? ctrl.videos : ctrl.videos.where((v) => v.id != hero.id).toList();

            return RefreshIndicator(
              color: _kDark,
              onRefresh: ctrl.refresh,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Media', style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.w700, color: _kDark)),
                          const SizedBox(height: 4),
                          Text(
                            'Watch the latest infrastructure updates, site walkthroughs, and project spotlights',
                            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w400, color: _kSubtext, height: 1.4),
                          ),
                          const SizedBox(height: 14),
                          const _YoutubeStatsRow(),
                          const SizedBox(height: 14),
                          _SearchBar(ctrl: ctrl),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(child: const SizedBox(height: 14)),
                  SliverToBoxAdapter(child: _CategoryTabs(ctrl: ctrl)),

                  if (hero != null) ...[
                    SliverToBoxAdapter(child: const SizedBox(height: 18)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _FeaturedVideoSpotlight(video: hero, onTap: () => openVideo(context, hero)),
                      ),
                    ),
                  ],

                  SliverToBoxAdapter(child: const SizedBox(height: 22)),

                  if (gridVideos.isEmpty && !ctrl.isLoading.value)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text('No videos found.', style: GoogleFonts.montserrat(fontSize: 14, color: _kSubtext)),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: context.gridColumns,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: context.gridColumns == 1 ? 1.5 : 0.86,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => VideoCard(video: gridVideos[i], onTap: () => openVideo(context, gridVideos[i])),
                          childCount: gridVideos.length,
                        ),
                      ),
                    ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Obx(() {
                        if (ctrl.hasMore.value) {
                          ctrl.loadMore();
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(_kDark))),
                          );
                        }
                        return const Padding(
                          padding: EdgeInsets.only(top: 12, bottom: 20),
                          child: Column(
                            children: [
                              SocialLinksGrid(),
                              SizedBox(height: 20),
                              LeaderboardPreview(),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  CHANNEL STATS  (videos / subscribers / views, from GET site/figures)
// ═════════════════════════════════════════════════════════════════════════════

class _YoutubeStatsRow extends StatefulWidget {
  const _YoutubeStatsRow();

  @override
  State<_YoutubeStatsRow> createState() => _YoutubeStatsRowState();
}

class _YoutubeStatsRowState extends State<_YoutubeStatsRow> {
  final _service = SiteService();
  List<SiteFigure> _figures = const [];

  @override
  void initState() {
    super.initState();
    _service.getSiteFigures().then((figures) {
      if (mounted) setState(() => _figures = figures);
    });
  }

  SiteFigure? _byKey(String key) {
    for (final f in _figures) {
      if (f.key == key) return f;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _byKey('youtube_videos'),
      _byKey('youtube_subscribers'),
      _byKey('youtube_views'),
    ].whereType<SiteFigure>().toList();

    if (tiles.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (int i = 0; i < tiles.length; i++) ...[
          Expanded(child: _StatTile(figure: tiles[i])),
          if (i != tiles.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final SiteFigure figure;
  const _StatTile({required this.figure});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppRadius.sharp),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Text(figure.display, style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w500, color: _kYT)),
          const SizedBox(height: 2),
          Text(
            figure.name ?? '',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(fontSize: 10, color: _kSubtext),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SEARCH BAR
// ═════════════════════════════════════════════════════════════════════════════

class _SearchBar extends StatelessWidget {
  final VideosController ctrl;
  const _SearchBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sharpLg),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, size: 20, color: _kSubtext),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: ctrl.searchController,
              onSubmitted: ctrl.onSearchSubmit,
              textInputAction: TextInputAction.search,
              style: GoogleFonts.montserrat(fontSize: 14, color: _kDark),
              decoration: InputDecoration(
                hintText: 'Search videos',
                hintStyle: GoogleFonts.montserrat(fontSize: 14, color: _kSubtext),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: ctrl.searchController,
            builder: (_, val, __) => val.text.isNotEmpty
                ? GestureDetector(
                    onTap: ctrl.clearSearch,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.close_rounded, size: 18, color: _kSubtext),
                    ),
                  )
                : const SizedBox(width: 12),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  CATEGORY FILTER PILLS — solid deep-slate active pill, bordered inactive
// ═════════════════════════════════════════════════════════════════════════════

class _CategoryTabs extends StatelessWidget {
  final VideosController ctrl;
  const _CategoryTabs({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cats = ctrl.categories;
      return SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _PillTab(
              label: 'All Media',
              isSelected: ctrl.selectedCategoryId.value == null,
              onTap: () => ctrl.selectCategory(null),
            ),
            for (final c in cats) ...[
              const SizedBox(width: 8),
              _PillTab(
                label: c.name,
                isSelected: ctrl.selectedCategoryId.value == c.id,
                onTap: () => ctrl.selectCategory(c.id),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _PillTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _PillTab({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? _kDark : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sharp),
          border: Border.all(color: isSelected ? _kDark : _kBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  FEATURED / HERO VIDEO SPOTLIGHT
// ═════════════════════════════════════════════════════════════════════════════

class _FeaturedVideoSpotlight extends StatelessWidget {
  final Video video;
  final VoidCallback onTap;
  const _FeaturedVideoSpotlight({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sharpLg),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetImage(
                    url: video.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholderColor: const Color(0xFF0F172A),
                    placeholderIcon: Icons.videocam_rounded,
                  ),
                  Container(color: Colors.black.withValues(alpha: 0.12)),
                  Center(
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 4,
                      child: Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        child: const Icon(Icons.play_arrow_rounded, color: _kDark, size: 34),
                      ),
                    ),
                  ),
                  if (video.duration != null)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(AppRadius.sharp),
                        ),
                        child: Text(video.duration!,
                            style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (video.category != null) ...[
          _CategoryPill(video.category!.name),
          const SizedBox(height: 10),
        ],
        Text(
          video.title,
          style: GoogleFonts.montserrat(fontSize: 21, fontWeight: FontWeight.w700, color: _kDark, height: 1.3),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.smart_display_rounded, size: 14, color: _kSubtext),
            const SizedBox(width: 5),
            Text('Mjengo Hub', style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w400, color: _kSubtext)),
            if (video.publishedAt != null) ...[
              Text('  ·  ', style: GoogleFonts.montserrat(fontSize: 12.5, color: _kSubtext)),
              Text(_formatDate(video.publishedAt!), style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w400, color: _kSubtext)),
            ],
          ],
        ),
        if (video.description.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            video.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w400, color: const Color(0xFF334155), height: 1.5),
          ),
        ],
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  const _CategoryPill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: _kDark, borderRadius: BorderRadius.circular(AppRadius.sharp)),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white, letterSpacing: 0.4),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  VIDEO GRID CARD
// ═════════════════════════════════════════════════════════════════════════════

class VideoCard extends StatelessWidget {
  final Video video;
  final VoidCallback? onTap;
  const VideoCard({Key? key, required this.video, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sharp),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetImage(
                    url: video.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholderColor: const Color(0xFF0F172A),
                    placeholderIcon: Icons.videocam_rounded,
                  ),
                  Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                  if (video.duration != null)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(AppRadius.sharp),
                        ),
                        child: Text(video.duration!,
                            style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (video.category != null) ...[
            Text(
              video.category!.name.toUpperCase(),
              style: GoogleFonts.montserrat(fontSize: 10.5, fontWeight: FontWeight.w500, color: _kSubtext, letterSpacing: 0.4),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            video.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w600, color: _kDark, height: 1.3),
          ),
          const SizedBox(height: 4),
          if (video.publishedAt != null)
            Text(
              _formatDate(video.publishedAt!),
              style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w400, color: _kSubtext),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  PLAYBACK — full-screen on mobile/desktop app, inline modal on web (so we
//  never boot the user out to a separate YouTube tab, and never touch
//  CanvasKit's WebGL context directly -- youtube_player_iframe composes its
//  own iframe as a platform view, same mechanism as net_image_html_web.dart).
// ═════════════════════════════════════════════════════════════════════════════

void openVideo(BuildContext context, Video video) {
  if (kIsWeb) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => _VideoModal(video: video),
    );
  } else {
    Get.to(() => VideoPlayerScreen(video: video), transition: Transition.cupertino);
  }
}

class _VideoModal extends StatefulWidget {
  final Video video;
  const _VideoModal({required this.video});

  @override
  State<_VideoModal> createState() => _VideoModalState();
}

class _VideoModalState extends State<_VideoModal> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.video.youtubeId,
      autoPlay: true,
      params: const YoutubePlayerParams(mute: false, showControls: true, showFullscreenButton: true),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final modalWidth = width > 900 ? 800.0 : width * 0.92;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sharpLg)),
      child: SizedBox(
        width: modalWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.video.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: _kDark),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: _kDark),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.sharpLg)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: YoutubePlayer(controller: _controller),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _formatDate(DateTime dt) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}
