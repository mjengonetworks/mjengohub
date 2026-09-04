// lib/projects/widgets/tracker_map_grid_section.dart
//
// Grid/Map toggle + pane, shared across all 4 tracker screens — mirrors
// every tracker template's own Grid/Map view toggle (projects.html's
// #pj-map, built_history.html's .bh-views, africa_world.html's .aw-views):
// Grid is the default view, Map is reachable via the toggle button, both
// panes show the exact same underlying project list. This is the tracker's
// "all projects" feed, not a separate section from it — the web templates
// render the same paginated project list either as cards or as map pins,
// never both/neither.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/coming_soon.dart';
import '../models/project_model.dart';
import 'projects_map_view.dart';
import 'tracker_project_card.dart';

class TrackerMapGridSection extends StatefulWidget {
  final List<Project> projects;
  final bool loading;

  /// The "Grid" pane's content when there are projects to show. Left null
  /// to fall back to a generic Wrap of TrackerProjectCard (used by Built
  /// History/Africa & World); ProjectsScreen passes its own richer
  /// row-tile list here instead so that per-screen styling isn't lost.
  final Widget? gridChild;

  /// Per-card bottom-left caption override for the default Wrap grid (e.g.
  /// decade for Built History, country for Africa & World) — ignored when
  /// [gridChild] is provided.
  final String Function(Project)? captionOf;

  final String emptyMessage;

  const TrackerMapGridSection({
    super.key,
    required this.projects,
    required this.loading,
    this.gridChild,
    this.captionOf,
    this.emptyMessage = 'No entries match these filters yet. Try broadening your search.',
  });

  @override
  State<TrackerMapGridSection> createState() => _TrackerMapGridSectionState();
}

class _TrackerMapGridSectionState extends State<TrackerMapGridSection> {
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerRight,
            child: _ViewToggle(showMap: _showMap, onChanged: (v) => setState(() => _showMap = v)),
          ),
        ),
        const SizedBox(height: 10),
        if (widget.loading)
          const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
        else if (widget.projects.isEmpty)
          ComingSoonPlaceholder(icon: Icons.search_off_rounded, title: 'Nothing here yet', message: widget.emptyMessage)
        else if (_showMap)
          SizedBox(
            height: 420,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ProjectsMapView(projects: widget.projects),
              ),
            ),
          )
        else if (widget.gridChild != null)
          widget.gridChild!
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.projects
                  .map((p) => TrackerProjectCard(project: p, captionOverride: widget.captionOf?.call(p), width: 220))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final bool showMap;
  final ValueChanged<bool> onChanged;
  const _ViewToggle({required this.showMap, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget pill(String label, IconData icon, bool active, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: active ? AppColors.textDark : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: active ? AppColors.textDark : AppColors.divider),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: active ? Colors.white : AppColors.textSubtle),
                const SizedBox(width: 5),
                Text(label, style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.textSubtle)),
              ],
            ),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        pill('Grid', Icons.grid_view_rounded, !showMap, () => onChanged(false)),
        const SizedBox(width: 8),
        pill('Map', Icons.map_rounded, showMap, () => onChanged(true)),
      ],
    );
  }
}
