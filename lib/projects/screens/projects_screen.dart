// lib/projects/screens/projects_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../news/widgets/net_image.dart';
import '../../point/routes/app_routes.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/text_case.dart';
import '../../shared/widgets/responsive.dart';
import '../controllers/projects_controller.dart';
import '../models/project_model.dart';
import '../models/tracker_sections_model.dart';
import '../services/projects_service.dart';
import '../widgets/tracker_hero_section.dart';
import '../widgets/tracker_map_grid_section.dart';
import 'project_detail_screen.dart';

/// Budget chip/badge tap -> Project Catalog filtered to that fixed
/// [BudgetTier] bracket. Mirrors ProjectDetailScreen's `_openBudgetTier`
/// (same targeted-instance-vs-push behavior); duplicated rather than shared
/// since each call site already has its own `Project` in scope.
void _openBudgetTier(Project project) {
  final tier = project.budgetTierBracket;
  if (tier == null) return;
  final route = project.projectType == 'private_development'
      ? AppRoutes.privateProjects
      : AppRoutes.projects;
  if (Get.isRegistered<ProjectsController>(tag: project.projectType)) {
    Get.find<ProjectsController>(
      tag: project.projectType,
    ).applyBudgetFilter(tier.min, tier.max);
    Get.until((r) => r.settings.name == route);
  } else {
    Get.toNamed(
      route,
      arguments: {'budgetMin': tier.min, 'budgetMax': ?tier.max},
    );
  }
}

const _kBlue = Color(0xFF2563EB);
const _kBg = Color(0xFFF0F4FF);
const _kDark = Color(0xFF1A1A2E);
const _kSubtext = Color(0xFF8888AA);
const _kDivider = Color(0xFFE2E8F0);
const _kCard = Colors.white;

/// "Buildings" hierarchy (Spec 3) — client-side display/filter layer only.
/// The backend has no category/subcategory column on `Project` at all today
/// (confirmed: only a single free-text `project_type`), so this can't be a
/// real server-side taxonomy. Matching is done by keyword against
/// title/summary/location, which is best-effort, not authoritative.
class BuildingsTaxonomy {
  BuildingsTaxonomy._();

  static const subcategories = [
    'Residential',
    'Commercial',
    'Mixed Development',
  ];
  static const types = [
    'Malls / Retail',
    'Office Complex',
    'Apartment Towers',
    'Gated Community',
    'Warehouses / Logistics',
  ];

  static const Map<String, List<String>> _keywords = {
    'Residential': ['residential', 'housing', 'apartment', 'estate', 'homes'],
    'Commercial': ['commercial', 'office', 'business park'],
    'Mixed Development': ['mixed-use', 'mixed use', 'mixed development'],
    'Malls / Retail': ['mall', 'retail', 'shopping'],
    'Office Complex': ['office'],
    'Apartment Towers': ['apartment', 'tower', 'flats'],
    'Gated Community': ['gated', 'community'],
    'Warehouses / Logistics': ['warehouse', 'logistics', 'industrial park'],
  };

  static bool matches(Project p, String label) {
    final haystack = '${p.title} ${p.summary ?? ''} ${p.location ?? ''}'
        .toLowerCase();
    final keywords = _keywords[label] ?? [label.toLowerCase()];
    return keywords.any(haystack.contains);
  }
}

class ProjectsScreen extends StatelessWidget {
  final String title;
  final String subtitle;

  /// 'infrastructure' (Infrastructure Tracker, the default) or
  /// 'private_development' (Private Projects) — see ProjectsController.
  final String projectType;

  const ProjectsScreen({
    super.key,
    this.title = "Kenya's Infrastructure Projects",
    this.subtitle =
        'Track road, bridge, building, and public infrastructure projects: '
        'progress, milestones, and community ratings.',
    this.projectType = 'infrastructure',
  });

  /// Applies incoming entity-filter arguments once, without clobbering
  /// whatever else is already selected — see ProjectsController.applyFilters.
  /// A no-op if this instance's controller already has the exact same
  /// filters applied (e.g. re-navigating here while it's already on the
  /// stack), so it never re-triggers a fetch loop.
  ///
  /// `Get.arguments` contract: a `Map` with any of —
  ///   `contractor` / `consultant` / `financier` — free-text stakeholder
  ///     names, matched as-is server-side (from a tapped Info Card chip on
  ///     ProjectDetailScreen).
  ///   `client` (+ optional `clientName`) — client slug for the real
  ///     server-side `client` filter, plus a display label for the header/
  ///     dismiss-pill since the slug alone isn't human-readable.
  ///   `category` — the `category` query param (distinct from `sector`).
  ///   `county` — free-text county name.
  ///   `user` (+ optional `userName`) — `submitted_by` id/slug plus a
  ///     display label, for "Contributions by {user}".
  ///   `budgetMin` / `budgetMax` (either may be absent for an open-ended
  ///     bracket) — the dynamic KES range from a tapped Budget quick-fact
  ///     chip on ProjectDetailScreen; applied separately below via
  ///     `applyBudgetFilter` since it's mutually exclusive with the entity
  ///     filters' single combined fetch (see that method).
  void _applyIncomingEntityArgs(ProjectsController ctrl) {
    final args = Get.arguments;
    if (args is! Map) return;
    final contractor = args['contractor'] as String?;
    final consultant = args['consultant'] as String?;
    final financier = args['financier'] as String?;
    final client = args['client'] as String?;
    final clientName = args['clientName'] as String?;
    final category = args['category'] as String?;
    final categoryName = args['categoryName'] as String?;
    final county = args['county'] as String?;
    final user = args['user'] as String?;
    final userName = args['userName'] as String?;
    final changed =
        (contractor != null && contractor != ctrl.selectedContractor.value) ||
        (consultant != null && consultant != ctrl.selectedConsultant.value) ||
        (financier != null && financier != ctrl.selectedFinancier.value) ||
        (client != null && client != ctrl.selectedClient.value) ||
        (category != null && category != ctrl.selectedCategory.value) ||
        (county != null && county != ctrl.selectedCounty.value) ||
        (user != null && user != ctrl.selectedUser.value);
    if (changed) {
      ctrl.applyFilters(
        contractor: contractor,
        consultant: consultant,
        financier: financier,
        client: client,
        clientName: clientName,
        category: category,
        categoryName: categoryName,
        county: county,
        user: user,
        userName: userName,
      );
    }

    if (args.containsKey('budgetMin') || args.containsKey('budgetMax')) {
      final budgetMin = (args['budgetMin'] as num?)?.toDouble();
      final budgetMax = (args['budgetMax'] as num?)?.toDouble();
      if (budgetMin != ctrl.budgetRangeMin.value ||
          budgetMax != ctrl.budgetRangeMax.value) {
        ctrl.applyBudgetFilter(budgetMin, budgetMax);
      }
    }
  }

