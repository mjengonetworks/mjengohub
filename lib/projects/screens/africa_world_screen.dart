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
import '../widgets/tracker_dynamic_sections.dart';
import '../widgets/tracker_map_grid_section.dart';

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

class _AfricaWorldScreenState extends State<AfricaWorldScreen> with SingleTickerProviderStateMixin {
  final _service = ProjectsService();
  late final TabController _tabController;

  List<Project> _projects = [];
  bool _loading = true;

  static final _regionKeys = _kRegions.keys.toList();

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
        title: Text('Africa & World', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textDark)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.accentBlue,
          unselectedLabelColor: AppColors.textSubtle,
          indicatorColor: AppColors.accentBlue,
          labelStyle: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w500),
          tabs: _regionKeys.map((k) => Tab(text: _kRegions[k])).toList(),
        ),
      ),
      body: ContentWidth(
        maxWidth: 900,
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grid/Map toggle + pane (live interactive map, color-coded
                // pins, tap-to-preview) — this IS the "all entries" feed for
                // the selected region, mirrors africa_world.html's .aw-views.
                TrackerMapGridSection(
                  projects: _projects,
                  loading: _loading,
                  captionOf: (p) => p.country ?? p.statusLabel,
                  emptyMessage: 'No Africa & World entries in this region yet.',
                ),
                const SizedBox(height: 24),
                TrackerDynamicSections(geoScope: 'global'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
