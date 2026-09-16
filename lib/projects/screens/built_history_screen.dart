// lib/projects/screens/built_history_screen.dart
//
// Built History archive — Project rows with is_built_history=True (same
// Project model as every other tracker, just filtered/labeled differently,
// per models.py's own comment on that column). Decade + ownership filter
// chips mirror the web's built_history_list() exactly (application.py),
// including the same DECADE_CHOICES/HERITAGE_CATEGORY_CHOICES/ownership
// values. "From the Archives" pulls articles tagged category='built-history'
// via the existing GET /articles?category= filter (same mechanism
// CLAUDE.md documents for the Jobs/Tenders category filters).
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../news/models/article_model.dart';
import '../../news/services/news_api_service.dart';
import '../../news/widgets/net_image.dart';
import '../../point/routes/app_routes.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/responsive.dart';
import '../models/project_model.dart';
import '../services/projects_service.dart';
import '../widgets/tracker_dynamic_sections.dart';
import '../widgets/tracker_hero_section.dart';
import '../widgets/tracker_map_grid_section.dart';
import '../../shared/widgets/scroll_to_top_fab.dart';

const _kDecades = [
  'pre-1960s',
  '1960s',
  '1970s',
  '1980s',
  '1990s',
  '2000s',
  '2010s',
  '2020s+',
];

String _decadeLabel(String d) => d == 'pre-1960s'
    ? 'Pre-1960s'
    : d == '2020s+'
    ? '2020s+'
    : d;

enum _SortBy {
  newest('Newest'),
  recentlyUpdated('Recently Updated'),
  budgetHighToLow('Budget: High to Low');

  final String label;
  const _SortBy(this.label);
}

class BuiltHistoryScreen extends StatefulWidget {
  const BuiltHistoryScreen({super.key});

  @override
  State<BuiltHistoryScreen> createState() => _BuiltHistoryScreenState();
}

class _BuiltHistoryScreenState extends State<BuiltHistoryScreen> {
  final _projectsService = ProjectsService();
  final _newsService = NewsApiService();
  final _scrollController = ScrollController();

  String? _decade;
  String _ownership = 'all'; // 'all' | 'public' | 'private'

  /// No server-side sort param on `built_history_list()`, so "Sort By" is a
  /// client-side sort of the already-loaded page — applied in [_applySort],
  /// re-run after every fetch and whenever the user changes it.
  _SortBy _sortBy = _SortBy.newest;

  void _applySort() {
    switch (_sortBy) {
      case _SortBy.newest:
        _projects.sort(
          (a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''),
        );
        break;
      case _SortBy.recentlyUpdated:
        _projects.sort((a, b) {
          final au = a.updatedAt ?? DateTime.tryParse(a.createdAt ?? '');
          final bu = b.updatedAt ?? DateTime.tryParse(b.createdAt ?? '');
          if (au == null && bu == null) return 0;
          if (au == null) return 1;
          if (bu == null) return -1;
          return bu.compareTo(au);
        });
        break;
      case _SortBy.budgetHighToLow:
        _projects.sort((a, b) => (b.costKes ?? 0).compareTo(a.costKes ?? 0));
        break;
    }
  }

  /// Tracker-scoped search term from the hero's "Quick Search" field.
  String _query = '';

  List<Project> _projects = [];
  List<Article> _archiveArticles = [];
  bool _loading = true;

