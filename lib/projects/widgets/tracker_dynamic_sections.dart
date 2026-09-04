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

import '../../shared/theme/app_theme.dart';
import '../models/project_model.dart';
import '../models/tracker_sections_model.dart';
import '../screens/tracker_filtered_list_screen.dart';
import '../services/projects_service.dart';
import 'tracker_project_card.dart';

class TrackerDynamicSections extends StatefulWidget {
  final String? projectType;
  final bool? isBuiltHistory;
  final String? geoScope;

  const TrackerDynamicSections({super.key, this.projectType, this.isBuiltHistory, this.geoScope});

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

  void _openFiltered(String title, Future<List<Project>> Function() fetcher, {String Function(Project)? captionOf}) {
    Get.to(() => TrackerFilteredListScreen(title: title, fetcher: fetcher, captionOf: captionOf));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TrackerSections>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }
        final sections = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sections.categoryPreview.isNotEmpty) ...[
              _Heading('Browse by Category'),
              ...sections.categoryPreview.map((g) => _CategoryRow(
                    group: g,
                    onViewMore: () => _openFiltered(
                      g.label,
                      () => _service.getProjects(
                        projectType: widget.projectType,
                        isBuiltHistory: widget.isBuiltHistory,
                        geoScope: widget.geoScope,
                        // Built History/Africa & World use their fixed
                        // dimension (heritage_category/region) as the
                        // category value; Infrastructure/Private use a real
                        // ProjectCategory slug — both map onto the same
                        // `categorySlug`/`heritageCategory`/`region` params.
                        categorySlug: (widget.isBuiltHistory != true && widget.geoScope == null) ? g.value : null,
                        heritageCategory: widget.isBuiltHistory == true ? g.value : null,
                        region: widget.geoScope == 'global' ? g.value : null,
                        perPage: 40,
                      ),
                    ),
                  )),
              const SizedBox(height: 20),
            ],
            if (sections.mostViewedWindows.isNotEmpty) ...[
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
                      .then((s) => s.mostViewedWindows.firstWhere((w) => w.label == window.label, orElse: () => window).projects),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (sections.statusPreview != null && sections.statusPreview!.isNotEmpty) ...[
              _Heading('By Status'),
              ...sections.statusPreview!.map((g) => _CategoryRow(
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
                  )),
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
      child: Text(title, style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
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
                  child: Text('${group.label} (${group.totalCount})',
                      style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                ),
                if (group.totalCount > group.projects.length)
                  GestureDetector(
                    onTap: onViewMore,
                    child: Text('View More', style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.accentBlue)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: group.projects.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => TrackerProjectCard(project: group.projects[i], width: 190),
            ),
          ),
        ],
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
    final window = widget.windows[_index.clamp(0, widget.windows.length - 1)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Most Viewed', style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('No views yet in this window.', style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textSubtle)),
          )
        else ...[
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: window.projects.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => TrackerProjectCard(project: window.projects[i], width: 190),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8),
            child: GestureDetector(
              onTap: () => widget.onViewMore(window),
              child: Text('View More', style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.accentBlue)),
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
  const _WindowToggle({required this.labels, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.divider)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (i) {
          final active = i == index;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(color: active ? AppColors.accentBlue : Colors.transparent, borderRadius: BorderRadius.circular(999)),
              child: Text(
                // Short label inside the toggle pill itself — the fuller
                // "Past 48 Hours" wording is shown as the section context,
                // this stays compact ("48h"/"7d"/"30d" abbreviated further).
                labels[i].replaceAll('Past ', '').replaceAll(' Hours', 'h').replaceAll(' Days', 'd').replaceAll(' Month', '30d').replaceAll('1 30d', '30d'),
                style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.textSubtle),
              ),
            ),
          );
        }),
      ),
    );
  }
}
