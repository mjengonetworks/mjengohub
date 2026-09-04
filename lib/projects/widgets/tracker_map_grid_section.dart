// lib/projects/widgets/tracker_map_grid_section.dart
//
// The tracker's always-visible interactive map, pinned at the top of every
// tracker screen (Infrastructure, Private Developments, Built History,
// Africa & World) — color-coded status pins, tap-to-preview bottom sheet
// (see projects_map_view.dart's showProjectPreviewSheet). Not a grid/map
// toggle: the map and the project grid/list are both always shown, as two
// separate sections, matching the "top interactive live map" spec rather
// than the earlier toggle-based design.
import 'package:flutter/material.dart';

import '../../shared/widgets/coming_soon.dart';
import '../models/project_model.dart';
import 'projects_map_view.dart';
import 'tracker_project_card.dart';

class TrackerLiveMap extends StatelessWidget {
  final List<Project> projects;
  final bool loading;

  const TrackerLiveMap({super.key, required this.projects, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (projects.isEmpty) {
      return const SizedBox(
        height: 220,
        child: ComingSoonPlaceholder(
          icon: Icons.map_outlined,
          title: 'Nothing to map yet',
          message: 'Entries will appear here as pins once they have a location.',
        ),
      );
    }
    // Full-bleed, no horizontal padding — the map is the top-of-screen
    // anchor, edge-to-edge like the website's own #pj-map.
    return SizedBox(
      height: 300,
      child: ProjectsMapView(projects: projects),
    );
  }
}

/// Default grid pane for trackers that don't supply their own richer list
/// (Built History uses decade as the caption, Africa & World uses country;
/// ProjectsScreen — Infrastructure/Private — supplies its own row-tile list
/// instead of this).
class TrackerProjectsWrapGrid extends StatelessWidget {
  final List<Project> projects;
  final bool loading;
  final String Function(Project)? captionOf;
  final String emptyMessage;

  const TrackerProjectsWrapGrid({
    super.key,
    required this.projects,
    required this.loading,
    this.captionOf,
    this.emptyMessage = 'No entries match these filters yet. Try broadening your search.',
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
    }
    if (projects.isEmpty) {
      return ComingSoonPlaceholder(icon: Icons.search_off_rounded, title: 'Nothing here yet', message: emptyMessage);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: projects
            .map((p) => TrackerProjectCard(project: p, captionOverride: captionOf?.call(p), width: 220))
            .toList(),
      ),
    );
  }
}
