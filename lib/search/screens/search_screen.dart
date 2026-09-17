// lib/search/screens/search_screen.dart
//
// Global, multi-category search with debounced queries.
//
// Sources are merged client-side, because no single endpoint covers
// everything:
//   * `GET /search` (SearchService) — articles, services and infrastructure
//     reports, in one round trip. This endpoint's shape is unchanged
//     server-side (still `{articles, services, reports, query}`, no
//     pagination/type params) — see the per-category fetches below for how
//     Infrastructure/Private/Africa & World/Built History/Profiles are
//     actually sourced instead.
//   * `ProjectsService.getProjects(...)` — filtered independently by
//     `projectType`/`geoScope`/`isBuiltHistory` for the four project-based
//     categories, since `/search` doesn't touch `/projects` at all.
//   * `ProjectsService.getClients()` — filtered client-side by name for
//     "Profiles/Companies"; there is no `/search`-style query endpoint for
//     entities/clients on the live backend (`GET /entities?q=` 404s), so
//     this category degrades to "whatever's in the clients list that
//     matches" rather than a real server-side search.
//   * `/incidents`, which the unified route also doesn't touch.
//
// Filters are applied per source so an unticked category costs no request.
// The old "Events" filter has been dropped: the website's events live only as
// HTML routes with no `/api/v1` equivalent, so it could never return results.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../entities/screens/entity_profile_screen.dart';
import '../../incidents/models/incident_model.dart';
import '../../incidents/services/incidents_service.dart';
import '../../navigation/app_header.dart';
import '../../navigation/main_navigation.dart';
import '../../news/controllers/discover_controller.dart';
import '../../news/models/article_model.dart';
import '../../news/services/news_api_service.dart';
import '../../point/routes/app_routes.dart';
import '../../projects/models/project_model.dart';
import '../../projects/screens/project_detail_screen.dart';
import '../../projects/screens/tracker_filtered_list_screen.dart';
import '../../projects/services/projects_service.dart';
import '../../reports/models/report_model.dart';
import '../../service_catalog/models/service_model.dart';
import '../../shared/theme/app_theme.dart';
import '../services/search_service.dart';

enum _SearchCategory {
  articles,
  infrastructureProjects,
  privateDevelopments,
  africaWorld,
  builtHistory,
  profiles,
  news,
  safetyIncidents,
  services,
  reports,
}

extension on _SearchCategory {
  String get label {
    switch (this) {
      case _SearchCategory.articles:
        return 'Articles';
      case _SearchCategory.infrastructureProjects:
        return 'Infrastructure Projects';
      case _SearchCategory.privateDevelopments:
        return 'Private Developments';
      case _SearchCategory.africaWorld:
        return 'Africa & World';
      case _SearchCategory.builtHistory:
        return 'Built History';
      case _SearchCategory.profiles:
        return 'Profiles/Companies';
      case _SearchCategory.news:
        return 'News';
      case _SearchCategory.safetyIncidents:
        return 'Safety Incidents';
      case _SearchCategory.services:
        return 'Services';
      case _SearchCategory.reports:
        return 'Reports';
    }
  }
}

/// Splits an entity-style query like "China Road and Bridge Corporation
/// (CRBC)" into its full-name and acronym halves. A project's `contractor`
/// field usually stores just one half, so a single LIKE-style `q=` search
/// against the whole combined string can miss it — this lets the caller
/// fire one request per variant and merge the results instead.
List<String> _entityQueryVariants(String query) {
  final match = RegExp(
    r'^(.*?)\s*\(([A-Za-z0-9&.\-]{2,15})\)\s*$',
  ).firstMatch(query);
  if (match == null) return [query];
  final fullName = match.group(1)!.trim();
  final acronym = match.group(2)!.trim();
  final variants = <String>{query};
  if (fullName.isNotEmpty) variants.add(fullName);
  if (acronym.isNotEmpty) variants.add(acronym);
  return variants.toList();
}

