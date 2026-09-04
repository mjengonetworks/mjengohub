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
import '../widgets/tracker_map_grid_section.dart';

const _kDecades = ['pre-1960s', '1960s', '1970s', '1980s', '1990s', '2000s', '2010s', '2020s+'];

String _decadeLabel(String d) => d == 'pre-1960s' ? 'Pre-1960s' : d == '2020s+' ? '2020s+' : d;

class BuiltHistoryScreen extends StatefulWidget {
  const BuiltHistoryScreen({super.key});

  @override
  State<BuiltHistoryScreen> createState() => _BuiltHistoryScreenState();
}

class _BuiltHistoryScreenState extends State<BuiltHistoryScreen> {
  final _projectsService = ProjectsService();
  final _newsService = NewsApiService();

  String? _decade;
  String _ownership = 'all'; // 'all' | 'public' | 'private'

  List<Project> _projects = [];
  List<Article> _archiveArticles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadArchives();
    _load();
  }

  Future<void> _loadArchives() async {
    final articles = await _newsService.getArticles(categorySlug: 'built-history', perPage: 8);
    if (mounted) setState(() => _archiveArticles = articles);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final projects = await _projectsService.getProjects(
      isBuiltHistory: true,
      completionDecade: _decade,
      ownershipType: _ownership == 'all' ? null : _ownership,
      perPage: 40,
    );
    if (!mounted) return;
    setState(() {
      _projects = projects;
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
        title: Text('Built History', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textDark)),
      ),
      body: ContentWidth(
        maxWidth: 900,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const SizedBox(height: 12),

              // ── Ownership chips ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip('All', _ownership == 'all', () => setState(() { _ownership = 'all'; _load(); })),
                    _chip('Public Heritage', _ownership == 'public', () => setState(() { _ownership = 'public'; _load(); })),
                    _chip('Private Heritage', _ownership == 'private', () => setState(() { _ownership = 'private'; _load(); })),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Decade chips ─────────────────────────────────────────────
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _kDecades.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    if (i == 0) return _chip('All Decades', _decade == null, () => setState(() { _decade = null; _load(); }));
                    final d = _kDecades[i - 1];
                    return _chip(_decadeLabel(d), _decade == d, () => setState(() { _decade = d; _load(); }));
                  },
                ),
              ),
              const SizedBox(height: 20),

              // ── Top interactive live map (color-coded pins, tap-to-
              // preview), pinned above the grid ──────────────────────────
              TrackerLiveMap(projects: _projects, loading: _loading),
              const SizedBox(height: 20),

              // ── Grid — the "all entries" feed, mirrors
              // built_history.html's .bh-views ─────────────────────────
              TrackerProjectsWrapGrid(
                projects: _projects,
                loading: _loading,
                captionOf: (p) => p.completionDecade ?? p.statusLabel,
                emptyMessage: 'No Built History entries match this filter.',
              ),

              // ── From the Archives — after the grid/map, before the
              // bottom Browse/Most Viewed/Status sections ─────────────────
              if (_archiveArticles.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('From the Archives', style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _archiveArticles.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final a = _archiveArticles[i];
                      return GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.articleDetail, arguments: a.slug),
                        child: Container(
                          width: 160,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AspectRatio(aspectRatio: 16 / 9, child: NetImage(url: a.imageUrl, fit: BoxFit.cover)),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 24),
              const TrackerDynamicSections(isBuiltHistory: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentBlue : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? AppColors.accentBlue : AppColors.divider),
          ),
          child: Text(label,
              style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.textSubtle)),
        ),
      );
}
