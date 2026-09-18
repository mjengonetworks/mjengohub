// lib/projects/widgets/tracker_dynamic_sections.dart
//
// The three standardized interactive modules shown on every tracker screen
// (Infrastructure, Private Developments, Built History, Africa & World):
// Browse by Category, Most Viewed (48h/7d/30d tabs), By Status. One shared
// widget, parameterized by tracker discriminator, backed by
// `GET /projects/tracker-sections` — dropped into each tracker screen's
// existing scrollable content rather than four near-duplicate
// implementations.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../news/widgets/net_image.dart';
import '../../shared/theme/app_theme.dart';
import '../models/project_model.dart';
import '../models/tracker_sections_model.dart';
import '../screens/project_detail_screen.dart';
import '../screens/tracker_filtered_list_screen.dart';
import '../services/projects_service.dart';
import 'tracker_project_card.dart';

class TrackerDynamicSections extends StatefulWidget {
  final String? projectType;
  final bool? isBuiltHistory;
  final String? geoScope;

  const TrackerDynamicSections({
    super.key,
    this.projectType,
    this.isBuiltHistory,
    this.geoScope,
  });

  @override
  State<TrackerDynamicSections> createState() => _TrackerDynamicSectionsState();
}

class _TrackerDynamicSectionsState extends State<TrackerDynamicSections> {
  final _service = ProjectsService();
  late final Future<TrackerSections> _future = _service.getTrackerSections(
    projectType: widget.projectType,
    isBuiltHistory: widget.isBuiltHistory,
    geoScope: widget.geoScope,
  );

