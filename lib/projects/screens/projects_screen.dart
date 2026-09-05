// lib/projects/screens/projects_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/app_header.dart';
import '../../news/widgets/net_image.dart';
import '../../point/routes/app_routes.dart';
import '../../shared/theme/app_theme.dart';
import '../controllers/projects_controller.dart';
import '../models/project_model.dart';
import '../widgets/tracker_dynamic_sections.dart';
import '../widgets/tracker_map_grid_section.dart';
import 'project_detail_screen.dart';

const _kBlue     = Color(0xFF2563EB);
const _kBg       = Color(0xFFF0F4FF);
const _kDark     = Color(0xFF1A1A2E);
const _kSubtext  = Color(0xFF8888AA);
const _kDivider  = Color(0xFFEEEEF5);
const _kCard     = Colors.white;

/// "Buildings" hierarchy (Spec 3) — client-side display/filter layer only.
/// The backend has no category/subcategory column on `Project` at all today
/// (confirmed: only a single free-text `project_type`), so this can't be a
/// real server-side taxonomy. Matching is done by keyword against
/// title/summary/location, which is best-effort, not authoritative.
class BuildingsTaxonomy {
  BuildingsTaxonomy._();

  static const subcategories = ['Residential', 'Commercial', 'Mixed Development'];
  static const types = ['Malls / Retail', 'Office Complex', 'Apartment Towers', 'Gated Community', 'Warehouses / Logistics'];

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
    final haystack = '${p.title} ${p.summary ?? ''} ${p.location ?? ''}'.toLowerCase();
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
    Key? key,
    this.title = 'Infrastructure Tracker',
    this.subtitle = "Kenya's roads, bridges & public infrastructure projects",
    this.projectType = 'infrastructure',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ProjectsController(projectType: projectType), tag: projectType);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: _kBlue,
          onPressed: () async {
            final submitted = await Get.toNamed(AppRoutes.submitProject, arguments: projectType);
            if (submitted == true) ctrl.fetchAll();
          },
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'Submit',
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
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
            child: Obx(() => ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    // 1. Top interactive live map — the very first scrollable
                    // item, directly beneath the app bar. Color-coded status
                    // pins, tap-to-preview bottom sheet. Never gated behind a
                    // toggle and never pushed below other content.
                    const SizedBox(height: 12),
                    TrackerLiveMap(projects: ctrl.projects, loading: false),
                    const SizedBox(height: 12),

                    // 2. Dedicated tracker control — status/county/client
                    // filter chips.
                    _buildStatusChips(ctrl),
                    if (ctrl.availableCounties.isNotEmpty) _buildCountyChips(ctrl),
                    if (ctrl.clients.isNotEmpty) _buildClientChips(ctrl),
                    if (projectType == 'private_development') _BuildingsTaxonomyFilter(ctrl: ctrl),

                    if (ctrl.featuredProjects.isNotEmpty) _buildFeaturedSection(ctrl),

                    // 3-5. Browse by Category / Most Viewed / By Status
                    const SizedBox(height: 12),
                    TrackerDynamicSections(projectType: ctrl.projectType),

                    // 6. All projects grid (paginated list feed)
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('All Projects',
                          style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500, color: _kDark)),
                    ),
                    const SizedBox(height: 10),
                    _buildProjectsGrid(ctrl),
                  ],
                )),
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
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 20, color: _kDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: _kDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.montserrat(fontSize: 12, color: _kSubtext),
          ),
          if (ctrl != null) ...[
            const SizedBox(height: 12),
            // Search bar
            TextField(
              onSubmitted: (q) => ctrl.applyFilters(
                status: ctrl.selectedStatus.value,
                clientSlug: ctrl.selectedClientSlug.value,
                county: ctrl.selectedCounty.value,
                q: q,
              ),
              style: GoogleFonts.montserrat(fontSize: 13.5, color: _kDark),
              decoration: InputDecoration(
                hintText: 'Search projects…',
                hintStyle:
                    GoogleFonts.montserrat(fontSize: 13, color: _kSubtext),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: _kSubtext, size: 20),
                filled: true,
                fillColor: _kBg,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
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

  static const _statusOptions = ['planned', 'ongoing', 'completed', 'stalled'];

  Widget _buildStatusChips(ProjectsController ctrl) {
    return Container(
      height: 42,
      color: _kCard,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _statusOptions.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return _FilterChip(
              label: 'All',
              selected: ctrl.selectedStatus.value.isEmpty,
              onTap: () => ctrl.applyFilters(
                status: '',
                clientSlug: ctrl.selectedClientSlug.value,
                county: ctrl.selectedCounty.value,
                q: ctrl.searchQuery.value,
              ),
            );
          }
          final status = _statusOptions[i - 1];
          return _FilterChip(
            label: Project.labelForStatus(status),
            selected: ctrl.selectedStatus.value == status,
            onTap: () => ctrl.applyFilters(
              status: status,
              clientSlug: ctrl.selectedClientSlug.value,
              county: ctrl.selectedCounty.value,
              q: ctrl.searchQuery.value,
            ),
          );
        },
      ),
    );
  }

  Widget _buildClientChips(ProjectsController ctrl) {
    return Container(
      height: 46,
      color: _kCard,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: ctrl.clients.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return _FilterChip(
              label: 'All',
              selected: ctrl.selectedClientSlug.value.isEmpty,
              onTap: () => ctrl.applyFilters(
                status: ctrl.selectedStatus.value,
                clientSlug: '',
                county: ctrl.selectedCounty.value,
                q: ctrl.searchQuery.value,
              ),
            );
          }
          final client = ctrl.clients[i - 1];
          return _FilterChip(
            label: client.name,
            selected: ctrl.selectedClientSlug.value == client.slug,
            onTap: () => ctrl.applyFilters(
              status: ctrl.selectedStatus.value,
              clientSlug: client.slug,
              county: ctrl.selectedCounty.value,
              q: ctrl.searchQuery.value,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCountyChips(ProjectsController ctrl) {
    final counties = ctrl.availableCounties;
    return Container(
      height: 42,
      color: _kCard,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: counties.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return _FilterChip(
              label: 'All Counties',
              selected: ctrl.selectedCounty.value.isEmpty,
              onTap: () => ctrl.applyFilters(
                status: ctrl.selectedStatus.value,
                clientSlug: ctrl.selectedClientSlug.value,
                county: '',
                q: ctrl.searchQuery.value,
              ),
            );
          }
          final county = counties[i - 1];
          return _FilterChip(
            label: county,
            selected: ctrl.selectedCounty.value == county,
            onTap: () => ctrl.applyFilters(
              status: ctrl.selectedStatus.value,
              clientSlug: ctrl.selectedClientSlug.value,
              county: county,
              q: ctrl.searchQuery.value,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedSection(ProjectsController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Notable Projects',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _kDark,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: ctrl.featuredProjects.length,
            itemBuilder: (_, i) =>
                _FeaturedProjectCard(project: ctrl.featuredProjects[i]),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: _kDivider),
      ],
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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kDivider),
          boxShadow: const [
            BoxShadow(
                color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _kDark,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (project.county != null || project.location != null)
                      Text(
                        '📍 ${project.county ?? project.location}',
                        style: GoogleFonts.montserrat(
                            fontSize: 10.5, color: _kSubtext),
                      ),
                    const Spacer(),
                    _ProgressBar(
                        value: project.progressPercent / 100,
                        label: '${project.progressPercent}%'),
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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kDivider),
          boxShadow: const [
            BoxShadow(
                color: Color(0x05000000), blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
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
                        if (project.client != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              project.client!.name,
                              style: GoogleFonts.montserrat(
                                  fontSize: 10, color: _kSubtext),
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
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _kDark,
                        height: 1.3,
                      ),
                    ),
                    if (project.county != null || project.location != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '📍 ${project.county ?? project.location}',
                        style: GoogleFonts.montserrat(
                            fontSize: 11, color: _kSubtext),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _ProgressBar(
                        value: project.progressPercent / 100,
                        label: '${project.progressPercent}% complete'),
                    if (project.averageRating != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '⭐ ${project.ratingDisplay} (${project.ratingCount} ratings)',
                        style: GoogleFonts.montserrat(
                            fontSize: 10.5, color: _kSubtext),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12, top: 12),
              child: Icon(Icons.chevron_right_rounded,
                  color: _kSubtext, size: 20),
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
            Text('Progress',
                style: GoogleFonts.montserrat(
                    fontSize: 10, color: _kSubtext)),
            Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _kBlue)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: _kDivider,
            valueColor: const AlwaysStoppedAnimation<Color>(_kBlue),
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
      case 'completed': return const Color(0xFF16A34A);
      case 'ongoing': return _kBlue;
      case 'planned': return const Color(0xFFF59E0B);
      case 'stalled':
      case 'cancelled': return const Color(0xFFDC2626);
      default: return _kSubtext;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
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
  State<_BuildingsTaxonomyFilter> createState() => _BuildingsTaxonomyFilterState();
}

class _BuildingsTaxonomyFilterState extends State<_BuildingsTaxonomyFilter> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final allChips = [...BuildingsTaxonomy.subcategories, ...BuildingsTaxonomy.types];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Buildings', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.captionSlate)),
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
                return _FilterChip(label: 'All', selected: _selected == null, onTap: () => setState(() => _selected = null));
              }
              final label = allChips[i - 1];
              return _FilterChip(label: label, selected: _selected == label, onTap: () => setState(() => _selected = label));
            },
          ),
        ),
        if (_selected != null)
          Obx(() {
            final matches = widget.ctrl.projects.where((p) => BuildingsTaxonomy.matches(p, _selected!)).toList();
            if (matches.isEmpty) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Text('No loaded projects match "$_selected" yet.',
                    style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.captionSlate)),
              );
            }
            return SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                itemCount: matches.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _FeaturedProjectCard(project: matches[i]),
              ),
            );
          }),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

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
          border: Border.all(
            color: selected ? _kBlue : _kDivider,
          ),
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