  /// Priority-ordered contextual header title for whichever entity filter is
  /// active; falls back to the screen's static [title] when none is.
  String _dynamicTitle(ProjectsController ctrl) {
    if (ctrl.selectedClient.value.isNotEmpty) {
      final name = ctrl.selectedClientName.value.isNotEmpty
          ? ctrl.selectedClientName.value
          : ctrl.selectedClient.value;
      return 'Projects by $name';
    }
    if (ctrl.selectedContractor.value.isNotEmpty) {
      return 'Projects by ${ctrl.selectedContractor.value}';
    }
    if (ctrl.selectedConsultant.value.isNotEmpty) {
      return 'Projects Advised by ${ctrl.selectedConsultant.value}';
    }
    if (ctrl.selectedFinancier.value.isNotEmpty) {
      return 'Projects Financed by ${ctrl.selectedFinancier.value}';
    }
    if (ctrl.selectedCounty.value.isNotEmpty) {
      return 'Infrastructure Projects in ${ctrl.selectedCounty.value} County';
    }
    if (ctrl.selectedUser.value.isNotEmpty) {
      final name = ctrl.selectedUserName.value.isNotEmpty
          ? ctrl.selectedUserName.value
          : ctrl.selectedUser.value;
      return 'Contributions by $name';
    }
    final budget = _budgetRangeTitle(ctrl);
    if (budget != null) return budget;
    final combined = _statusCategoryHeading(ctrl);
    if (combined != null) return combined;
    return title;
  }

  /// "Projects Budgeted Between X and Y" hero title for a tapped
  /// [BudgetTier] bracket (or an open-ended "Above KES X" when [max] is
  /// null). Null when no budget bracket is active.
  String? _budgetRangeTitle(ProjectsController ctrl) {
    final min = ctrl.budgetRangeMin.value;
    final max = ctrl.budgetRangeMax.value;
    if (min == null && max == null) return null;
    if (max == null) return 'Projects Budgeted Above ${_compactKes(min!)}';
    if (min == null || min == 0) {
      return 'Projects Budgeted Under ${_compactKes(max)}';
    }
    return 'Projects Budgeted Between ${_compactKes(min)} and ${_compactKes(max)}';
  }

  String? _budgetRangeSubtitle(ProjectsController ctrl, int count) {
    if (_budgetRangeTitle(ctrl) == null) return null;
    return 'Showing $count project${count == 1 ? '' : 's'} in this budget range';
  }

  /// Human status label honoring both single- and multi-select — "Ongoing"
  /// for one value, "Ongoing/Planned" for several.
  String? _activeStatusLabel(ProjectsController ctrl) {
    if (ctrl.selectedStatuses.length > 1) {
      return ctrl.selectedStatuses.map(_statusLabel).join('/');
    }
    return ctrl.selectedStatus.value.isNotEmpty
        ? _statusLabel(ctrl.selectedStatus.value)
        : null;
  }

  /// Human category label honoring both single- and multi-select, same
  /// shape as [_activeStatusLabel]. [ProjectsController.selectedCategoryName]
  /// only ever holds one real label (set at the tap site), so a multi-select
  /// falls back to Title Case of each slug rather than a hardcoded
  /// category->label table.
  String? _activeCategoryLabel(ProjectsController ctrl) {
    if (ctrl.selectedCategories.length > 1) {
      return ctrl.selectedCategories.map(titleCaseFromSlug).join('/');
    }
    if (ctrl.selectedCategory.value.isEmpty) return null;
    return ctrl.selectedCategoryName.value.isNotEmpty
        ? ctrl.selectedCategoryName.value
        : titleCaseFromSlug(ctrl.selectedCategory.value);
  }

  /// Status + category filter heading (e.g. "Ongoing Private Developments",
  /// "Road Projects", "Ongoing Road Projects") — lower priority than the
  /// entity-filter titles above (client/contractor/etc. + county), which
  /// already give a more specific header.
  String? _statusCategoryHeading(ProjectsController ctrl) {
    final statusPart = _activeStatusLabel(ctrl);
    final categoryName = _activeCategoryLabel(ctrl);
    if (statusPart == null && categoryName == null) return null;
    final noun = categoryName != null
        ? '$categoryName Projects'
        : (projectType == 'private_development'
              ? 'Private Developments'
              : 'Infrastructure Projects');
    return statusPart != null ? '$statusPart $noun' : noun;
  }

  String? _statusCategorySubtitle(ProjectsController ctrl) {
    final statusPart = _activeStatusLabel(ctrl);
    final categoryName = _activeCategoryLabel(ctrl);
    if (statusPart == null && categoryName == null) return null;
    final count = ctrl.projects.length;
    var noun = 'project${count == 1 ? '' : 's'}';
    if (categoryName != null) noun = '${categoryName.toLowerCase()} $noun';
    if (statusPart != null) noun = '${statusPart.toLowerCase()} $noun';
    return 'Showing $count $noun';
  }

  String _dynamicSubtitle(ProjectsController ctrl) {
    if (ctrl.selectedClient.value.isNotEmpty) {
      final name = ctrl.selectedClientName.value.isNotEmpty
          ? ctrl.selectedClientName.value
          : ctrl.selectedClient.value;
      return 'Projects commissioned or overseen by $name';
    }
    if (ctrl.selectedContractor.value.isNotEmpty) {
      return 'Civil works executed by ${ctrl.selectedContractor.value}';
    }
    if (ctrl.selectedConsultant.value.isNotEmpty) {
      return 'Technical advisory and design by ${ctrl.selectedConsultant.value}';
    }
    if (ctrl.selectedFinancier.value.isNotEmpty) {
      return 'Projects backed by ${ctrl.selectedFinancier.value}';
    }
    if (ctrl.selectedCounty.value.isNotEmpty) {
      return 'Public works and development across ${ctrl.selectedCounty.value}';
    }
    if (ctrl.selectedUser.value.isNotEmpty) {
      final name = ctrl.selectedUserName.value.isNotEmpty
          ? ctrl.selectedUserName.value
          : ctrl.selectedUser.value;
      return 'Projects submitted and curated by $name';
    }
    final budget = _budgetRangeSubtitle(ctrl, ctrl.projects.length);
    if (budget != null) return budget;
    final combined = _statusCategorySubtitle(ctrl);
    if (combined != null) return combined;
    return subtitle;
  }