  void _openFiltered(
    String title,
    Future<List<Project>> Function(int page) fetcher, {
    String Function(Project)? captionOf,
    int perPage = 40,
  }) {
    Get.to(
      () => TrackerFilteredListScreen(
        title: title,
        fetcher: fetcher,
        captionOf: captionOf,
        perPage: perPage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TrackerSections>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final sections = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Browse by Category" always renders once this tracker has the
            // dimension at all (categoryPreview is a real, possibly-empty
            // list here, never omitted) — an empty tracker shows the
            // section with a placeholder rather than disappearing, matching
            // tracker_browse_sections.html's own "exists, just empty" intent.
            _Heading('Browse by Category'),
            if (sections.categoryPreview.isEmpty)
              const _EmptyNote('Nothing published in any category yet.')
            else
              ...sections.categoryPreview.map(
                (g) => _CategoryRow(
                  group: g,
                  onViewMore: () => _openFiltered(
                    g.displayLabel,
                    (page) => _service.getProjects(
                      projectType: widget.projectType,
                      isBuiltHistory: widget.isBuiltHistory,
                      geoScope: widget.geoScope,
                      // Built History/Africa & World use their fixed
                      // dimension (heritage_category/region) as the
                      // category value; Infrastructure/Private use a real
                      // ProjectCategory slug — both map onto the same
                      // `categorySlug`/`heritageCategory`/`region` params.
                      categorySlug:
                          (widget.isBuiltHistory != true &&
                              widget.geoScope == null)
                          ? g.value
                          : null,
                      heritageCategory: widget.isBuiltHistory == true
                          ? g.value
                          : null,
                      region: widget.geoScope == 'global' ? g.value : null,
                      page: page,
                      perPage: 40,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Most Viewed: the backend always returns 3 window entries
            // (each with its own per-window "no views yet" placeholder), so
            // this section always renders too.
            _MostViewedSection(
              windows: sections.mostViewedWindows,
              // The backend has no page/offset concept for "most viewed" —
              // it's a fixed top-N window, not a paginated list — so only
              // page 1 returns data; later pages report empty to stop the
              // list screen's infinite scroll after that single fetch.
              onViewMore: (window) => _openFiltered(
                'Most Viewed — ${_windowFullLabel(window.label)}',
                (page) => page > 1
                    ? Future.value(const <Project>[])
                    : _service
                          .getTrackerSections(
                            projectType: widget.projectType,
                            isBuiltHistory: widget.isBuiltHistory,
                            geoScope: widget.geoScope,
                            mostViewedLimit: 20,
                          )
                          .then(
                            (s) => s.mostViewedWindows
                                .firstWhere(
                                  (w) => w.label == window.label,
                                  orElse: () => window,
                                )
                                .projects,
                          ),
                perPage: 20,
              ),
            ),
            const SizedBox(height: 20),

            // "By Status" is genuinely omitted (not just empty) for Built
            // History — planned/ongoing makes no sense for heritage entries
            // that already exist, matching tracker_browse_sections.html's
            // `{% if status_preview is not none %}`.
            if (sections.statusPreview != null) ...[
              _Heading('By Status'),
              if (sections.statusPreview!.isEmpty)
                const _EmptyNote('Nothing published yet.')
              else
                ...sections.statusPreview!.map(
                  (g) => _CategoryRow(
                    group: g,
                    onViewMore: () => _openFiltered(
                      g.label,
                      (page) => _service.getProjects(
                        projectType: widget.projectType,
                        isBuiltHistory: widget.isBuiltHistory,
                        geoScope: widget.geoScope,
                        status: g.value,
                        page: page,
                        perPage: 40,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

String _windowFullLabel(String apiLabel) => switch (apiLabel) {
  '48h' => 'Past 48 Hours',
  '7d' => 'Past 7 Days',
  '30d' => 'Past 1 Month',
  _ => apiLabel,
};

class _Heading extends StatelessWidget {
  final String title;
  const _Heading(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}

/// Matches tracker_browse_sections.html's `.tbs-empty` placeholder — the
/// section header still renders so an empty tracker reads as "exists, just
/// empty" rather than looking like the feature is missing. Styled as a
/// left-accented card (not raw text) so a 0-item category/period/tracker
/// still reads as a deliberate, on-brand state.
class _EmptyNote extends StatelessWidget {
  final String message;
  final String title;
  const _EmptyNote(this.message, {this.title = 'Nothing here yet'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFCBD5E1)),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: Color(0xFF0284C7), width: 3.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                message,
                style: GoogleFonts.montserrat(
                  fontSize: 11.5,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final TrackerSectionGroup group;
  final VoidCallback onViewMore;
  const _CategoryRow({required this.group, required this.onViewMore});

  @override
  Widget build(BuildContext context) {
    if (group.projects.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    group.displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _CountBadge(count: group.totalCount),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (int i = 0; i < group.projects.length; i++) ...[
                  i == 0
                      ? _CategoryHeroTile(project: group.projects[i])
                      : _CategoryListTile(
                          project: group.projects[i],
                          tinted: i.isEven,
                        ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: onViewMore,
              child: Text(
                'View All ${group.displayLabel} (${group.totalCount}) →',
                style: GoogleFonts.montserrat(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accentBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small rounded count pill next to a category/status heading — mirrors
/// tracker_browse_sections.html's count badge (a separate pill, not text
/// appended in parentheses to the title).
class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.mutedCanvas,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSubtle,
        ),
      ),
    );
  }
}

/// Compact list row for "Browse by Category" groups (Roads, Trade, Sports,
/// Buildings, etc.) — a larger thumbnail than a plain avatar, with the title
/// given room to wrap to 2 lines rather than truncating early on multi-word
/// category names.
class _CategoryListTile extends StatelessWidget {
  final Project project;

  /// Alternating light-blue tint (#F0F7FF / #DBEAFE border) vs. clean white
  /// — zebra-striped like the app drawer's nav list, so a long category
  /// list stays scannable row-by-row.
  final bool tinted;
  const _CategoryListTile({required this.project, this.tinted = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(
        () => ProjectDetailScreen(slug: project.slug),
        transition: Transition.cupertino,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tinted ? const Color(0xFFF0F7FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: NetImage(
                url: project.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholderColor: const Color(0xFF1E3A5F),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if ((project.county ?? project.location ?? project.country) !=
                      null)
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 12,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            project.county ??
                                project.location ??
                                project.country!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 2),
                  Text(
                    project.statusLabel,
                    style: GoogleFonts.montserrat(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
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

/// First item in a "Browse by Category" list — a prominent full-width hero
/// card (banner image + stacked title/meta) so the category doesn't read as
/// a flat list of identical rows; every item after this one falls back to
/// [_CategoryListTile]'s compact horizontal layout.
class _CategoryHeroTile extends StatelessWidget {
  final Project project;
  const _CategoryHeroTile({required this.project});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(
        () => ProjectDetailScreen(slug: project.slug),
        transition: Transition.cupertino,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: NetImage(
                url: project.imageUrl,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                placeholderColor: const Color(0xFF1E3A5F),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if ((project.county ?? project.location ?? project.country) !=
                      null)
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 12,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            project.county ??
                                project.location ??
                                project.country!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 2),
                  Text(
                    project.statusLabel,
                    style: GoogleFonts.montserrat(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
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

class _MostViewedSection extends StatefulWidget {
  final List<MostViewedWindow> windows;
  final void Function(MostViewedWindow) onViewMore;
  const _MostViewedSection({required this.windows, required this.onViewMore});

  @override
  State<_MostViewedSection> createState() => _MostViewedSectionState();
}

class _MostViewedSectionState extends State<_MostViewedSection> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.windows.isEmpty) return const SizedBox.shrink();
    final window = widget.windows[_index.clamp(0, widget.windows.length - 1)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Most Viewed',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
              _WindowToggle(
                labels: widget.windows.map((w) => w.label).toList(),
                index: _index,
                onChanged: (i) => setState(() => _index = i),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (window.projects.isEmpty)
          _EmptyNote(
            'Nothing has picked up views in this window yet.',
            title: 'Most Viewed — ${window.label}',
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final project in window.projects) ...[
                  TrackerProjectCard(project: project, width: double.infinity),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8),
            child: GestureDetector(
              onTap: () => widget.onViewMore(window),
              child: Text(
                'View More',
                style: GoogleFonts.montserrat(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accentBlue,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _WindowToggle extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const _WindowToggle({
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (i) {
          final active = i == index;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: active ? AppColors.accentBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                // Short label inside the toggle pill itself — the fuller
                // "Past 48 Hours" wording is shown as the section context,
                // this stays compact ("48h"/"7d"/"30d" abbreviated further).
                labels[i]
                    .replaceAll('Past ', '')
                    .replaceAll(' Hours', 'h')
                    .replaceAll(' Days', 'd')
                    .replaceAll(' Month', '30d')
                    .replaceAll('1 30d', '30d'),
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: active ? Colors.white : AppColors.textSubtle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
