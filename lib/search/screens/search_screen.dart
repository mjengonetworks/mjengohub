// lib/search/screens/search_screen.dart
//
// Global, multi-category search with debounced queries.
//
// Two sources are merged, because neither covers everything:
//   * `GET /search` (SearchService) — articles, services and infrastructure
//     reports, in one round trip.
//   * per-feature endpoints — `/projects` and `/incidents`, which the unified
//     route deliberately doesn't touch.
//
// Filters are applied per source so an unticked category costs no request.
// The old "Events" filter has been dropped: the website's events live only as
// HTML routes with no `/api/v1` equivalent, so it could never return results.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../incidents/models/incident_model.dart';
import '../../incidents/services/incidents_service.dart';
import '../../navigation/app_header.dart';
import '../../news/models/article_model.dart';
import '../../news/services/news_api_service.dart';
import '../../point/routes/app_routes.dart';
import '../../projects/models/project_model.dart';
import '../../projects/screens/project_detail_screen.dart';
import '../../projects/services/projects_service.dart';
import '../../reports/models/report_model.dart';
import '../../service_catalog/models/service_model.dart';
import '../../shared/theme/app_theme.dart';
import '../services/search_service.dart';

enum _SearchCategory {
  articles,
  news,
  projects,
  safetyIncidents,
  services,
  reports,
}

extension on _SearchCategory {
  String get label {
    switch (this) {
      case _SearchCategory.articles: return 'Articles';
      case _SearchCategory.news: return 'News';
      case _SearchCategory.projects: return 'Projects';
      case _SearchCategory.safetyIncidents: return 'Safety Incidents';
      case _SearchCategory.services: return 'Services';
      case _SearchCategory.reports: return 'Reports';
    }
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _newsApi = NewsApiService();
  final _projectsApi = ProjectsService();
  final _incidentsApi = IncidentsService();
  final _searchApi = SearchService();

  final _controller = TextEditingController();
  Timer? _debounce;

  final Set<_SearchCategory> _activeFilters = {
    _SearchCategory.articles,
    _SearchCategory.news,
    _SearchCategory.projects,
    _SearchCategory.safetyIncidents,
    _SearchCategory.services,
    _SearchCategory.reports,
  };

  bool _loading = false;
  String _query = '';
  List<Article> _articles = [];
  List<Article> _news = [];
  List<Project> _projects = [];
  List<Incident> _incidents = [];
  List<ServiceOffering> _services = [];
  List<InfrastructureReport> _reports = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _runSearch(value));
  }

  Future<void> _runSearch(String q) async {
    final trimmed = q.trim();
    setState(() => _query = trimmed);
    if (trimmed.length < 2) {
      setState(() {
        _articles = [];
        _news = [];
        _projects = [];
        _incidents = [];
        _services = [];
        _reports = [];
      });
      return;
    }

    setState(() => _loading = true);

    final futures = <Future>[];
    Future<List<Article>> articlesFuture = Future.value([]);
    Future<List<Project>> projectsFuture = Future.value([]);
    Future<List<Incident>> incidentsRoadFuture = Future.value([]);
    Future<List<Incident>> incidentsSiteFuture = Future.value([]);
    Future<UnifiedSearchResults> unifiedFuture =
        Future.value(const UnifiedSearchResults());

    if (_activeFilters.contains(_SearchCategory.articles) || _activeFilters.contains(_SearchCategory.news)) {
      articlesFuture = _newsApi.getArticles(q: trimmed, perPage: 20);
      futures.add(articlesFuture);
    }
    // One call covers both services and reports, so only fire it once.
    if (_activeFilters.contains(_SearchCategory.services) ||
        _activeFilters.contains(_SearchCategory.reports)) {
      unifiedFuture = _searchApi.search(trimmed);
      futures.add(unifiedFuture);
    }
    if (_activeFilters.contains(_SearchCategory.projects)) {
      projectsFuture = _projectsApi.getProjects(q: trimmed, perPage: 20);
      futures.add(projectsFuture);
    }
    if (_activeFilters.contains(_SearchCategory.safetyIncidents)) {
      incidentsRoadFuture = _incidentsApi.getIncidents(type: 'road_safety', q: trimmed, perPage: 15);
      incidentsSiteFuture = _incidentsApi.getIncidents(type: 'site_safety', q: trimmed, perPage: 15);
      futures.addAll([incidentsRoadFuture, incidentsSiteFuture]);
    }

    await Future.wait(futures);
    if (!mounted) return;

    final allArticles = await articlesFuture;
    final projectResults = await projectsFuture;
    final roadIncidents = await incidentsRoadFuture;
    final siteIncidents = await incidentsSiteFuture;
    final unified = await unifiedFuture;

    setState(() {
      _articles = _activeFilters.contains(_SearchCategory.articles) ? allArticles : [];
      _news = _activeFilters.contains(_SearchCategory.news)
          ? allArticles.where((a) => a.isBreaking).toList()
          : [];
      _projects = projectResults;
      _incidents = [...roadIncidents, ...siteIncidents];
      _services =
          _activeFilters.contains(_SearchCategory.services) ? unified.services : [];
      _reports =
          _activeFilters.contains(_SearchCategory.reports) ? unified.reports : [];
      _loading = false;
    });
  }

  void _toggleFilter(_SearchCategory cat) {
    setState(() {
      if (_activeFilters.contains(cat)) {
        _activeFilters.remove(cat);
      } else {
        _activeFilters.add(cat);
      }
    });
    if (_query.length >= 2) _runSearch(_query);
  }

  int get _totalResults =>
      _articles.length +
      _news.length +
      _projects.length +
      _incidents.length +
      _services.length +
      _reports.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AppHeader(),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          onChanged: _onChanged,
                          style: GoogleFonts.montserrat(fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText: 'Search MjengoHub…',
                            hintStyle: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSubtle),
                            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSubtle),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _SearchCategory.values
                        .map((c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _FilterChip(
                                label: c.label,
                                selected: _activeFilters.contains(c),
                                onTap: () => _toggleFilter(c),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_query.length < 2) {
      return Center(
        child: Text('Search articles, projects, services & safety reports',
            style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSubtle)),
      );
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentBlue));
    }
    if (_totalResults == 0) {
      return Center(
        child: Text('No results for "$_query"', style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSubtle)),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (_articles.isNotEmpty) _section('Articles', _articles.map((a) => _ArticleRow(a)).toList()),
        if (_news.isNotEmpty) _section('News', _news.map((a) => _ArticleRow(a)).toList()),
        if (_projects.isNotEmpty) _section('Projects', _projects.map((p) => _ProjectRow(p)).toList()),
        if (_incidents.isNotEmpty) _section('Safety Incidents', _incidents.map((i) => _IncidentRow(i)).toList()),
        if (_services.isNotEmpty) _section('Services', _services.map((s) => _ServiceRow(s)).toList()),
        if (_reports.isNotEmpty) _section('Reports', _reports.map((r) => _ReportRow(r)).toList()),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
            child: Text(title, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSubtle, letterSpacing: 0.4)),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentBlue : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.accentBlue : AppColors.divider),
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textSubtle)),
        ),
      ),
    );
  }
}

