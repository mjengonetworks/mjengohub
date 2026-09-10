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
    Future<List<Project>> Function() fetcher, {
    String Function(Project)? captionOf,
  }) {
    Get.to(
      () => TrackerFilteredListScreen(
        title: title,
        fetcher: fetcher,
        captionOf: captionOf,
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
                    () => _service.getProjects(
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
              onViewMore: (window) => _openFiltered(
                'Most Viewed — ${_windowFullLabel(window.label)}',
                () => _service
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
                      () => _service.getProjects(
                        projectType: widget.projectType,
                        isBuiltHistory: widget.isBuiltHistory,
                        geoScope: widget.geoScope,
                        status: g.value,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${group.displayLabel} (${group.totalCount})',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                if (group.totalCount > group.projects.length)
                  GestureDetector(
                    onTap: onViewMore,
                    child: Text(
                      'View More',
                      style: GoogleFonts.montserrat(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final project in group.projects) ...[
                  _CategoryListTile(project: project),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
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
  const _CategoryListTile({required this.project});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(
        () => ProjectDetailScreen(slug: project.slug),
        transition: Transition.cupertino,
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSlate),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: NetImage(
                url: project.imageUrl,
                width: 90,
                height: 68,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  if ((project.county ?? project.location ?? project.country) !=
                      null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 11,
                          color: AppColors.textSubtle,
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
                              fontSize: 10.5,
                              color: AppColors.textSubtle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    project.statusLabel,
                    style: GoogleFonts.montserrat(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accentBlue,
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