  /// "KES 500M" / "KES 2B" compact label for a raw KES value, matching the
  /// [BudgetTier] labels' own formatting.
  String _compactKes(double value) {
    if (value >= 1000000000) {
      final b = value / 1000000000;
      return 'KES ${b == b.roundToDouble() ? b.toInt() : b.toStringAsFixed(1)}B';
    }
    final m = value / 1000000;
    return 'KES ${m == m.roundToDouble() ? m.toInt() : m.toStringAsFixed(1)}M';
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(
      ProjectsController(projectType: projectType),
      tag: projectType,
    );
    _applyIncomingEntityArgs(ctrl);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: _kBlue,
          onPressed: () async {
            final submitted = await Get.toNamed(
              AppRoutes.submitProject,
              arguments: projectType,
            );
            if (submitted == true) ctrl.fetchAll();
          },
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            '+ Submit Project',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Obx(() {
                if (ctrl.isLoading.value) return _buildLoading();
                return _buildContent(context, ctrl);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      children: [
        _buildHeader(null),
        const Expanded(
          child: Center(child: CircularProgressIndicator(color: _kBlue)),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, ProjectsController ctrl) {
    return Column(
      children: [
        // App bar / header — title, back button, search only. Filter chips
        // live in the scrollable content below the map, not here.
        _buildHeader(ctrl),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollEndNotification &&
                  n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                ctrl.loadMore();
              }
              return false;
            },
            child: Obx(
              () => ContentWidth(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    const SizedBox(height: 12),
                    _buildHeroBanner(ctrl),
                    const SizedBox(height: 16),
                    _buildFeaturedStrip(ctrl),
                    _buildFilterControls(context, ctrl),
                    _buildEntityIntelligenceHeader(ctrl),
                    _buildActiveEntityFilters(ctrl),
                    const SizedBox(height: 12),

                    // Dedicated tracker control — status/county/client
                    // filter chips, directly above the primary list/grid
                    // feed (list-first, not map-dominated).
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Megaprojects',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _kDark,
                        ),
                      ),
                    ),
                    _PortfolioTabs(ctrl: ctrl),
                    const SizedBox(height: 10),
                    _buildProjectsGrid(ctrl),

                    // Interactive live map — color-coded status pins,
                    // tap-to-preview bottom sheet. Always rendered (see
                    // TrackerLiveMap/ProjectsMapView), never unmounted when
                    // the current filter matches zero pins. Moved below the
                    // primary feed so the list/grid is the default view,
                    // matching the website.
                    const SizedBox(height: 20),
                    TrackerLiveMap(projects: ctrl.projects, loading: false),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ProjectsController? ctrl) {
    return Container(
      color: _kCard,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
                  color: _kDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ctrl == null
                    ? Text(
                        title,
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1D4ED8),
                        ),
                      )
                    : Obx(
                        () => Text(
                          _dynamicTitle(ctrl),
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ctrl == null
              ? Text(
                  subtitle,
                  style: GoogleFonts.montserrat(fontSize: 12, color: _kSubtext),
                )
              : Obx(
                  () => Text(
                    _dynamicSubtitle(ctrl),
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: _kSubtext,
                    ),
                  ),
                ),
          if (ctrl != null) ...[
            const SizedBox(height: 12),
            // Search + filter bar — full-width input on its own row, then a
            // "Search"/"Filters" button pair sharing equal width below, no
            // outer container/shadow wrapper around the section (the input's
            // own border is the only bordered element here).
            _SearchFilterBar(
              ctrl: ctrl,
              onOpenFilters: (context) => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (sheetContext) => SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 16, bottom: 24),
                    child: _buildFilterControls(sheetContext, ctrl),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Standardized tracker hero — deep blue gradient panel with a featured-
  /// project carousel, shared with the other three trackers via
  /// [TrackerHeroSection]. Filtered views (a tapped client/contractor/etc.)
  /// never show a global featured project — falls back to the already-
  /// filtered result set's top rows so the carousel never reads as
  /// unrelated content.
  Widget _buildHeroBanner(ProjectsController ctrl) {
    return Obx(() {
      final featured = ctrl.hasArchiveFilter
          ? ctrl.projects.take(5).toList()
          : () {
              final f = ctrl.projects.where((p) => p.isFeatured).toList();
              return (f.isNotEmpty ? f : ctrl.projects).take(5).toList();
            }();

      return TrackerHeroSection(
        title: title,
        subtitle: subtitle,
        featuredProjects: featured,
        submitProjectType: projectType,
        searchHint: 'Search $title…',
        onSearch: (q) => ctrl.applyFilters(
          status: ctrl.selectedStatus.value,
          county: ctrl.selectedCounty.value,
          sector: ctrl.selectedSector.value,
          q: q,
        ),
        onSubmitted: ctrl.fetchAll,
      );
    });
  }

  /// Top-3 featured projects from the currently-loaded page (derived from
  /// `ctrl.projects`/`Project.isFeatured` rather than a separate fetch —
  /// there's no dedicated "featured projects" endpoint, and
  /// `getTrackerSections` returns a differently-shaped module set, not a
  /// flat featured list). Hidden entirely when none of the loaded rows are
  /// featured, rather than showing an empty section.
  Widget _buildFeaturedStrip(ProjectsController ctrl) {
    return Obx(() {
      // Never show generic global featured projects on a filtered view
      // (e.g. Talanta Stadium showing up under "Projects by KeNHA"), status
      // tab, or budget bracket — any of these already scope the page to a
      // specific archive, so a generic "Featured Projects" module would read
      // as unrelated content.
      if (ctrl.hasArchiveFilter) return const SizedBox.shrink();
      final featured = ctrl.projects
          .where((p) => p.isFeatured)
          .take(3)
          .toList();
      if (featured.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Featured Projects',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _kDark,
              ),
            ),
            const SizedBox(height: 10),
            for (final project in featured) ...[
              _FeaturedProjectRowCard(project: project),
              const SizedBox(height: 10),
            ],
          ],
        ),
      );
    });
  }

  /// Single-line "Financier: Government of Kenya"-style header, shown only
  /// when a stakeholder filter is active — the per-status counts already
  /// live in [_PortfolioTabs]'s chip labels just below, so this only adds
  /// the missing identity line rather than duplicating those network calls.
  Widget _buildEntityIntelligenceHeader(ProjectsController ctrl) {
    return Obx(() {
      final (label, value) = switch (ctrl) {
        _ when ctrl.selectedFinancier.value.isNotEmpty => (
          'Financier',
          ctrl.selectedFinancier.value,
        ),
        _ when ctrl.selectedContractor.value.isNotEmpty => (
          'Contractor',
          ctrl.selectedContractor.value,
        ),
        _ when ctrl.selectedConsultant.value.isNotEmpty => (
          'Consultant',
          ctrl.selectedConsultant.value,
        ),
        _ when ctrl.selectedClient.value.isNotEmpty => (
          'Client',
          ctrl.selectedClientName.value.isNotEmpty
              ? ctrl.selectedClientName.value
              : ctrl.selectedClient.value,
        ),
        _ => (null, null),
      };
      if (label == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Text(
          '$label: $value',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0A2540),
          ),
        ),
      );
    });
  }

  /// Dismissible chip bar for stakeholder filters arriving from a tapped
  /// entity link on ProjectDetailScreen (e.g. "Contractor: CRBC [x]"). Each
  /// chip clears only its own filter — the county/sector/status/cost-tier
  /// controls above are untouched, so filters stack rather than reset.
  Widget _buildActiveEntityFilters(ProjectsController ctrl) {
    return Obx(() {
      final active = <(String, String, VoidCallback)>[
        if (ctrl.selectedClient.value.isNotEmpty)
          (
            'Client',
            ctrl.selectedClientName.value.isNotEmpty
                ? ctrl.selectedClientName.value
                : ctrl.selectedClient.value,
            () => ctrl.applyFilters(client: '', clientName: ''),
          ),
        if (ctrl.selectedContractor.value.isNotEmpty)
          (
            'Contractor',
            ctrl.selectedContractor.value,
            () => ctrl.applyFilters(contractor: ''),
          ),
        if (ctrl.selectedConsultant.value.isNotEmpty)
          (
            'Consultant',
            ctrl.selectedConsultant.value,
            () => ctrl.applyFilters(consultant: ''),
          ),
        if (ctrl.selectedFinancier.value.isNotEmpty)
          (
            'Financier',
            ctrl.selectedFinancier.value,
            () => ctrl.applyFilters(financier: ''),
          ),
        if (ctrl.selectedCategory.value.isNotEmpty)
          (
            'Category',
            ctrl.selectedCategory.value,
            () => ctrl.applyFilters(category: ''),
          ),
        if (ctrl.selectedUser.value.isNotEmpty)
          (
            'Contributor',
            ctrl.selectedUserName.value.isNotEmpty
                ? ctrl.selectedUserName.value
                : ctrl.selectedUser.value,
            () => ctrl.applyFilters(user: '', userName: ''),
          ),
        if (ctrl.selectedCounty.value.isNotEmpty)
          (
            'County',
            ctrl.selectedCounty.value,
            () {
              ctrl.selectedCounties.clear();
              ctrl.applyFilters(county: '');
            },
          ),
        if (ctrl.selectedTypologies.isNotEmpty)
          (
            'Typology',
            ctrl.selectedTypologies.join(', '),
            () => ctrl.selectedTypologies.clear(),
          ),
      ];
      if (active.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, value, onClear) in active)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Filter: $label: $value',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0284C7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onClear,
                        child: const Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildFilterControls(BuildContext context, ProjectsController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filter projects',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kDark,
                ),
              ),
              const Spacer(),
              if (ctrl.activeFilterCount > 0)
                TextButton(
                  onPressed: ctrl.clearFilters,
                  child: const Text('Clear All'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (projectType == 'private_development')
            _buildPrivateFilterGrid(context, ctrl)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _LabeledFilterButton(
                  label: 'Category',
                  value: ctrl.selectedCategories.length > 1
                      ? '${ctrl.selectedCategories.length} selected'
                      : (ctrl.selectedCategoryName.value.isNotEmpty
                            ? ctrl.selectedCategoryName.value
                            : 'All categories'),
                  icon: Icons.apartment_outlined,
                  onTap: () => _showCategorySheet(context, ctrl),
                ),
                _LabeledFilterButton(
                  label: 'County',
                  value: ctrl.selectedCounties.isEmpty
                      ? 'All 47 Counties'
                      : '${ctrl.selectedCounties.length} selected',
                  icon: Icons.location_on_outlined,
                  onTap: () => _showCountySheet(context, ctrl),
                ),
                _LabeledFilterButton(
                  label: 'Sector',
                  value: ctrl.selectedSector.value.isEmpty
                      ? 'All sectors'
                      : ctrl.selectedSector.value,
                  icon: Icons.category_outlined,
                  onTap: () => _showSingleSelectSheet(
                    context,
                    title: 'Select Sector',
                    options: ProjectsController.sectorOptions,
                    selected: ctrl.selectedSector.value,
                    onSelected: (value) => ctrl.applyFilters(sector: value),
                  ),
                ),
                _LabeledFilterButton(
                  label: 'Project Status',
                  value: ctrl.selectedStatuses.length > 1
                      ? '${ctrl.selectedStatuses.length} selected'
                      : _statusLabel(ctrl.selectedStatus.value),
                  icon: Icons.timelapse_outlined,
                  onTap: () => _showStatusSheet(context, ctrl),
                ),
                _LabeledFilterButton(
                  label: 'Cost Tier',
                  value: _costTierLabel(ctrl.selectedCostTier.value),
                  icon: Icons.payments_outlined,
                  onTap: () => _showSingleSelectSheet(
                    context,
                    title: 'Select Cost Tier',
                    options: const [
                      'Under KES 100M',
                      'KES 100M–500M',
                      'KES 500M–1B',
                      'KES 1B–5B',
                      'KES 5B+',
                      'Under USD 1M',
                      'USD 1M–5M',
                      'USD 5M–10M',
                      'USD 10M+',
                    ],
                    values: const [
                      '<100M',
                      '100M-500M',
                      '500M-1B',
                      '1B-5B',
                      '5B+',
                      'usd_under_1m',
                      'usd_1m_5m',
                      'usd_5m_10m',
                      'usd_10m_plus',
                    ],
                    selected: ctrl.selectedCostTier.value,
                    onSelected: (value) {
                      ctrl.selectedCostTier.value = value;
                      ctrl.budgetRangeMin.value = null;
                      ctrl.budgetRangeMax.value = null;
                      ctrl.fetchAll();
                    },
                  ),
                ),
                _LabeledFilterButton(
                  label: 'Sort By',
                  value: _sortLabel(ctrl),
                  icon: Icons.sort_rounded,
                  onTap: () => _showSingleSelectSheet(
                    context,
                    title: 'Sort By',
                    options: const [
                      'Default',
                      'Trending',
                      'Newest',
                      'Recently Updated',
                      'Budget: High to Low',
                    ],
                    values: const [
                      '',
                      'trending',
                      'newest',
                      'recently_updated',
                      'budget_desc',
                    ],
                    selected: ctrl.selectedSort.value == 'trending'
                        ? 'trending'
                        : ctrl.clientSortBy.value,
                    onSelected: (value) => _applySort(ctrl, value),
                  ),
                ),
              ],
            ),
          if (ctrl.activeFilterCount > 0) ...[
            const SizedBox(height: 10),
            Text(
              'Filters (${ctrl.activeFilterCount}) active',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: _kBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Private Projects' filter architecture — a compact 2-column grid rather
  /// than infrastructure's wrapping chip row, with more facets (typology,
  /// developer/architect/contractor, sort) matching the web's Private
  /// Developments Tracker filter panel. "Scope" (National/County/Regional)
  /// from the web spec is intentionally not included here: `Project` has no
  /// server-side scope column (only `county`, already covered by the County
  /// facet below), so a Scope filter would be decorative rather than real —
  /// same reasoning `_BuildingsTaxonomyFilter`'s doc comment gives for
  /// keeping Typology client-side instead of a fabricated server param.
  Widget _buildPrivateFilterGrid(
    BuildContext context,
    ProjectsController ctrl,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 3.2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _LabeledFilterButton(
          label: 'Category / Typology',
          value: ctrl.selectedTypologies.isEmpty
              ? 'All Typologies'
              : '${ctrl.selectedTypologies.length} selected',
          icon: Icons.apartment_outlined,
          onTap: () => _showTypologySheet(context, ctrl),
        ),
        _LabeledFilterButton(
          label: 'National or County',
          value: ctrl.selectedCounties.isEmpty
              ? 'All Kenya'
              : '${ctrl.selectedCounties.length} selected',
          icon: Icons.location_on_outlined,
          onTap: () => _showCountySheet(context, ctrl),
        ),
        _LabeledFilterButton(
          label: 'Status',
          value: ctrl.selectedStatuses.length > 1
              ? '${ctrl.selectedStatuses.length} selected'
              : _privateStatusLabel(ctrl.selectedStatus.value),
          icon: Icons.timelapse_outlined,
          onTap: () => _showStatusSheet(context, ctrl),
        ),
        _LabeledFilterButton(
          label: 'Developer / Client',
          value: ctrl.selectedClientName.value.isNotEmpty
              ? ctrl.selectedClientName.value
              : (ctrl.selectedClient.value.isEmpty
                    ? 'All Developers'
                    : ctrl.selectedClient.value),
          icon: Icons.business_outlined,
          onTap: () => _showClientSheet(context, ctrl),
        ),
        _LabeledFilterButton(
          label: 'Architect / Consultant',
          value: ctrl.selectedConsultant.value.isEmpty
              ? 'Any Consultant'
              : ctrl.selectedConsultant.value,
          icon: Icons.architecture_outlined,
          onTap: () => _showFreeTextSheet(
            context,
            title: 'Architect / Consultant',
            hint: 'e.g. Planet Architects',
            initial: ctrl.selectedConsultant.value,
            onApply: (value) => ctrl.applyFilters(consultant: value),
          ),
        ),
        _LabeledFilterButton(
          label: 'Main Contractor',
          value: ctrl.selectedContractor.value.isEmpty
              ? 'Any Contractor'
              : ctrl.selectedContractor.value,
          icon: Icons.engineering_outlined,
          onTap: () => _showFreeTextSheet(
            context,
            title: 'Main Contractor',
            hint: 'e.g. China Wu Yi',
            initial: ctrl.selectedContractor.value,
            onApply: (value) => ctrl.applyFilters(contractor: value),
          ),
        ),
        _LabeledFilterButton(
          label: 'Cost Range',
          value: _costTierLabel(ctrl.selectedCostTier.value),
          icon: Icons.payments_outlined,
          onTap: () => _showSingleSelectSheet(
            context,
            title: 'Select Cost Range',
            options: const [
              'Under KES 100M',
              'KES 100M–500M',
              'KES 500M–1B',
              'KES 1B–5B',
              'KES 5B+',
              'Under USD 1M',
              'USD 1M–5M',
              'USD 5M–10M',
              'USD 10M+',
            ],
            values: const [
              '<100M',
              '100M-500M',
              '500M-1B',
              '1B-5B',
              '5B+',
              'usd_under_1m',
              'usd_1m_5m',
              'usd_5m_10m',
              'usd_10m_plus',
            ],
            selected: ctrl.selectedCostTier.value,
            onSelected: (value) {
              ctrl.selectedCostTier.value = value;
              ctrl.budgetRangeMin.value = null;
              ctrl.budgetRangeMax.value = null;
              ctrl.fetchAll();
            },
          ),
        ),
        _LabeledFilterButton(
          label: 'Sort By',
          value: _sortLabel(ctrl),
          icon: Icons.sort_rounded,
          onTap: () => _showSingleSelectSheet(
            context,
            title: 'Sort By',
            options: const [
              'Default',
              'Trending',
              'Newest',
              'Recently Updated',
              'Budget: High to Low',
            ],
            values: const [
              '',
              'trending',
              'newest',
              'recently_updated',
              'budget_desc',
            ],
            selected: ctrl.selectedSort.value == 'trending'
                ? 'trending'
                : ctrl.clientSortBy.value,
            onSelected: (value) => _applySort(ctrl, value),
          ),
        ),
      ],
    );
  }

  /// Server-side `trending` and the client-side options share one dropdown
  /// (see `ProjectsController.clientSortBy`'s doc comment) — this resolves
  /// which one is currently active for display, and [_applySort] below
  /// keeps the two mutually exclusive.
  String _sortLabel(ProjectsController ctrl) {
    if (ctrl.selectedSort.value == 'trending') return 'Trending';
    switch (ctrl.clientSortBy.value) {
      case 'newest':
        return 'Newest';
      case 'recently_updated':
        return 'Recently Updated';
      case 'budget_desc':
        return 'Budget: High to Low';
      default:
        return 'Default';
    }
  }

  void _applySort(ProjectsController ctrl, String value) {
    if (value == 'trending' || value.isEmpty) {
      ctrl.clientSortBy.value = '';
      ctrl.applyFilters(sort: value);
    } else {
      ctrl.clientSortBy.value = value;
      if (ctrl.selectedSort.value == 'trending') {
        ctrl.applyFilters(sort: '');
      }
    }
  }

  Future<void> _showTypologySheet(
    BuildContext context,
    ProjectsController ctrl,
  ) async {
    final options = [
      ...BuildingsTaxonomy.subcategories,
      ...BuildingsTaxonomy.types,
    ];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _MultiSelectChipSheet(
        title: 'Select Typology',
        options: options,
        selected: ctrl.selectedTypologies.toSet(),
        onApply: (values) {
          Navigator.pop(sheetContext);
          ctrl.selectedTypologies.assignAll(values);
        },
      ),
    );
  }

  Future<void> _showClientSheet(
    BuildContext context,
    ProjectsController ctrl,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _ClientSelectSheet(
        selectedSlug: ctrl.selectedClient.value,
        onSelected: (slug, name) {
          Navigator.pop(sheetContext);
          ctrl.applyFilters(client: slug, clientName: name);
        },
      ),
    );
  }

  Future<void> _showFreeTextSheet(
    BuildContext context, {
    required String title,
    required String hint,
    required String initial,
    required ValueChanged<String> onApply,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _FreeTextFilterSheet(
        title: title,
        hint: hint,
        initial: initial,
        onApply: (value) {
          Navigator.pop(sheetContext);
          onApply(value);
        },
      ),
    );
  }

  String _privateStatusLabel(String status) => switch (status) {
    '' => 'All statuses',
    'planned' => 'Planned',
    'ongoing' => 'Ongoing',
    'completed' => 'Completed',
    'stalled' => 'Stalled',
    'cancelled' => 'Cancelled',
    _ => titleCaseFromSlug(status),
  };

  String _statusLabel(String status) => switch (status) {
    '' => 'All statuses',
    'planned' => 'Planned',
    'ongoing' => 'Ongoing',
    'completed' => 'Completed',
    'stalled' => 'Stalled',
    'cancelled' => 'Cancelled',
    _ => titleCaseFromSlug(status),
  };

  String _costTierLabel(String tier) => switch (tier) {
    '<100M' => 'Under KES 100M',
    '100M-500M' => 'KES 100M–500M',
    '500M-1B' => 'KES 500M–1B',
    '1B-5B' => 'KES 1B–5B',
    '5B+' => 'KES 5B+',
    'usd_under_1m' => 'Under USD 1M',
    'usd_1m_5m' => 'USD 1M–5M',
    'usd_5m_10m' => 'USD 5M–10M',
    'usd_10m_plus' => 'USD 10M+',
    _ => 'All ranges',
  };

  Future<void> _showCountySheet(
    BuildContext context,
    ProjectsController ctrl,
  ) async {
    final selected = ctrl.selectedCounties.toSet();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _SearchableMultiSelectSheet(
        title: 'Select County',
        options: ctrl.availableCounties,
        selected: selected,
        onApply: (values) {
          Navigator.pop(sheetContext);
          ctrl.applyCountySelection(values);
        },
      ),
    );
  }

  /// Multi-select tracker Category — options come from the real backend
  /// category taxonomy (`GET /projects/tracker-sections`'s
  /// `categoryPreview`), not a hardcoded list, so new categories the backend
  /// adds show up automatically.
  Future<void> _showCategorySheet(
    BuildContext context,
    ProjectsController ctrl,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _CategorySelectSheet(
        projectType: projectType,
        selected: ctrl.selectedCategories.isNotEmpty
            ? ctrl.selectedCategories.toSet()
            : (ctrl.selectedCategory.value.isEmpty
                  ? <String>{}
                  : {ctrl.selectedCategory.value}),
        onApply: (values, names) {
          Navigator.pop(sheetContext);
          ctrl.applyCategorySelection(values, names);
        },
      ),
    );
  }

  /// Multi-select Status — see ProjectsController.applyStatusSelection for
  /// how more than one selected value is served (fan-out + merge, since
  /// `GET /projects?status=` only ever takes one).
  Future<void> _showStatusSheet(
    BuildContext context,
    ProjectsController ctrl,
  ) async {
    const options = ['Planned', 'Ongoing', 'Stalled', 'Cancelled', 'Completed'];
    const values = ['planned', 'ongoing', 'stalled', 'cancelled', 'completed'];
    final selected = ctrl.selectedStatuses.isNotEmpty
        ? ctrl.selectedStatuses.toSet()
        : (ctrl.selectedStatus.value.isEmpty
              ? <String>{}
              : {ctrl.selectedStatus.value});
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _MultiSelectChipSheet(
        title: 'Select Status',
        options: options,
        values: values,
        selected: selected,
        onApply: (chosen) {
          Navigator.pop(sheetContext);
          ctrl.applyStatusSelection(chosen);
        },
      ),
    );
  }

  Future<void> _showSingleSelectSheet(
    BuildContext context, {
    required String title,
    required List<String> options,
    List<String>? values,
    required String selected,
    required ValueChanged<String> onSelected,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _SearchableSelectSheet(
        title: title,
        options: options,
        values: values,
        selected: selected,
        onSelected: (value) {
          Navigator.pop(sheetContext);
          onSelected(value);
        },
      ),
    );
  }

  Widget _buildProjectsGrid(ProjectsController ctrl) {
    final filtered = ctrl.selectedTypologies.isEmpty
        ? ctrl.projects
        : ctrl.projects
              .where(
                (p) => ctrl.selectedTypologies.any(
                  (t) => BuildingsTaxonomy.matches(p, t),
                ),
              )
              .toList();
    final visible = _sorted(filtered, ctrl.clientSortBy.value);
    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No projects found.',
            style: GoogleFonts.montserrat(fontSize: 14, color: _kSubtext),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: visible.map((p) => _ProjectListTile(project: p)).toList(),
      ),
    );
  }
}

