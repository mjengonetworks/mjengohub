// lib/videos/screens/videos_screen.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../home/widgets/home_extra_sections.dart' show SocialLinksGrid;
import '../../news/widgets/net_image.dart';
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

const int _kPageSize = 6;

// ═════════════════════════════════════════════════════════════════════════════
//  ROOT SCREEN — mirrors mjengohub-website's /media page structure: header,
//  featured spotlight, YouTube grid (capped + "view more"), playlists strip,
//  and the official-channels / community-leaderboard footer. The website's
//  /media route has no podcast/audio-episode content (checked against
//  application.py's media_page() + templates/media.html), so that section
//  is intentionally omitted rather than fabricated.
// ═════════════════════════════════════════════════════════════════════════════

class VideosScreen extends StatefulWidget {
  const VideosScreen({Key? key}) : super(key: key);

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  final _scrollController = ScrollController();
  int _visibleCount = _kPageSize;
  int? _lastCategoryId = -1; // sentinel so the first build doesn't "change"

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleViewMore(VideosController ctrl, int gridLength) async {
    if (_visibleCount < gridLength) {
      setState(() => _visibleCount += _kPageSize);
      return;
    }
    if (ctrl.hasMore.value) {
      await ctrl.loadMore();
      if (mounted) setState(() => _visibleCount += _kPageSize);
    }
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

            // Reset the visible-count cap whenever the active category changes.
            if (_lastCategoryId != ctrl.selectedCategoryId.value) {
              _lastCategoryId = ctrl.selectedCategoryId.value;
              _visibleCount = _kPageSize;
            }

            // Hero = first featured video if one exists, else the newest
            // video overall; excluded from the grid below it so it isn't
            // shown twice.
            final hero = ctrl.featuredVideos.isNotEmpty
                ? ctrl.featuredVideos.first
                : (ctrl.videos.isNotEmpty ? ctrl.videos.first : null);
            final gridVideos = hero == null ? ctrl.videos : ctrl.videos.where((v) => v.id != hero.id).toList();

            final visible = gridVideos.take(_visibleCount).toList();
            final canViewMore = _visibleCount < gridVideos.length || ctrl.hasMore.value;

            return RefreshIndicator(
              color: _kDark,
              onRefresh: ctrl.refresh,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // ── 1. Header & category filter ──────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Media Hub', style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.w700, color: _kDark)),
                          const SizedBox(height: 4),
                          Text(
                            'Watch site walkthroughs, infrastructure updates, and industry interviews',
                            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w400, color: _kSubtext, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: const SizedBox(height: 16)),
                  SliverToBoxAdapter(child: _CategoryTabs(ctrl: ctrl)),

                  // ── 2. Featured spotlight ─────────────────────────────────
                  if (hero != null) ...[
                    SliverToBoxAdapter(child: const SizedBox(height: 20)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _FeaturedVideoSpotlight(video: hero, onTap: () => openVideo(context, hero)),
                      ),
                    ),
                  ],

                  // ── 3. YouTube grid, capped at 6 with a "view more" ──────
                  SliverToBoxAdapter(child: const SizedBox(height: 28)),
                  SliverToBoxAdapter(child: _SectionTitleRow(title: 'Latest Video Coverage')),
                  SliverToBoxAdapter(child: const SizedBox(height: 14)),

                  if (visible.isEmpty && !ctrl.isLoading.value)
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
                          (_, i) => VideoCard(video: visible[i], onTap: () => openVideo(context, visible[i])),
                          childCount: visible.length,
                        ),
                      ),
                    ),

                  if (canViewMore)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _ViewMoreButton(
                          isLoading: ctrl.isLoadingMore.value,
                          onTap: () => _handleViewMore(ctrl, gridVideos.length),
                        ),
                      ),
                    ),

                  // ── 4. Secondary sections: playlists + official channels ──
                  SliverToBoxAdapter(child: const SizedBox(height: 32)),
                  SliverToBoxAdapter(child: _PlaylistsSection(ctrl: ctrl)),

                  SliverToBoxAdapter(child: const SizedBox(height: 8)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          border: Border.all(color: _kBorder),
                          borderRadius: BorderRadius.circular(AppRadius.sharpLg),
                        ),
                        child: const SocialLinksGrid(),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: LeaderboardPreview()),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
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
          color: isSelected ? _kDark : Colors.transparent,
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
                          color: const Color(0xCC000000),
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
//  SECTION TITLE + YOUTUBE BADGE (for the "Latest Video Coverage" heading)
// ═════════════════════════════════════════════════════════════════════════════

class _SectionTitleRow extends StatelessWidget {
  final String title;
  const _SectionTitleRow({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(title, style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: _kDark)),
          const SizedBox(width: 10),
          const _YoutubeBadge(),
        ],
      ),
    );
  }
}

class _YoutubeBadge extends StatelessWidget {
  const _YoutubeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        border: Border.all(color: const Color(0xFFFFD5D5)),
        borderRadius: BorderRadius.circular(AppRadius.sharp),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.smart_display_rounded, size: 12, color: _kYT),
          const SizedBox(width: 4),
          Text('YOUTUBE', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFCC0000), letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  "VIEW MORE VIDEOS" BUTTON
// ═════════════════════════════════════════════════════════════════════════════

class _ViewMoreButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _ViewMoreButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: _kDark,
        borderRadius: BorderRadius.circular(AppRadius.sharp),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(AppRadius.sharp),
          child: Container(
            height: 46,
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : Text(
                    'View More Videos',
                    style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
          ),
        ),
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
                          color: const Color(0xCC000000),
                          borderRadius: BorderRadius.circular(AppRadius.sharp),
                        ),
                        child: Text(video.duration!,
                            style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white)),
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
              style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w500, color: _kSubtext, letterSpacing: 0.4),
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
//  SITE WALKTHROUGHS & PLAYLISTS — horizontal reel of curated video groupings
//  (GET youtube/playlists), tapping a card filters the grid above to it.
// ═════════════════════════════════════════════════════════════════════════════

class _PlaylistsSection extends StatelessWidget {
  final VideosController ctrl;
  const _PlaylistsSection({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final playlists = ctrl.playlists;
      if (playlists.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Site Walkthroughs & Playlists', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: _kDark)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 172,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: playlists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _PlaylistCard(playlist: playlists[i], ctrl: ctrl),
            ),
          ),
        ],
      );
    });
  }
}

class _PlaylistCard extends StatelessWidget {
  final VideoPlaylist playlist;
  final VideosController ctrl;
  const _PlaylistCard({required this.playlist, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSelected = ctrl.selectedPlaylistId.value == playlist.playlistId;
      return GestureDetector(
        onTap: () => ctrl.selectPlaylist(playlist.playlistId),
        child: Container(
          width: 220,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            border: Border.all(color: isSelected ? _kDark : _kBorder, width: isSelected ? 1.5 : 1),
            borderRadius: BorderRadius.circular(AppRadius.sharpLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetImage(
                      url: playlist.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholderColor: const Color(0xFF0F172A),
                      placeholderIcon: Icons.playlist_play_rounded,
                    ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xCC000000), borderRadius: BorderRadius.circular(AppRadius.sharp)),
                        child: Text('${playlist.videoCount} videos',
                            style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  playlist.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w600, color: _kDark, height: 1.3),
                ),
              ),
            ],
          ),
        ),
      );
    });
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
