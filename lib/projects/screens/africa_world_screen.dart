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
import '../../shared/widgets/coming_soon.dart';
import '../../shared/widgets/responsive.dart';
import '../models/project_model.dart';
import '../services/projects_service.dart';
import '../widgets/projects_map_view.dart';
import '../widgets/tracker_dynamic_sections.dart';
import '../widgets/tracker_project_card.dart';

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
  bool _showMap = false;

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
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list_rounded : Icons.map_rounded, color: AppColors.textDark),
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
        ],
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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _projects.isEmpty
                ? const ComingSoonPlaceholder(
                    icon: Icons.public_rounded,
                    title: 'Nothing here yet',
                    message: 'No Africa & World entries in this region yet.',
                  )
                : _showMap
                    ? ProjectsMapView(projects: _projects)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 16, bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: _projects.map((p) => TrackerProjectCard(project: p, captionOverride: p.country, width: 220)).toList(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TrackerDynamicSections(geoScope: 'global'),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }
}