// ── Search + filter bar ────────────────────────────────────────────────────

/// Full-width search input on row 1; a "Search" (filled) / "Filters"
/// (outlined, with an active-filter count badge) button pair sharing equal
/// width on row 2. No outer bordered/shadowed container around the section
/// — the input's own outline is the only border here.
class _SearchFilterBar extends StatefulWidget {
  final ProjectsController ctrl;
  final void Function(BuildContext context) onOpenFilters;

  const _SearchFilterBar({required this.ctrl, required this.onOpenFilters});

  @override
  State<_SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<_SearchFilterBar> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submit() {
    final ctrl = widget.ctrl;
    ctrl.applyFilters(
      status: ctrl.selectedStatus.value,
      county: ctrl.selectedCounty.value,
      sector: ctrl.selectedSector.value,
      q: _searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onSubmitted: (_) => _submit(),
          style: GoogleFonts.montserrat(fontSize: 13.5, color: _kDark),
          decoration: InputDecoration(
            hintText: 'Search projects…',
            hintStyle: GoogleFonts.montserrat(fontSize: 13, color: _kSubtext),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: _kSubtext,
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kDivider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kDivider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBlue, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Search',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Obx(() {
                final count = widget.ctrl.activeFilterCount;
                return OutlinedButton(
                  onPressed: () => widget.onOpenFilters(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kBlue,
                    side: const BorderSide(color: _kDivider),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    count > 0 ? 'Filters ($count)' : 'Filters',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Featured strip row card (compact, under the hero banner) ──────────────

class _FeaturedProjectRowCard extends StatelessWidget {
  final Project project;
  const _FeaturedProjectRowCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => Get.to(
        () => ProjectDetailScreen(slug: project.slug),
        transition: Transition.cupertino,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NetImage(
              url: project.imageUrl,
              width: 76,
              height: 76,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          project.statusLabel.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0284C7),
                          ),
                        ),
                      ),
                      if (project.county != null ||
                          project.location != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '·',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            project.county ?? project.location!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _ProgressBar(
                    value: project.progressPercent / 100,
                    percent: project.progressPercent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Featured card (horizontal scroll) ────────────────────────────────────────

class _FeaturedProjectCard extends StatelessWidget {
  final Project project;
  const _FeaturedProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(
        () => ProjectDetailScreen(slug: project.slug),
        transition: Transition.cupertino,
      ),
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kDivider),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: NetImage(
                  url: project.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholderColor: const Color(0xFF1E3A5F),
                  placeholderIcon: Icons.business_rounded,
                  placeholderIconColor: Colors.white38,
                  placeholderIconSize: 36,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (project.county != null || project.location != null)
                      Text(
                        '📍 ${project.county ?? project.location}',
                        style: GoogleFonts.montserrat(
                          fontSize: 10.5,
                          color: _kSubtext,
                        ),
                      ),
                    const Spacer(),
                    _ProgressBar(
                      value: project.progressPercent / 100,
                      percent: project.progressPercent,
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

// ── Project list tile (main list) ─────────────────────────────────────────────

class _ProjectListTile extends StatelessWidget {
  final Project project;
  const _ProjectListTile({required this.project});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(
        () => ProjectDetailScreen(slug: project.slug),
        transition: Transition.cupertino,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kDivider),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 100,
                height: 100,
                child: NetImage(
                  url: project.imageUrl,
                  fit: BoxFit.cover,
                  placeholderColor: const Color(0xFF1E3A5F),
                  placeholderIcon: Icons.business_rounded,
                  placeholderIconColor: Colors.white38,
                ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sector + client tags
                    Row(
                      children: [
                        _MetricTag(label: project.sectorLabel),
                        if (project.client != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              project.client!.name,
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                color: _kSubtext,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _StatusBadge(status: project.status),
                        if (project.county != null ||
                            project.location != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '·',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _kSubtext,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              project.county ?? project.location!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                color: _kSubtext,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (project.budgetTierBracket != null)
                      GestureDetector(
                        onTap: () => _openBudgetTier(project),
                        child: Text(
                          'Budget: ${project.budgetTier}',
                          style: GoogleFonts.montserrat(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: _kBlue,
                            decoration: TextDecoration.underline,
                            decorationColor: _kBlue,
                          ),
                        ),
                      )
                    else
                      Text(
                        'Budget: ${project.budgetTier}',
                        style: GoogleFonts.montserrat(
                          fontSize: 10.5,
                          color: _kSubtext,
                        ),
                      ),
                    if (project.contractor != null &&
                        project.contractor!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Contractor: ${project.contractor}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 10.5,
                          color: _kSubtext,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _ProgressBar(
                      value: project.progressPercent / 100,
                      percent: project.progressPercent,
                    ),
                    if (project.averageRating != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '⭐ ${project.ratingDisplay} (${project.ratingCount} ratings)',
                        style: GoogleFonts.montserrat(
                          fontSize: 10.5,
                          color: _kSubtext,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12, top: 12),
              child: Icon(
                Icons.chevron_right_rounded,
                color: _kSubtext,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final double value;
  final num percent;
  const _ProgressBar({required this.value, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                backgroundColor: _kDivider,
                valueColor: const AlwaysStoppedAnimation<Color>(_kBlue),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$percent%',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _kBlue,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case 'completed':
        return const Color(0xFF16A34A);
      case 'ongoing':
        return _kBlue;
      case 'planned':
        return const Color(0xFFF59E0B);
      case 'stalled':
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return _kSubtext;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        Project.labelForStatus(status),
        style: GoogleFonts.montserrat(
          fontSize: 9.5,
          fontWeight: FontWeight.w500,
          color: _color,
        ),
      ),
    );
  }
}

/// Buildings subcategory + type chip filter (Spec 3), Private Projects only.
/// Purely client-side: selecting a chip filters the already-loaded
/// `ctrl.projects` by keyword match (see `BuildingsTaxonomy.matches`) and
/// shows a "Matching Buildings" preview strip — it does not call the API
/// with a new query, since there's no server-side field to filter on.
class _BuildingsTaxonomyFilter extends StatefulWidget {
  final ProjectsController ctrl;
  const _BuildingsTaxonomyFilter({required this.ctrl});

  @override
  State<_BuildingsTaxonomyFilter> createState() =>
      _BuildingsTaxonomyFilterState();
}

class _BuildingsTaxonomyFilterState extends State<_BuildingsTaxonomyFilter> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final allChips = [
      ...BuildingsTaxonomy.subcategories,
      ...BuildingsTaxonomy.types,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Buildings',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.captionSlate,
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: allChips.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                return _FilterChip(
                  label: 'All',
                  selected: _selected == null,
                  onTap: () => setState(() => _selected = null),
                );
              }
              final label = allChips[i - 1];
              return _FilterChip(
                label: label,
                selected: _selected == label,
                onTap: () => setState(() => _selected = label),
              );
            },
          ),
        ),
        if (_selected != null)
          Obx(() {
            final matches = widget.ctrl.projects
                .where((p) => BuildingsTaxonomy.matches(p, _selected!))
                .toList();
            if (matches.isEmpty) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Text(
                  'No loaded projects match "$_selected" yet.',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: AppColors.captionSlate,
                  ),
                ),
              );
            }
            return SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                itemCount: matches.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) =>
                    _FeaturedProjectCard(project: matches[i]),
              ),
            );
          }),
      ],
    );
  }
}

class _LabeledFilterButton extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _LabeledFilterButton({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minWidth: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kDivider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: _kBlue),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _kSubtext,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kDark,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.expand_more_rounded, size: 18, color: _kSubtext),
          ],
        ),
      ),
    );
  }
}

