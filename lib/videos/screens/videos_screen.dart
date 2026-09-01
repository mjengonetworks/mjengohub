// lib/videos/screens/videos_screen.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../news/widgets/net_image.dart';
import '../../shared/services/site_service.dart';
import '../controllers/videos_controller.dart';
import '../models/video_model.dart';
import 'video_player_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens — matches the rest of the app
// ─────────────────────────────────────────────────────────────────────────────
const _kBlue    = Color(0xFF2563EB);
const _kDark    = Color(0xFF111827);
const _kSubtext = Color(0xFF9CA3AF);
const _kBg      = Color(0xFFF3F4F6);
const _kDivider = Color(0xFFF3F4F6);
const _kYT      = Color(0xFFFF0000);

// ═════════════════════════════════════════════════════════════════════════════
//  ROOT SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class VideosScreen extends StatelessWidget {
  const VideosScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ctrl   = Get.find<VideosController>();
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topPad + 12),

          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Videos',
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _kDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Latest from @MjengoHubKE',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: _kSubtext,
                  ),
                ),
                const SizedBox(height: 14),

                // ── Channel stats (mirrors templates/youtube.html's
                // videos/subscribers/views tiles, via GET site/figures) ──
                const _YoutubeStatsRow(),
                const SizedBox(height: 14),

                // ── Search bar ─────────────────────────────────────────
                _SearchBar(ctrl: ctrl),
                const SizedBox(height: 18),
              ],
            ),
          ),

          // ── Category tabs ─────────────────────────────────────────────
          _CategoryTabs(ctrl: ctrl),
          const SizedBox(height: 8),

          // ── Video list ────────────────────────────────────────────────
          Expanded(child: _VideoList(ctrl: ctrl)),
        ],
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
        color: _kBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            figure.display,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _kYT,
            ),
          ),
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
//  SEARCH BAR  (mirrors Discover's _SearchBar)
// ═════════════════════════════════════════════════════════════════════════════

class _SearchBar extends StatelessWidget {
  final VideosController ctrl;
  const _SearchBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search_rounded, size: 20, color: _kSubtext),
          const SizedBox(width: 8),

          // Text field
          Expanded(
            child: TextField(
              controller: ctrl.searchController,
              onSubmitted: ctrl.onSearchSubmit,
              textInputAction: TextInputAction.search,
              style: GoogleFonts.montserrat(fontSize: 14, color: _kDark),
              decoration: InputDecoration(
                hintText: 'Search videos',
                hintStyle:
                    GoogleFonts.montserrat(fontSize: 14, color: const Color(0xFFADB5BD)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // Clear button
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: ctrl.searchController,
            builder: (_, val, __) => val.text.isNotEmpty
                ? GestureDetector(
                    onTap: ctrl.clearSearch,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.close_rounded,
                          size: 18, color: _kSubtext),
                    ),
                  )
                : const SizedBox(width: 8),
          ),

          // Divider
          Container(height: 30, width: 1, color: const Color(0xFFE5E7EB)),

          // Filter icon — shows purple dot when a category is active
          Obx(() {
            final active = ctrl.selectedCategoryId.value != null;
            return GestureDetector(
              onTap: () => _showFilterSheet(context, ctrl),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.tune_rounded,
                        size: 18,
                        color: active ? _kBlue : const Color(0xFF374151)),
                    if (active)
                      Positioned(
                        top: -3,
                        right: -3,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: _kBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  CATEGORY TABS  (same underline style as Discover)
// ═════════════════════════════════════════════════════════════════════════════

class _CategoryTabs extends StatelessWidget {
  final VideosController ctrl;
  const _CategoryTabs({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cats = ctrl.categories;

      return SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _TabItem(
              label: 'All',
              isSelected: ctrl.selectedCategoryId.value == null,
              onTap: () => ctrl.selectCategory(null),
            ),
            ...cats.map((c) => _TabItem(
                  label: c.name,
                  isSelected: ctrl.selectedCategoryId.value == c.id,
                  onTap: () => ctrl.selectCategory(c.id),
                )),
          ],
        ),
      );
    });
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _TabItem(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 24),
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? _kDark : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? _kDark : _kSubtext,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  VIDEO LIST  (mirrors Discover's _ArticleList)
// ═════════════════════════════════════════════════════════════════════════════

class _VideoList extends StatelessWidget {
  final VideosController ctrl;
  const _VideoList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Loading with no content yet
      if (ctrl.isLoading.value && ctrl.videos.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_kDark),
          ),
        );
      }

      // Empty
      if (ctrl.videos.isEmpty) {
        return Center(
          child: Text(
            'No videos found.',
            style: GoogleFonts.montserrat(fontSize: 14, color: _kSubtext),
          ),
        );
      }

      // List
      return RefreshIndicator(
        color: _kDark,
        onRefresh: ctrl.refresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n is ScrollEndNotification && n.metrics.extentAfter < 200) {
              ctrl.loadMore();
            }
            return false;
          },
          child: ListView.separated(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            itemCount: ctrl.videos.length + (ctrl.hasMore.value ? 1 : 0),
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
              color: _kDivider,
            ),
            itemBuilder: (_, i) {
              if (i == ctrl.videos.length) {
                // load-more sentinel
                ctrl.loadMore();
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_kDark),
                    ),
                  ),
                );
              }
              return VideoListTile(
                video: ctrl.videos[i],
                onTap: () => _openVideo(ctrl.videos[i]),
              );
            },
          ),
        ),
      );
    });
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  VIDEO LIST TILE  (mirrors ArticleListTile + YouTube icon)
// ═════════════════════════════════════════════════════════════════════════════

class VideoListTile extends StatelessWidget {
  final Video video;
  final VoidCallback? onTap;