/// Runs [call] once per [_entityQueryVariants] of [query] and merges the
/// results (deduped by project id), rather than a single verbatim search.
Future<List<Project>> _searchProjectsMerged(
  Future<List<Project>> Function(String q) call,
  String query,
) async {
  final variants = _entityQueryVariants(query);
  if (variants.length == 1) return call(variants.first);
  final results = await Future.wait(variants.map(call));
  final byId = <int, Project>{};
  for (final list in results) {
    for (final p in list) {
      byId[p.id] = p;
    }
  }
  return byId.values.toList();
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

  static const _allCategories = _SearchCategory.values;

  final Set<_SearchCategory> _activeFilters = {..._allCategories};

  bool get _allSelected => _activeFilters.length == _allCategories.length;

  bool _loading = false;
  String _query = '';
  List<Article> _articles = [];
  List<Article> _news = [];
  List<Project> _infraProjects = [];
  List<Project> _privateProjects = [];
  List<Project> _africaWorldProjects = [];
  List<Project> _builtHistoryProjects = [];
  List<ProjectClient> _profiles = [];
  List<Incident> _incidents = [];
  List<ServiceOffering> _services = [];
  List<InfrastructureReport> _reports = [];

  static const int _kSectionCap = 6;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _runSearch(value),
    );
  }

  Future<void> _runSearch(String q) async {
    final trimmed = q.trim();
    setState(() => _query = trimmed);
    if (trimmed.length < 2) {
      setState(() {
        _articles = [];
        _news = [];
        _infraProjects = [];
        _privateProjects = [];
        _africaWorldProjects = [];
        _builtHistoryProjects = [];
        _profiles = [];
        _incidents = [];
        _services = [];
        _reports = [];
      });
      return;
    }

    setState(() => _loading = true);

    final futures = <Future>[];
    Future<List<Article>> articlesFuture = Future.value([]);
    Future<List<Project>> infraFuture = Future.value([]);
    Future<List<Project>> privateFuture = Future.value([]);
    Future<List<Project>> africaWorldFuture = Future.value([]);
    Future<List<Project>> builtHistoryFuture = Future.value([]);
    Future<List<ProjectClient>> profilesFuture = Future.value([]);
    Future<List<Incident>> incidentsRoadFuture = Future.value([]);
    Future<List<Incident>> incidentsSiteFuture = Future.value([]);
    Future<UnifiedSearchResults> unifiedFuture = Future.value(
      const UnifiedSearchResults(),
    );

    if (_activeFilters.contains(_SearchCategory.articles) ||
        _activeFilters.contains(_SearchCategory.news)) {
      articlesFuture = _newsApi.getArticles(q: trimmed, perPage: 20);
      futures.add(articlesFuture);
    }
    // One call covers both services and reports, so only fire it once.
    if (_activeFilters.contains(_SearchCategory.services) ||
        _activeFilters.contains(_SearchCategory.reports)) {
      unifiedFuture = _searchApi.search(trimmed);
      futures.add(unifiedFuture);
    }
    if (_activeFilters.contains(_SearchCategory.infrastructureProjects)) {
      infraFuture = _searchProjectsMerged(
        (q) => _projectsApi.getProjects(
          projectType: 'infrastructure',
          q: q,
          perPage: 20,
        ),
        trimmed,
      );
      futures.add(infraFuture);
    }
    if (_activeFilters.contains(_SearchCategory.privateDevelopments)) {
      privateFuture = _searchProjectsMerged(
        (q) => _projectsApi.getProjects(
          projectType: 'private_development',
          q: q,
          perPage: 20,
        ),
        trimmed,
      );
      futures.add(privateFuture);
    }
    if (_activeFilters.contains(_SearchCategory.africaWorld)) {
      africaWorldFuture = _searchProjectsMerged(
        (q) => _projectsApi.getProjects(geoScope: 'global', q: q, perPage: 20),
        trimmed,
      );
      futures.add(africaWorldFuture);
    }
    if (_activeFilters.contains(_SearchCategory.builtHistory)) {
      builtHistoryFuture = _searchProjectsMerged(
        (q) =>
            _projectsApi.getProjects(isBuiltHistory: true, q: q, perPage: 20),
        trimmed,
      );
      futures.add(builtHistoryFuture);
    }
    if (_activeFilters.contains(_SearchCategory.profiles)) {
      // `GET /entities` has no query support and `/search` doesn't cover
      // clients/entities at all, so this matches client-side against the
      // full clients list rather than a real server-side search — see the
      // file header comment.
      profilesFuture = _projectsApi.getClients().then(
        (clients) => clients
            .where((c) => c.name.toLowerCase().contains(trimmed.toLowerCase()))
            .toList(),
      );
      futures.add(profilesFuture);
    }
    if (_activeFilters.contains(_SearchCategory.safetyIncidents)) {
      incidentsRoadFuture = _incidentsApi.getIncidents(
        type: 'road_safety',
        q: trimmed,
        perPage: 15,
      );
      incidentsSiteFuture = _incidentsApi.getIncidents(
        type: 'site_safety',
        q: trimmed,
        perPage: 15,
      );
      futures.addAll([incidentsRoadFuture, incidentsSiteFuture]);
    }

    await Future.wait(futures);
    if (!mounted) return;

    final allArticles = await articlesFuture;
    final infraResults = await infraFuture;
    final privateResults = await privateFuture;
    final africaWorldResults = await africaWorldFuture;
    final builtHistoryResults = await builtHistoryFuture;
    final profileResults = await profilesFuture;
    final roadIncidents = await incidentsRoadFuture;
    final siteIncidents = await incidentsSiteFuture;
    final unified = await unifiedFuture;

    setState(() {
      _articles = _activeFilters.contains(_SearchCategory.articles)
          ? allArticles
          : [];
      _news = _activeFilters.contains(_SearchCategory.news)
          ? allArticles.where((a) => a.isBreaking).toList()
          : [];
      _infraProjects = infraResults;
      _privateProjects = privateResults;
      _africaWorldProjects = africaWorldResults;
      _builtHistoryProjects = builtHistoryResults;
      _profiles = profileResults;
      _incidents = [...roadIncidents, ...siteIncidents];
      _services = _activeFilters.contains(_SearchCategory.services)
          ? unified.services
          : [];
      _reports = _activeFilters.contains(_SearchCategory.reports)
          ? unified.reports
          : [];
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

  void _selectAll() {
    setState(
      () => _activeFilters
        ..clear()
        ..addAll(_allCategories),
    );
    if (_query.length >= 2) _runSearch(_query);
  }

  int get _totalResults =>
      _articles.length +
      _news.length +
      _infraProjects.length +
      _privateProjects.length +
      _africaWorldProjects.length +
      _builtHistoryProjects.length +
      _profiles.length +
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
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: AppColors.textDark,
                      ),
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
                            hintStyle: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: AppColors.textSubtle,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: AppColors.textSubtle,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
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
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: 'All',
                          selected: _allSelected,
                          onTap: _selectAll,
                        ),
                      ),
                      ..._SearchCategory.values.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: c.label,
                            selected: _activeFilters.contains(c),
                            onTap: () => _toggleFilter(c),
                          ),
                        ),
                      ),
                    ],
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
        child: Text(
          'Search articles, infrastructure & private projects, '
          'Africa & World, Built History, profiles, services & reports',
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: AppColors.textSubtle,
          ),
        ),
      );
    }
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentBlue),
      );
    }
    if (_totalResults == 0) {
      return Center(
        child: Text(
          'No results for "$_query"',
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: AppColors.textSubtle,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Articles / Infrastructure Projects / Private Projects: capped to 3
        // rows with a "View All" row when there's more — sections with zero
        // results are omitted entirely (the `isNotEmpty` guards below), never
        // shown as an empty container.
        if (_articles.isNotEmpty)
          _cappedSection(
            'Articles',
            _articles,
            (a) => _ArticleRow(a),
            _viewAllArticles,
            buttonLabel: 'Read More',
          ),
        if (_infraProjects.isNotEmpty)
          _cappedSection(
            'Infrastructure Projects',
            _infraProjects,
            (p) => _ProjectRow(p),
            () => _viewAllProjects('infrastructure'),
            buttonLabel: 'View More',
          ),
        if (_privateProjects.isNotEmpty)
          _cappedSection(
            'Private Developments',
            _privateProjects,
            (p) => _ProjectRow(p),
            () => _viewAllProjects('private_development'),
            buttonLabel: 'View More',
          ),
        if (_africaWorldProjects.isNotEmpty)
          _cappedSection(
            'Africa & World',
            _africaWorldProjects,
            (p) => _ProjectRow(p),
            () => _viewAllProjectQuery(
              'Africa & World',
              (page) => ProjectsService().getProjects(
                geoScope: 'global',
                q: _query,
                page: page,
                perPage: 20,
              ),
            ),
            buttonLabel: 'View More',
          ),
        if (_builtHistoryProjects.isNotEmpty)
          _cappedSection(
            'Built History',
            _builtHistoryProjects,
            (p) => _ProjectRow(p),
            () => _viewAllProjectQuery(
              'Built History',
              (page) => ProjectsService().getProjects(
                isBuiltHistory: true,
                q: _query,
                page: page,
                perPage: 20,
              ),
            ),
            buttonLabel: 'View More',
          ),
        if (_profiles.isNotEmpty)
          _cappedSection(
            'Profiles/Companies',
            _profiles,
            (c) => _ProfileRow(c),
            _viewAllProfiles,
            buttonLabel: 'View More',
          ),
        if (_news.isNotEmpty)
          _section('News', _news.map((a) => _ArticleRow(a)).toList()),
        if (_incidents.isNotEmpty)
          _section(
            'Safety Incidents',
            _incidents.map((i) => _IncidentRow(i)).toList(),
          ),
        if (_services.isNotEmpty)
          _section('Services', _services.map((s) => _ServiceRow(s)).toList()),
        if (_reports.isNotEmpty)
          _section('Reports', _reports.map((r) => _ReportRow(r)).toList()),
      ],
    );
  }

  void _viewAllArticles() {
    final discover = Get.find<DiscoverController>();
    discover.searchController.text = _query;
    discover.onSearchSubmit(_query);
    Get.find<MainNavController>().currentIndex.value =
        MainNavController.tabNews;
  }

  void _viewAllProjects(String projectType) {
    final title = projectType == 'infrastructure'
        ? 'Infrastructure Projects'
        : 'Private Developments';
    _viewAllProjectQuery(
      title,
      (page) => ProjectsService().getProjects(
        projectType: projectType,
        q: _query,
        page: page,
        perPage: 20,
      ),
    );
  }

  void _viewAllProjectQuery(
    String title,
    Future<List<Project>> Function(int page) fetcher,
  ) {
    Get.to(
      () => TrackerFilteredListScreen(
        title: '$title · "$_query"',
        fetcher: fetcher,
        perPage: 20,
      ),
    );
  }

  /// No dedicated "Profiles" list screen exists — pushes a plain,
  /// locally-built list of the already-fetched client-side matches (see the
  /// header comment: there's no server-side entity/client search to paginate
  /// against, so "View More" here just shows the full match set rather than
  /// a further network fetch).
  void _viewAllProfiles() {
    Get.to(() => _ProfilesListScreen(query: _query, profiles: _profiles));
  }

  Widget _cappedSection<T>(
    String title,
    List<T> items,
    Widget Function(T) rowBuilder,
    VoidCallback onViewAll, {
    required String buttonLabel,
  }) {
    final shown = items.take(_kSectionCap).toList();
    return _section(
      '$title (${items.length})',
      shown.map(rowBuilder).toList(),
      trailing: items.length > _kSectionCap
          ? GestureDetector(
              onTap: onViewAll,
              child: Text(
                buttonLabel,
                style: GoogleFonts.montserrat(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentBlue,
                ),
              ),
            )
          : null,
    );
  }

  Widget _section(String title, List<Widget> children, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSubtle,
                    letterSpacing: 0.4,
                  ),
                ),
                ?trailing,
              ],
            ),
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
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
          border: Border.all(
            color: selected ? AppColors.accentBlue : AppColors.divider,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSubtle,
            ),
          ),
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
      title: Text(
        article.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: article.category != null
          ? Text(
              article.category!.name,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: AppColors.textSubtle,
              ),
            )
          : null,
      onTap: () =>
          Get.toNamed(AppRoutes.articleDetail, arguments: article.slug),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  final Project project;
  const _ProjectRow(this.project);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.corporate_fare_rounded,
        color: AppColors.accentBlue,
      ),
      title: Text(
        project.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        project.county ?? project.location ?? '',
        style: GoogleFonts.montserrat(
          fontSize: 11,
          color: AppColors.textSubtle,
        ),
      ),
      onTap: () => Get.to(
        () => ProjectDetailScreen(slug: project.slug),
        transition: Transition.cupertino,
      ),
    );
  }
}

