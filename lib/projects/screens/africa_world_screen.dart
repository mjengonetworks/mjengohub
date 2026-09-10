// lib/projects/screens/africa_world_screen.dart
//
// Africa & World showcase — curated international entries (same Project
// rows as every other tracker, Project.geo_scope='global', per models.py's
// own comment on that column). Continent tab bar matches the web's
// REGION_CHOICES exactly (application.py's africa_world_list()), East
// Africa first. There is no separate "sector" taxonomy for this tracker
// server-side (only region) — application.py's africa_world_list() route
// filters by region/country/status/q only, so this screen doesn't fabricate
// sector chips that wouldn't actually filter anything.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../news/widgets/net_image.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/responsive.dart';
import '../models/project_model.dart';
import '../services/projects_service.dart';
import '../widgets/tracker_dynamic_sections.dart';
import '../widgets/tracker_map_grid_section.dart';
import '../../shared/widgets/scroll_to_top_fab.dart';

const _kRegions = <String, String>{
  'east_africa': 'East Africa',
  'africa': 'Africa',
  'europe': 'Europe',
  'asia': 'Asia',
  'north_america': 'North America',
  'south_america': 'South America',
  'oceania': 'Oceania',
};

class AfricaWorldScreen extends StatefulWidget {
  const AfricaWorldScreen({super.key});

  @override
  State<AfricaWorldScreen> createState() => _AfricaWorldScreenState();
}

class _AfricaWorldScreenState extends State<AfricaWorldScreen>
    with SingleTickerProviderStateMixin {
  final _service = ProjectsService();
  final _scrollController = ScrollController();
  late final TabController _tabController;

  List<Project> _projects = [];
  bool _loading = true;

  static final _regionKeys = _kRegions.keys.toList();

  /// First loaded entry's photo backs the hero strip — there's no dedicated
  /// "featured pan-African project" endpoint, same pragmatic fallback used
  /// by BuiltHistoryScreen's hero strip.
  String? get _heroImageUrl =>
      _projects.isNotEmpty ? _projects.first.imageUrl : null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _regionKeys.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _load();
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final projects = await _service.getProjects(
      geoScope: 'global',
      region: _regionKeys[_tabController.index],
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
        title: Text(
          'Africa & World',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: AppColors.textDark,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.accentBlue,
          unselectedLabelColor: AppColors.textSubtle,
          indicatorColor: AppColors.accentBlue,
          labelStyle: GoogleFonts.montserrat(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.montserrat(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
          tabs: _regionKeys.map((k) => Tab(text: _kRegions[k])).toList(),
        ),
      ),
      body: ScrollToTopFab(
        controller: _scrollController,
        child: ContentWidth(
          maxWidth: 900,
          child: RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AfricaWorldHeroStrip(imageUrl: _heroImageUrl),
                  const SizedBox(height: 16),

                  // 1. Top interactive live map — the very first scrollable
                  // item, directly beneath the app bar (continent tabs live
                  // in the app bar itself). Never gated behind a toggle.
                  TrackerLiveMap(projects: _projects, loading: _loading),
                  const SizedBox(height: 24),

                  // 3-5. Browse by Category / Most Viewed / By Status
                  TrackerDynamicSections(geoScope: 'global'),

                  // 6. All entries grid for the selected region, mirrors
                  // africa_world.html's .aw-views.
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'All Entries in This Region',
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
                    captionOf: (p) => p.country ?? p.statusLabel,
                    emptyMessage:
                        'No Africa & World entries in this region yet.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Slim 150px hero strip, matching BuiltHistoryScreen's _HeroStrip — kept
/// local rather than shared since the two trackers' copy/imagery differ and
/// there's no third caller to justify extracting a shared widget yet.
class _AfricaWorldHeroStrip extends StatelessWidget {
  final String? imageUrl;
  const _AfricaWorldHeroStrip({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 150,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              NetImage(
                url: imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholderColor: AppColors.deepNavy,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xDE000000), Color(0x8A000000)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Africa & World Mega Projects',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cross-border transport corridors, energy grids, '
                      'and global engineering',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