  const VideoListTile({Key? key, required this.video, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail with overlays ──────────────────────────────────
            _Thumbnail(video: video),
            const SizedBox(width: 14),

            // ── Text info ────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kDark,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Meta row: duration · views · YouTube icon
                  Row(
                    children: [
                      // Duration
                      if (video.duration != null) ...[
                        const Icon(Icons.schedule_rounded,
                            size: 12, color: _kSubtext),
                        const SizedBox(width: 3),
                        Text(
                          video.duration!,
                          style: GoogleFonts.montserrat(
                              fontSize: 11.5, color: _kSubtext),
                        ),
                        const SizedBox(width: 12),
                      ],

                      // Views
                      const Icon(Icons.remove_red_eye_outlined,
                          size: 12, color: _kSubtext),
                      const SizedBox(width: 3),
                      Text(
                        '${_formatViews(video.viewCount)} views',
                        style: GoogleFonts.montserrat(
                            fontSize: 11.5, color: _kSubtext),
                      ),

                      const Spacer(),

                      // YouTube icon badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kYT,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_arrow_rounded,
                                size: 11, color: Colors.white),
                            const SizedBox(width: 2),
                            Text(
                              'YouTube',
                              style: GoogleFonts.montserrat(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Category chip (optional)
                  if (video.category != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      video.category!.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: _kBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  THUMBNAIL  76×76 with play overlay + duration badge
// ─────────────────────────────────────────────────────────────────────────────

class _Thumbnail extends StatelessWidget {
  final Video video;
  const _Thumbnail({required this.video});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 76,
        height: 76,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            _buildImage(),

            // Semi-dark overlay for legibility
            Container(color: Colors.black.withValues(alpha: 0.10)),

            // Play circle centre
            Center(
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 17),
              ),
            ),

            // Duration badge — bottom-right
            if (video.duration != null)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    video.duration!,
                    style: GoogleFonts.montserrat(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return NetImage(
      url: video.thumbnailUrl,
      fit: BoxFit.cover,
      placeholderColor: const Color(0xFFEEEEF5),
      placeholderIcon: Icons.videocam_rounded,
      placeholderIconColor: const Color(0xFFCCCCDD),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  FILTER BOTTOM SHEET
// ═════════════════════════════════════════════════════════════════════════════

void _showFilterSheet(BuildContext context, VideosController ctrl) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _FilterSheet(ctrl: ctrl),
  );
}

class _FilterSheet extends StatelessWidget {
  final VideosController ctrl;
  const _FilterSheet({required this.ctrl});

  static const _kSheetDark    = Color(0xFF111827);
  static const _kSheetSubtext = Color(0xFF9CA3AF);
  static const _kSheetDivider = Color(0xFFF3F4F6);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final maxHeight   = MediaQuery.of(context).size.height * 0.75;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fixed header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filter by Category',
                          style: GoogleFonts.montserrat(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _kSheetDark)),
                      Obx(() => ctrl.selectedCategoryId.value != null
                          ? GestureDetector(
                              onTap: () {
                                ctrl.selectCategory(null);
                                Navigator.pop(context);
                              },
                              child: Text('Clear',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _kBlue)),
                            )
                          : const SizedBox.shrink()),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Choose a topic to filter videos',
                      style: GoogleFonts.montserrat(
                          fontSize: 12.5, color: _kSheetSubtext)),
                  const SizedBox(height: 16),
                  const Divider(color: _kSheetDivider, height: 1),
                ],
              ),
            ),

            // ── Scrollable options ─────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 8, 24, bottomInset + 24),
                child: Obx(() {
                  final cats = ctrl.categories;
                  return Column(
                    children: [
                      _FilterOption(
                        label: 'All Categories',
                        icon: Icons.grid_view_rounded,
                        isSelected: ctrl.selectedCategoryId.value == null,
                        onTap: () {
                          ctrl.selectCategory(null);
                          Navigator.pop(context);
                        },
                      ),
                      if (cats.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text('No categories available',
                                style: GoogleFonts.montserrat(
                                    fontSize: 13, color: _kSheetSubtext)),
                          ),
                        )
                      else
                        ...cats.map((cat) => _FilterOption(
                              label: cat.name,
                              icon: _categoryIcon(cat.name),
                              isSelected:
                                  ctrl.selectedCategoryId.value == cat.id,
                              onTap: () {
                                ctrl.selectCategory(cat.id);
                                Navigator.pop(context);
                              },
                            )),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String name) {
    final s = name.toLowerCase();
    if (s.contains('infrastructure') || s.contains('transport')) return Icons.account_balance_rounded;
    if (s.contains('real') || s.contains('estate') || s.contains('property')) return Icons.home_work_rounded;
    if (s.contains('safety') || s.contains('regulation')) return Icons.health_and_safety_rounded;
    if (s.contains('material') || s.contains('technology')) return Icons.science_rounded;
    if (s.contains('urban') || s.contains('planning')) return Icons.location_city_rounded;
    if (s.contains('road') || s.contains('highway')) return Icons.add_road_rounded;
    if (s.contains('government') || s.contains('policy')) return Icons.gavel_rounded;
    if (s.contains('construction') || s.contains('project')) return Icons.construction_rounded;
    if (s.contains('tip') || s.contains('guide')) return Icons.lightbulb_rounded;
    return Icons.play_circle_outline_rounded;
  }
}

class _FilterOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _kBlue.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _kBlue : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: isSelected ? _kBlue : const Color(0xFF6B7280)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? _kBlue : const Color(0xFF111827),
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, size: 18, color: _kBlue),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────────────────────

void _openVideo(video) {
  if (kIsWeb) {
    _launchYouTube(video.youtubeUrl);
  } else {
    Get.to(
      () => VideoPlayerScreen(video: video),
      transition: Transition.cupertino,
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
