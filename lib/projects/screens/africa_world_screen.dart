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

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/responsive.dart';
import '../models/project_model.dart';
import '../services/projects_service.dart';
import '../widgets/projects_map_view.dart' show kAfricaMapCenter;
import '../widgets/tracker_dynamic_sections.dart';
import '../widgets/tracker_hero_carousel.dart';
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

  List<Project> _allProjects = [];
  bool _loading = true;

  /// No server-side single-country query param exists (`application.py`'s
  /// africa_world_list() only filters by region/country/status/q as a
  /// combined search term server-side, per this file's own header comment,
  /// and `ProjectsService.getProjects` has no dedicated `country` param) —
  /// same "client-side over already-loaded rows" pattern as
  /// `BuildingsTaxonomy` on the Private Projects tracker. Country options
  /// are derived from the currently-loaded region's rows, never hardcoded,
  /// so this degrades gracefully as new countries appear in the data.
  String? _country;

  List<Project> get _projects => _country == null
      ? _allProjects
      : _allProjects.where((p) => p.country == _country).toList();

  List<String> get _availableCountries =>
      _allProjects.map((p) => p.country).whereType<String>().toSet().toList()
        ..sort();

  static final _regionKeys = _kRegions.keys.toList();

  /// Top 5 loaded entries' photos rotate through the hero carousel — there's
  /// no dedicated "featured pan-African project" endpoint, same pragmatic
  /// fallback used by BuiltHistoryScreen's hero carousel.
  List<String> get _heroImageUrls => _projects
      .map((p) => p.imageUrl)
      .whereType<String>()
      .toSet()
      .take(5)
      .toList();

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
      _allProjects = projects;
      // A country selected under one region may not exist in another —
      // drop it rather than silently filtering to an empty grid.
      if (_country != null && !_availableCountries.contains(_country)) {
        _country = null;
      }
      _loading = false;
    });
  }

  Future<void> _showCountrySheet() async {
    final options = _availableCountries;
    final selected = await showModalBottomSheet<String?>(
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
                'Select Country',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
            ListTile(
              title: Text(
                'All Countries',
                style: GoogleFonts.montserrat(fontSize: 13.5),
              ),
              trailing: _country == null
                  ? const Icon(Icons.check, color: AppColors.accentBlue)
                  : null,
              onTap: () => Navigator.pop(sheetContext, ''),
            ),
            if (options.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  'No countries in this region yet.',
                  style: GoogleFonts.montserrat(
                    fontSize: 12.5,
                    color: AppColors.textSubtle,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final country in options)
                      ListTile(
                        title: Text(
                          country,
                          style: GoogleFonts.montserrat(fontSize: 13.5),
                        ),
                        trailing: _country == country
                            ? const Icon(
                                Icons.check,
                                color: AppColors.accentBlue,
                              )
                            : null,
                        onTap: () => Navigator.pop(sheetContext, country),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _country = selected.isEmpty ? null : selected);
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
              padding: const EdgeInsets.only(top: 16, bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TrackerHeroCarousel(
                    title: 'Africa & World Mega Projects',
                    subtitle:
                        'Tracking landmark mega-developments, engineering '
                        'marvels, and iconic architectural builds across '
                        'Africa and around the globe.',
                    imageUrls: _heroImageUrls,
                  ),
                  const SizedBox(height: 16),

                  // 1. Top interactive live map — the very first scrollable
                  // item, directly beneath the app bar (continent tabs live
                  // in the app bar itself). Never gated behind a toggle.
                  TrackerLiveMap(
                    projects: _projects,
                    loading: _loading,
                    defaultCenter: kAfricaMapCenter,
                  ),
                  const SizedBox(height: 16),

                  // Geographic scope is 'global' here (Africa/World), so the
                  // Country selector applies — mirrors the web's
                  // Kenya-scope-shows-county / global-scope-shows-country
                  // logic (ProjectsScreen's Kenya-scoped trackers show only
                  // a County selector, never Country; this screen is the
                  // reverse and never shows County).
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: _showCountrySheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.public_rounded,
                              size: 18,
                              color: AppColors.textSubtle,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Country: ${_country ?? 'All Countries'}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: AppColors.textSubtle,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

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
