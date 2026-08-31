// lib/search/screens/search_screen.dart
//
// Global, multi-category search — Articles, News, Public Projects, Private
// Projects, Safety Incidents, Events — with debounced queries against the
// existing per-feature endpoints (there is no single unified `/search`
// JSON endpoint on the backend yet, see the cross-repo audit, so this fans
// out to `/articles`, `/projects`, `/incidents` in parallel per filter).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../incidents/models/incident_model.dart';
import '../../incidents/services/incidents_service.dart';
import '../../news/models/article_model.dart';
import '../../news/services/news_api_service.dart';
import '../../point/routes/app_routes.dart';
import '../../projects/models/project_model.dart';
import '../../projects/screens/project_detail_screen.dart';
import '../../projects/services/projects_service.dart';
import '../../shared/theme/app_theme.dart';

enum _SearchCategory { articles, news, publicProjects, privateProjects, safetyIncidents, events }

extension on _SearchCategory {
  String get label {
    switch (this) {
      case _SearchCategory.articles: return 'Articles';
      case _SearchCategory.news: return 'News';
      case _SearchCategory.publicProjects: return 'Public Projects';
      case _SearchCategory.privateProjects: return 'Private Projects';
      case _SearchCategory.safetyIncidents: return 'Safety Incidents';
      case _SearchCategory.events: return 'Events';
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

  final _controller = TextEditingController();
  Timer? _debounce;

  final Set<_SearchCategory> _activeFilters = {
    _SearchCategory.articles,
    _SearchCategory.news,
    _SearchCategory.publicProjects,
    _SearchCategory.privateProjects,
    _SearchCategory.safetyIncidents,
    _SearchCategory.events,
  };

  bool _loading = false;
  String _query = '';
  List<Article> _articles = [];
  List<Article> _news = [];
  List<Project> _publicProjects = [];
  List<Project> _privateProjects = [];
  List<Incident> _incidents = [];

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
        _publicProjects = [];
        _privateProjects = [];
        _incidents = [];
      });
      return;
    }

    setState(() => _loading = true);

    final futures = <Future>[];
    Future<List<Article>> articlesFuture = Future.value([]);
    Future<List<Project>> publicFuture = Future.value([]);
    Future<List<Project>> privateFuture = Future.value([]);
    Future<List<Incident>> incidentsRoadFuture = Future.value([]);
    Future<List<Incident>> incidentsSiteFuture = Future.value([]);

    if (_activeFilters.contains(_SearchCategory.articles) || _activeFilters.contains(_SearchCategory.news)) {
      articlesFuture = _newsApi.getArticles(q: trimmed, perPage: 20);
      futures.add(articlesFuture);
    }
    if (_activeFilters.contains(_SearchCategory.publicProjects)) {
      publicFuture = _projectsApi.getPublicProjects(q: trimmed, perPage: 20);
      futures.add(publicFuture);
    }
    if (_activeFilters.contains(_SearchCategory.privateProjects)) {
      privateFuture = _projectsApi.getPrivateProjects(q: trimmed, perPage: 20);
      futures.add(privateFuture);
    }
    if (_activeFilters.contains(_SearchCategory.safetyIncidents)) {
      incidentsRoadFuture = _incidentsApi.getIncidents(type: 'road_safety', q: trimmed, perPage: 15);
      incidentsSiteFuture = _incidentsApi.getIncidents(type: 'site_safety', q: trimmed, perPage: 15);
      futures.addAll([incidentsRoadFuture, incidentsSiteFuture]);
    }

    await Future.wait(futures);
    if (!mounted) return;

    final allArticles = await articlesFuture;
    final publicResults = await publicFuture;
    final privateResults = await privateFuture;
    final roadIncidents = await incidentsRoadFuture;
    final siteIncidents = await incidentsSiteFuture;

    setState(() {
      _articles = _activeFilters.contains(_SearchCategory.articles) ? allArticles : [];
      _news = _activeFilters.contains(_SearchCategory.news)
          ? allArticles.where((a) => a.isBreaking).toList()
          : [];
      _publicProjects = publicResults;
      _privateProjects = privateResults;
      _incidents = [...roadIncidents, ...siteIncidents];
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
      _articles.length + _news.length + _publicProjects.length + _privateProjects.length + _incidents.length;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 12),
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
        child: Text('Search articles, projects & safety incidents',
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
        if (_publicProjects.isNotEmpty) _section('Public Projects', _publicProjects.map((p) => _ProjectRow(p)).toList()),
        if (_privateProjects.isNotEmpty) _section('Private Projects', _privateProjects.map((p) => _ProjectRow(p)).toList()),
        if (_incidents.isNotEmpty) _section('Safety Incidents', _incidents.map((i) => _IncidentRow(i)).toList()),
        if (_activeFilters.contains(_SearchCategory.events))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text('Events search isn\'t available in the app yet — check the website.',
                style: GoogleFonts.montserrat(fontSize: 11.5, color: AppColors.textSubtle, fontStyle: FontStyle.italic)),
          ),
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
            child: Text(title, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSubtle, letterSpacing: 0.4)),
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
      leading: Icon(project.isPrivateProject ? Icons.apartment_rounded : Icons.corporate_fare_rounded, color: AppColors.accentBlue),
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
