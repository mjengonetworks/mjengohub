// lib/projects/widgets/tracker_hero_section.dart
//
// Standardized hero header shared by every tracker screen (Infrastructure,
// Private Projects, Africa & World, Built History) — a deep blue gradient
// panel (matches the website's --primary-blue/--secondary-blue tracker page
// headers, see AppColors.heroGradient) carrying the tracker's title/
// subtitle, a "+ Submit a Project" / "Quick Search" action row, and a
// swipeable featured-project carousel (thumbnail, status tag, title).
// "Quick Search" reveals an inline search field scoped to whichever tracker
// hosts this widget — [onSearch] is the caller's own filter/query call, so
// a search here never leaks across trackers.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../news/widgets/featured_article_card.dart' show PageDotIndicator;
import '../../news/widgets/net_image.dart';
import '../../point/routes/app_routes.dart';
import '../../shared/theme/app_theme.dart';
import '../models/project_model.dart';
import '../screens/project_detail_screen.dart';
import 'projects_map_view.dart' show statusMarkerColor;

class TrackerHeroSection extends StatefulWidget {
  final String title;
  final String subtitle;

  /// Slides for the featured carousel — hidden entirely when empty.
  final List<Project> featuredProjects;

  /// Passed straight through to `AppRoutes.submitProject` as `Get.arguments`
  /// so the submit form pre-selects the right tracker kind — one of
  /// `'infrastructure'`, `'private_development'`, `'built_history'`,
  /// `'africa_world'` (see `SubmitProjectScreen`'s `_TrackerKind` mapping).
  final String submitProjectType;

  /// Runs the tracker-scoped search — e.g. `ctrl.applyFilters(q: query)` or
  /// a local `setState` refetch — never a cross-tracker/global search.
  final ValueChanged<String> onSearch;

  final String searchHint;

  /// Called after a submission completes successfully, so the caller can
  /// refresh its own project list.
  final VoidCallback? onSubmitted;

  const TrackerHeroSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.featuredProjects,
    required this.onSearch,
    this.submitProjectType = 'infrastructure',
    this.searchHint = 'Search projects…',
    this.onSubmitted,
  });

  @override
  State<TrackerHeroSection> createState() => _TrackerHeroSectionState();
}

class _TrackerHeroSectionState extends State<TrackerHeroSection> {
  bool _searchOpen = false;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _pageController = PageController(viewportFraction: 0.86);
  int _page = 0;
  Timer? _autoplay;

  @override
  void initState() {
    super.initState();
    _armAutoplay();
  }

  @override
  void didUpdateWidget(covariant TrackerHeroSection old) {
    super.didUpdateWidget(old);
    if (old.featuredProjects.length != widget.featuredProjects.length) {
      _page = 0;
      _armAutoplay();
    }
  }

  void _armAutoplay() {
    _autoplay?.cancel();
    if (widget.featuredProjects.length <= 1) return;
    _autoplay = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_page + 1) % widget.featuredProjects.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoplay?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (_searchOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    }
  }

  Future<void> _submit() async {
    final submitted = await Get.toNamed(
      AppRoutes.submitProject,
      arguments: widget.submitProjectType,
    );
    if (submitted == true) widget.onSubmitted?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(fontSize: 12.5, color: Colors.white70),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '+ Submit a Project',
                  style: GoogleFonts.montserrat(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _toggleSearch,
                icon: Icon(
                  _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: Text(
                  'Quick Search',
                  style: GoogleFonts.montserrat(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onSubmitted: widget.onSearch,
                style: GoogleFonts.montserrat(fontSize: 13.5, color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  hintStyle: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.white60,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.12),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            crossFadeState: _searchOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          if (widget.featuredProjects.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 130,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.featuredProjects.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _FeaturedSlide(project: widget.featuredProjects[i]),
                ),
              ),
            ),
            if (widget.featuredProjects.length > 1) ...[
              const SizedBox(height: 8),
              Center(
                child: PageDotIndicator(
                  count: widget.featuredProjects.length,
                  current: _page,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _FeaturedSlide extends StatelessWidget {
  final Project project;
  const _FeaturedSlide({required this.project});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(
        () => ProjectDetailScreen(slug: project.slug),
        transition: Transition.cupertino,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 108,
              child: NetImage(
                url: project.imageUrl,
                fit: BoxFit.cover,
                placeholderColor: AppColors.deepNavy,
                placeholderIcon: Icons.apartment_rounded,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusMarkerColor(project.status),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        project.statusLabel.toUpperCase(),
                        style: GoogleFonts.montserrat(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      project.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
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
