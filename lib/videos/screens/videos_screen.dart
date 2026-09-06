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

const int _kPageSize = 6;

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
  int _visibleCount = _kPageSize;
  int? _lastCategoryId = -1; // sentinel so the first build doesn't "change"

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleViewMore(VideosController ctrl) async {
    if (_visibleCount < ctrl.videos.length) {
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

            final videos = ctrl.videos;
            final visible = videos.take(_visibleCount).toList();
            final canViewMore = _visibleCount < videos.length || ctrl.hasMore.value;

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
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(child: const SizedBox(height: 16)),
                  SliverToBoxAdapter(child: _CategoryTabs(ctrl: ctrl)),
                  SliverToBoxAdapter(child: const SizedBox(height: 20)),

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

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        children: [
                          if (canViewMore) _ViewMoreButton(isLoading: ctrl.isLoadingMore.value, onTap: () => _handleViewMore(ctrl)),
                          if (!canViewMore) ...[
                            const SocialLinksGrid(),
                            const SizedBox(height: 20),
                            const LeaderboardPreview(),
                          ],
                        ],
                      ),
                    ),
                  ),
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