class _ArticleRow extends StatelessWidget {
  final Article article;
  const _ArticleRow(this.article);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.article_rounded, color: AppColors.accentBlue),
      title: Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: article.category != null ? Text(article.category!.name, style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.textSubtle)) : null,
      onTap: () => Get.toNamed(AppRoutes.articleDetail, arguments: article.slug),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  final Project project;
  const _ProjectRow(this.project);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.corporate_fare_rounded, color: AppColors.accentBlue),
      title: Text(project.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(project.county ?? project.location ?? '', style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.textSubtle)),
      onTap: () => Get.to(() => ProjectDetailScreen(slug: project.slug), transition: Transition.cupertino),
    );
  }
}

class _IncidentRow extends StatelessWidget {
  final Incident incident;
  const _IncidentRow(this.incident);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.report_problem_rounded, color: AppColors.danger),
      title: Text(incident.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(incident.county ?? incident.location ?? '', style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.textSubtle)),
      onTap: () => Get.toNamed(AppRoutes.incidentDetail, arguments: incident.slug),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final ServiceOffering service;
  const _ServiceRow(this.service);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.handyman_rounded, color: AppColors.primaryBlue),
      title: Text(service.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(service.description ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.textSubtle)),
      onTap: () => Get.toNamed(AppRoutes.serviceDetail, arguments: service.slug),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final InfrastructureReport report;
  const _ReportRow(this.report);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.construction_rounded, color: AppColors.warning),
      title: Text(report.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(report.location ?? '',
          style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.textSubtle)),
      onTap: () => Get.toNamed(AppRoutes.reportDetail, arguments: report.id),
    );
  }
}
