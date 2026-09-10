// lib/projects/screens/projects_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/app_header.dart';
import '../../news/widgets/net_image.dart';
import '../../point/routes/app_routes.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/responsive.dart';
import '../controllers/projects_controller.dart';
import '../models/project_model.dart';
import '../services/projects_service.dart';
import 'project_detail_screen.dart';

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

  ProjectsScreen({
    super.key,
    this.title = 'Infrastructure Tracker',
    this.subtitle = "Kenya's roads, bridges & public infrastructure projects",
    this.projectType = 'infrastructure',
  });

  /// Backs the hero banner's "Quick Search" pill — focuses the search field
  /// already in [_buildHeader] rather than duplicating a second search UI.
  /// A fresh instance per pushed route (this widget isn't reused across
  /// navigations), not disposed — same pragmatic style already used
  /// elsewhere in this file rather than introducing a StatefulWidget just
  /// for one FocusNode.
  final FocusNode _searchFocusNode = FocusNode();

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
  void _applyIncomingEntityArgs(ProjectsController ctrl) {
    final args = Get.arguments;
    if (args is! Map) return;
    final contractor = args['contractor'] as String?;
    final consultant = args['consultant'] as String?;
    final financier = args['financier'] as String?;
    final client = args['client'] as String?;
    final clientName = args['clientName'] as String?;
    final category = args['category'] as String?;
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
    if (!changed) return;
    ctrl.applyFilters(
      contractor: contractor,
      consultant: consultant,
      financier: financier,
      client: client,
      clientName: clientName,
      category: category,
      county: county,
      user: user,
      userName: userName,
    );
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
      return 'Projects by ${ctrl.selectedConsultant.value}';
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
    return title;
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
      return 'Design & consultancy works by ${ctrl.selectedConsultant.value}';
    }
    return subtitle;
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
            'Submit',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        body: Column(
          children: [
            const AppHeader(),
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
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    // 1. Top interactive live map — the very first scrollable
                    // item, directly beneath the app bar. Color-coded status
                    // pins, tap-to-preview bottom sheet. Never gated behind a
                    // toggle and never pushed below other content.
                    const SizedBox(height: 12),
                    _buildHeroBanner(ctrl),
                    _buildFeaturedStrip(ctrl),
                    _buildFilterControls(context, ctrl),
                    _buildActiveEntityFilters(ctrl),
                    const SizedBox(height: 12),

                    // 2. Dedicated tracker control — status/county/client
                    // filter chips.
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
                          color: _kDark,
                        ),
                      )
                    : Obx(
                        () => Text(
                          _dynamicTitle(ctrl),
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: _kDark,
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
            // Search bar
            TextField(
              focusNode: _searchFocusNode,
              onSubmitted: (q) => ctrl.applyFilters(
                status: ctrl.selectedStatus.value,
                county: ctrl.selectedCounty.value,
                sector: ctrl.selectedSector.value,
                q: q,
              ),
              style: GoogleFonts.montserrat(fontSize: 13.5, color: _kDark),
              decoration: InputDecoration(
                hintText: 'Search projects…',
                hintStyle: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: _kSubtext,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _kSubtext,
                  size: 20,
                ),
                filled: true,
                fillColor: _kBg,
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
          ],
        ],
      ),
    );
  }

  /// Full-bleed hero banner at the top of the feed — background is the
  /// first currently-loaded featured project's image (falls back to a flat
  /// gradient, not a bundled asset: no `hero_bg.jpg`-style placeholder is
  /// registered in pubspec.yaml/assets/, so referencing one would crash).
  Widget _buildHeroBanner(ProjectsController ctrl) {
    return Obx(() {
      // Filtered views (a tapped client/contractor/etc.) must never show a
      // global featured project's photo — it reads as unrelated content.
      // Fall back to the first row of the already-filtered result set.
      String? bgUrl;
      if (ctrl.hasEntityFilter) {
        bgUrl = ctrl.projects.isNotEmpty ? ctrl.projects.first.imageUrl : null;
      } else {
        final featured = ctrl.projects.where((p) => p.isFeatured).toList();
        bgUrl = featured.isNotEmpty ? featured.first.imageUrl : null;
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 240,
            child: Stack(
              fit: StackFit.expand,
              children: [
                NetImage(
                  url: bgUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholderColor: _kDark,
                  errorBuilder: (_) => Container(color: _kDark),
                ),
                DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xD10F172A), Color(0xF00F172A)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        title == 'Infrastructure Tracker'
                            ? "Kenya's Infrastructure Projects"
                            : title,
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Track road, bridge, building, and public '
                        'infrastructure projects: progress, milestones, '
                        'and ratings.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: const Color(0xFFCBD5E1),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              final submitted = await Get.toNamed(
                                AppRoutes.submitProject,
                                arguments: projectType,
                              );
                              if (submitted == true) ctrl.fetchAll();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              '+ Submit a Project',
                              style: GoogleFonts.montserrat(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () => FocusScope.of(
                              Get.context!,
                            ).requestFocus(_searchFocusNode),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.12,
                              ),
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: Text(
                              '🔍 Quick Search',
                              style: GoogleFonts.montserrat(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
      // (e.g. Talanta Stadium showing up under "Projects by KeNHA").
      if (ctrl.hasEntityFilter) return const SizedBox.shrink();
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
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
                value: _statusLabel(ctrl.selectedStatus.value),
                icon: Icons.timelapse_outlined,
                onTap: () => _showSingleSelectSheet(
                  context,
                  title: 'Select Status',
                  options: const [
                    'Announced',
                    'Under Construction',
                    'Completed',
                    'Stalled',
                  ],
                  values: const ['planned', 'ongoing', 'completed', 'stalled'],
                  selected: ctrl.selectedStatus.value,
                  onSelected: (value) => ctrl.applyFilters(status: value),
                ),
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
                    ctrl.fetchAll();
                  },
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

  String _statusLabel(String status) => switch (status) {
    'planned' => 'Announced',
    'ongoing' => 'Under Construction',
    'completed' => 'Completed',
    'stalled' => 'Stalled',
    _ => 'All statuses',
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
    if (ctrl.projects.isEmpty) {
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
        children: ctrl.projects
            .map((p) => _ProjectListTile(project: p))
            .toList(),
      ),
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
                      const Spacer(),
                      Text(
                        '${project.progressPercent}%',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  if (project.county != null || project.location != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '📍 ${project.county ?? project.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: project.progressPercent / 100,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF10B981),
                        ),
                      ),
                    ),
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
                aspectRatio: 16 / 9,
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
                      label: '${project.progressPercent}%',
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
                    // Status badge
                    Row(
                      children: [
                        _StatusBadge(status: project.status),
                        const SizedBox(width: 6),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        height: 1.3,
                      ),
                    ),
                    if (project.county != null || project.location != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '📍 ${project.county ?? project.location}',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: _kSubtext,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
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
                      label: '${project.progressPercent}% complete',
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
  final String label;
  const _ProgressBar({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: GoogleFonts.montserrat(fontSize: 10, color: _kSubtext),
            ),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _kBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 4,
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor: _kDivider,
              valueColor: const AlwaysStoppedAnimation<Color>(_kBlue),
            ),
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