class _IncidentRow extends StatelessWidget {
  final Incident incident;
  const _IncidentRow(this.incident);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.report_problem_rounded,
        color: AppColors.danger,
      ),
      title: Text(
        incident.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        incident.county ?? incident.location ?? '',
        style: GoogleFonts.montserrat(
          fontSize: 11,
          color: AppColors.textSubtle,
        ),
      ),
      onTap: () =>
          Get.toNamed(AppRoutes.incidentDetail, arguments: incident.slug),
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
      title: Text(
        service.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        service.description ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.montserrat(
          fontSize: 11,
          color: AppColors.textSubtle,
        ),
      ),
      onTap: () =>
          Get.toNamed(AppRoutes.serviceDetail, arguments: service.slug),
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
      title: Text(
        report.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        report.location ?? '',
        style: GoogleFonts.montserrat(
          fontSize: 11,
          color: AppColors.textSubtle,
        ),
      ),
      onTap: () => Get.toNamed(AppRoutes.reportDetail, arguments: report.id),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final ProjectClient client;
  const _ProfileRow(this.client);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.apartment_rounded,
        color: AppColors.primaryBlue,
      ),
      title: Text(
        client.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: client.clientType != null
          ? Text(
              client.clientType!,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: AppColors.textSubtle,
              ),
            )
          : null,
      onTap: () => Get.to(
        () => EntityProfileScreen(slug: client.slug, fallbackName: client.name),
      ),
    );
  }
}

/// Full-list destination for the "Profiles/Companies" category's View More —
/// there's no server-side pagination to fetch further pages from (see the
/// file header comment), so this just renders every client-side match
/// already found rather than triggering another network call.
class _ProfilesListScreen extends StatelessWidget {
  final String query;
  final List<ProjectClient> profiles;
  const _ProfilesListScreen({required this.query, required this.profiles});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        title: Text(
          'Profiles/Companies · "$query"',
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 32),
        itemCount: profiles.length,
        itemBuilder: (_, i) => _ProfileRow(profiles[i]),
      ),
    );
  }
}