class _MetricTag extends StatelessWidget {
  final String label;
  const _MetricTag({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: _kBg,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: GoogleFonts.montserrat(
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
        color: _kBlue,
      ),
    ),
  );
}

class _SearchableSelectSheet extends StatefulWidget {
  final String title;
  final List<String> options;
  final List<String>? values;
  final String selected;
  final ValueChanged<String> onSelected;

  const _SearchableSelectSheet({
    required this.title,
    required this.options,
    this.values,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<_SearchableSelectSheet> createState() => _SearchableSelectSheetState();
}

class _SearchableSelectSheetState extends State<_SearchableSelectSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final visible = widget.options
        .asMap()
        .entries
        .where(
          (entry) => entry.value.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: Column(
          children: [
            ListTile(
              title: Text(
                widget.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: const Icon(Icons.close_rounded),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search options',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: RadioGroup<String>(
                groupValue: widget.selected,
                onChanged: (selected) {
                  if (selected != null) widget.onSelected(selected);
                },
                child: ListView.builder(
                  itemCount: visible.length,
                  itemBuilder: (_, index) {
                    final entry = visible[index];
                    final value = widget.values?[entry.key] ?? entry.value;
                    return RadioListTile<String>(
                      title: Text(entry.value),
                      value: value,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchableMultiSelectSheet extends StatefulWidget {
  final String title;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<List<String>> onApply;

  const _SearchableMultiSelectSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.onApply,
  });

  @override
  State<_SearchableMultiSelectSheet> createState() =>
      _SearchableMultiSelectSheetState();
}

class _SearchableMultiSelectSheetState
    extends State<_SearchableMultiSelectSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final visible = widget.options
        .where((option) => option.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .78,
        child: Column(
          children: [
            ListTile(
              title: Text(
                widget.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: Text('${widget.selected.length} selected'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search counties',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: visible.length,
                itemBuilder: (_, index) => CheckboxListTile(
                  title: Text(visible[index]),
                  value: widget.selected.contains(visible[index]),
                  onChanged: (checked) => setState(
                    () => checked == true
                        ? widget.selected.add(visible[index])
                        : widget.selected.remove(visible[index]),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => widget.onApply(widget.selected.toList()),
                  child: const Text('Apply County Filter'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Developer/Client picker for Private Projects' filter grid — client is a
/// slug-based server filter (see ProjectsService.clientSlug), so this needs
/// a real name→slug list rather than free text; `GET clients` is the only
/// source for that.
class _ClientSelectSheet extends StatefulWidget {
  final String selectedSlug;
  final void Function(String slug, String name) onSelected;

  const _ClientSelectSheet({
    required this.selectedSlug,
    required this.onSelected,
  });

  @override
  State<_ClientSelectSheet> createState() => _ClientSelectSheetState();
}

class _ClientSelectSheetState extends State<_ClientSelectSheet> {
  final _service = ProjectsService();
  late final Future<List<ProjectClient>> _future = _service.getClients();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: Column(
          children: [
            const ListTile(
              title: Text(
                'Select Developer / Client',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: Icon(Icons.close_rounded),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search developers / clients',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<ProjectClient>>(
                future: _future,
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  final visible = snap.data!
                      .where(
                        (c) =>
                            c.name.toLowerCase().contains(_query.toLowerCase()),
                      )
                      .toList();
                  if (visible.isEmpty) {
                    return const Center(child: Text('No matches.'));
                  }
                  return RadioGroup<String>(
                    groupValue: widget.selectedSlug,
                    onChanged: (slug) {
                      if (slug == null) return;
                      final client = visible.firstWhere((c) => c.slug == slug);
                      widget.onSelected(slug, client.name);
                    },
                    child: ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (_, i) => RadioListTile<String>(
                        title: Text(visible[i].name),
                        value: visible[i].slug,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Free-text entry for the stakeholder filters (`contractor`/`consultant`)
/// that are plain strings server-side with no enumerated options list — see
/// ProjectsController's doc comment on `selectedContractor`.
class _FreeTextFilterSheet extends StatefulWidget {
  final String title;
  final String hint;
  final String initial;
  final ValueChanged<String> onApply;

  const _FreeTextFilterSheet({
    required this.title,
    required this.hint,
    required this.initial,
    required this.onApply,
  });

  @override
  State<_FreeTextFilterSheet> createState() => _FreeTextFilterSheetState();
}

class _FreeTextFilterSheetState extends State<_FreeTextFilterSheet> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              onSubmitted: (value) => widget.onApply(value.trim()),
              decoration: InputDecoration(
                hintText: widget.hint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (widget.initial.isNotEmpty)
                  TextButton(
                    onPressed: () => widget.onApply(''),
                    child: const Text('Clear'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: () => widget.onApply(_controller.text.trim()),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Multi-select bottom sheet using selectable chips with a checkmark on the
/// active state — Private Projects' Typology/Category facet (client-side
/// OR-matched, see BuildingsTaxonomy) rather than the checkbox-list style
/// `_SearchableMultiSelectSheet` already used for County.
/// Multi-select tracker Category sheet — fetches the real category taxonomy
/// (`GET /projects/tracker-sections`) on open rather than a hardcoded list,
/// since Infrastructure/Private Developments each have their own real,
/// backend-driven categories with no fixed enum client-side.
class _CategorySelectSheet extends StatefulWidget {
  final String projectType;
  final Set<String> selected;
  final void Function(List<String> values, List<String> names) onApply;

  const _CategorySelectSheet({
    required this.projectType,
    required this.selected,
    required this.onApply,
  });

  @override
  State<_CategorySelectSheet> createState() => _CategorySelectSheetState();
}

class _CategorySelectSheetState extends State<_CategorySelectSheet> {
  final _service = ProjectsService();
  late final Future<TrackerSections> _future = _service.getTrackerSections(
    projectType: widget.projectType,
  );
  late final Set<String> _selected = {...widget.selected};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: FutureBuilder<TrackerSections>(
          future: _future,
          builder: (context, snap) {
            final groups = snap.data?.categoryPreview ?? const [];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Select Category',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text('${_selected.length} selected'),
                  ],
                ),
                const SizedBox(height: 14),
                if (!snap.hasData)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (groups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No categories published yet.'),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: groups.map((g) {
                      final active = _selected.contains(g.value);
                      return FilterChip(
                        label: Text(g.displayLabel),
                        selected: active,
                        showCheckmark: true,
                        onSelected: (value) => setState(() {
                          if (value) {
                            _selected.add(g.value);
                          } else {
                            _selected.remove(g.value);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (_selected.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(_selected.clear),
                        child: const Text('Clear'),
                      ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        final names = _selected
                            .map(
                              (v) => groups
                                  .firstWhere(
                                    (g) => g.value == v,
                                    orElse: () => TrackerSectionGroup(
                                      value: v,
                                      label: titleCaseFromSlug(v),
                                      totalCount: 0,
                                      projects: const [],
                                    ),
                                  )
                                  .displayLabel,
                            )
                            .toList();
                        widget.onApply(_selected.toList(), names);
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MultiSelectChipSheet extends StatefulWidget {
  final String title;
  final List<String> options;

  /// Real filter values matching [options] 1:1 (e.g. status slugs behind
  /// Title Case labels). Defaults to [options] itself when omitted, same as
  /// [_SearchableSelectSheet]'s `values`/`options` split.
  final List<String>? values;
  final Set<String> selected;
  final ValueChanged<List<String>> onApply;

  const _MultiSelectChipSheet({
    required this.title,
    required this.options,
    this.values,
    required this.selected,
    required this.onApply,
  });

  @override
  State<_MultiSelectChipSheet> createState() => _MultiSelectChipSheetState();
}

class _MultiSelectChipSheetState extends State<_MultiSelectChipSheet> {
  late final Set<String> _selected = {...widget.selected};

  @override
  Widget build(BuildContext context) {
    final values = widget.values ?? widget.options;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text('${_selected.length} selected'),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(widget.options.length, (i) {
                final option = widget.options[i];
                final value = values[i];
                final active = _selected.contains(value);
                return FilterChip(
                  label: Text(option),
                  selected: active,
                  showCheckmark: true,
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _selected.add(value);
                    } else {
                      _selected.remove(value);
                    }
                  }),
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_selected.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(_selected.clear),
                    child: const Text('Clear'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: () => widget.onApply(_selected.toList()),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Portfolio Segmentation tabs — All/Ongoing/Completed/Trending, shown only
/// on a filtered (entity) view, positioned directly above the project list.
/// Selecting a tab preserves every other active filter since it only ever
/// touches status/sort (see ProjectsController.selectTab).
class _PortfolioTabs extends StatefulWidget {
  final ProjectsController ctrl;
  const _PortfolioTabs({required this.ctrl});

  @override
  State<_PortfolioTabs> createState() => _PortfolioTabsState();
}

class _PortfolioTabsState extends State<_PortfolioTabs> {
  final _service = ProjectsService();
  String _signature = '';
  Future<Map<String, int>>? _countsFuture;

  String _signatureOf(ProjectsController ctrl) => [
    ctrl.projectType,
    ctrl.selectedContractor.value,
    ctrl.selectedConsultant.value,
    ctrl.selectedFinancier.value,
    ctrl.selectedClient.value,
    ctrl.selectedCategory.value,
    ctrl.selectedUser.value,
    ctrl.selectedCounty.value,
    ctrl.selectedSector.value,
  ].join('|');

  /// Best-effort counts, capped at 200 rows per bucket — there is no
  /// dedicated total-count endpoint on `GET projects`, so this approximates
  /// via the same entity filters with `perPage: 200`, same pragmatic pattern
  /// already used elsewhere in this codebase for unconfirmed/uncapped
  /// totals.
  Future<Map<String, int>> _fetchCounts(ProjectsController ctrl) async {
    Future<int> countFor(String? status) async {
      final result = await _service.getProjects(
        projectType: ctrl.projectType,
        status: status,
        county: ctrl.selectedCounty.value,
        sector: ctrl.selectedSector.value,
        contractor: ctrl.selectedContractor.value,
        consultant: ctrl.selectedConsultant.value,
        financier: ctrl.selectedFinancier.value,
        clientSlug: ctrl.selectedClient.value,
        categorySlug: ctrl.selectedCategory.value,
        submittedBy: ctrl.selectedUser.value,
        perPage: 200,
      );
      return result.length;
    }

    final all = await countFor(null);
    final ongoing = await countFor('ongoing');
    final completed = await countFor('completed');
    return {'all': all, 'ongoing': ongoing, 'completed': completed};
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ctrl = widget.ctrl;
      if (!ctrl.hasEntityFilter) return const SizedBox.shrink();

      final sig = _signatureOf(ctrl);
      if (sig != _signature || _countsFuture == null) {
        _signature = sig;
        _countsFuture = _fetchCounts(ctrl);
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: FutureBuilder<Map<String, int>>(
          future: _countsFuture,
          builder: (context, snap) {
            final counts = snap.data;
            String label(String base, String key) =>
                counts == null ? base : '$base (${counts[key]})';
            return SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _PortfolioTabChip(
                    label: label('All', 'all'),
                    active:
                        ctrl.selectedStatus.value.isEmpty &&
                        ctrl.selectedSort.value.isEmpty,
                    onTap: () => ctrl.selectTab(''),
                  ),
                  const SizedBox(width: 8),
                  _PortfolioTabChip(
                    label: label('Ongoing', 'ongoing'),
                    active: ctrl.selectedStatus.value == 'ongoing',
                    onTap: () => ctrl.selectTab('ongoing'),
                  ),
                  const SizedBox(width: 8),
                  _PortfolioTabChip(
                    label: label('Completed', 'completed'),
                    active: ctrl.selectedStatus.value == 'completed',
                    onTap: () => ctrl.selectTab('completed'),
                  ),
                  const SizedBox(width: 8),
                  _PortfolioTabChip(
                    label: 'Trending',
                    active: ctrl.selectedSort.value == 'trending',
                    onTap: () => ctrl.selectTab('trending'),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}

class _PortfolioTabChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _PortfolioTabChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0284C7) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.captionSlate,
          ),
        ),
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
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? _kBlue : _kBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _kBlue : _kDivider),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _kSubtext,
          ),
        ),
      ),
    );
  }
}

/// Client-side sort for the "Sort By" filter-bar control — see
/// `ProjectsController.clientSortBy`'s doc comment for why this isn't a
/// server-side `sort=` param.
List<Project> _sorted(List<Project> projects, String sortBy) {
  final sorted = [...projects];
  switch (sortBy) {
    case 'newest':
      sorted.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
      break;
    case 'recently_updated':
      sorted.sort((a, b) {
        final au = a.updatedAt ?? DateTime.tryParse(a.createdAt ?? '');
        final bu = b.updatedAt ?? DateTime.tryParse(b.createdAt ?? '');
        if (au == null && bu == null) return 0;
        if (au == null) return 1;
        if (bu == null) return -1;
        return bu.compareTo(au);
      });
      break;
    case 'budget_desc':
      sorted.sort((a, b) => (b.costKes ?? 0).compareTo(a.costKes ?? 0));
      break;
  }
  return sorted;
}