  /// Top 5 featured (falling back to top loaded) entries feed the hero
  /// carousel — there's no dedicated "featured heritage image" endpoint,
  /// same pragmatic fallback used elsewhere for unconfirmed/uncapped totals.
  List<Project> get _featuredProjects {
    final featured = _projects.where((p) => p.isFeatured).toList();
    return (featured.isNotEmpty ? featured : _projects).take(5).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadArchives();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadArchives() async {
    final articles = await _newsService.getArticles(
      categorySlug: 'built-history',
      perPage: 8,
    );
    if (mounted) setState(() => _archiveArticles = articles);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final projects = await _projectsService.getProjects(
      isBuiltHistory: true,
      completionDecade: _decade,
      ownershipType: _ownership == 'all' ? null : _ownership,
      q: _query.isEmpty ? null : _query,
      perPage: 40,
    );
    if (!mounted) return;
    setState(() {
      _projects = projects;
      _applySort();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        title: Text(
          'Built History',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: ScrollToTopFab(
        controller: _scrollController,
        child: ContentWidth(
          maxWidth: 900,
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                const SizedBox(height: 12),
                TrackerHeroSection(
                  title: 'Built History & Architectural Heritage',
                  subtitle:
                      'Landmark structures and historic urban architecture',
                  featuredProjects: _featuredProjects,
                  submitProjectType: 'built_history',
                  searchHint: 'Search Built History entries…',
                  onSearch: (q) {
                    setState(() => _query = q.trim());
                    _load();
                  },
                  onSubmitted: _load,
                ),
                const SizedBox(height: 16),

                // Dedicated tracker control — ownership + decade chips, plus
                // Sort By — the explicit filter bar, directly above the
                // list/grid feed (list-first, not map-dominated).
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip(
                        'All',
                        _ownership == 'all',
                        () => setState(() {
                          _ownership = 'all';
                          _load();
                        }),
                      ),
                      _chip(
                        'Public Heritage',
                        _ownership == 'public',
                        () => setState(() {
                          _ownership = 'public';
                          _load();
                        }),
                      ),
                      _chip(
                        'Private Heritage',
                        _ownership == 'private',
                        () => setState(() {
                          _ownership = 'private';
                          _load();
                        }),
                      ),
                      GestureDetector(
                        onTap: _showSortSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.sort_rounded,
                                size: 15,
                                color: AppColors.textSubtle,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Sort: ${_sortBy.label}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSubtle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _kDecades.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      if (i == 0)
                        return _chip(
                          'All Decades',
                          _decade == null,
                          () => setState(() {
                            _decade = null;
                            _load();
                          }),
                        );
                      final d = _kDecades[i - 1];
                      return _chip(
                        _decadeLabel(d),
                        _decade == d,
                        () => setState(() {
                          _decade = d;
                          _load();
                        }),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // From the Archives — after the map/controls, before the
                // bottom Browse/Most Viewed/Status sections ─────────────────
                if (_archiveArticles.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'From the Archives',
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _archiveArticles.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final a = _archiveArticles[i];
                        return GestureDetector(
                          onTap: () => Get.toNamed(
                            AppRoutes.articleDetail,
                            arguments: a.slug,
                          ),
                          child: Container(
                            width: 160,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AspectRatio(
                                  aspectRatio: 4 / 3,
                                  child: NetImage(
                                    url: a.imageUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    a.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // 3-5. Browse by Category / Most Viewed / By Status
                const SizedBox(height: 24),
                const TrackerDynamicSections(isBuiltHistory: true),

                // 6. All entries grid, mirrors built_history.html's .bh-views
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'All Built History Entries',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TrackerProjectsWrapGrid(
                  projects: _projects,
                  loading: _loading,
                  captionOf: (p) => p.completionDecade ?? p.statusLabel,
                  emptyMessage: 'No Built History entries match this filter.',
                ),

                // Interactive live map — moved below the primary feed so the
                // list/grid is the default view, matching the website.
                const SizedBox(height: 20),
                TrackerLiveMap(projects: _projects, loading: _loading),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSortSheet() async {
    final selected = await showModalBottomSheet<_SortBy>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Sort By',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
            for (final option in _SortBy.values)
              ListTile(
                title: Text(
                  option.label,
                  style: GoogleFonts.montserrat(fontSize: 13.5),
                ),
                trailing: _sortBy == option
                    ? const Icon(Icons.check, color: AppColors.accentBlue)
                    : null,
                onTap: () => Navigator.pop(sheetContext, option),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _sortBy = selected;
      _applySort();
    });
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentBlue : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.accentBlue : AppColors.divider,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : AppColors.textSubtle,
            ),
          ),
        ),
      );
}
