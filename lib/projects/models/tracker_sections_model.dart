// lib/projects/models/tracker_sections_model.dart
//
// `GET /projects/tracker-sections` — the three standardized modules shown
// on every tracker screen (Browse by Category, Most Viewed in a time
// window, By Status). Backed by the exact same helper functions
// (get_fixed_category_preview / get_most_viewed_projects / get_status_preview)
// the web tracker pages already use, so this can never drift from them.
import 'project_model.dart';

class TrackerSectionGroup {
  final String value;
  final String label;
  final int totalCount;
  final List<Project> projects;

  const TrackerSectionGroup({required this.value, required this.label, required this.totalCount, required this.projects});

  factory TrackerSectionGroup.fromJson(Map<String, dynamic> j) => TrackerSectionGroup(
        value: (j['value'] as String?) ?? '',
        label: (j['label'] as String?) ?? '',
        totalCount: (j['total_count'] as num?)?.toInt() ?? 0,
        projects: (j['projects'] as List?)?.whereType<Map<String, dynamic>>().map(Project.fromJson).toList() ?? [],
      );
}

class MostViewedWindow {
  final String label; // '48h' | '7d' | '30d'
  final int windowHours;
  final List<Project> projects;

  const MostViewedWindow({required this.label, required this.windowHours, required this.projects});

  factory MostViewedWindow.fromJson(Map<String, dynamic> j) => MostViewedWindow(
        label: (j['label'] as String?) ?? '',
        windowHours: (j['window_hours'] as num?)?.toInt() ?? 0,
        projects: (j['projects'] as List?)?.whereType<Map<String, dynamic>>().map(Project.fromJson).toList() ?? [],
      );
}

class TrackerSections {
  final List<TrackerSectionGroup> categoryPreview;
  final List<TrackerSectionGroup>? statusPreview; // null for Built History (no status dimension)
  final List<MostViewedWindow> mostViewedWindows;

  const TrackerSections({this.categoryPreview = const [], this.statusPreview, this.mostViewedWindows = const []});

  factory TrackerSections.fromJson(Map<String, dynamic> j) => TrackerSections(
        categoryPreview: (j['category_preview'] as List?)?.whereType<Map<String, dynamic>>().map(TrackerSectionGroup.fromJson).toList() ?? [],
        statusPreview: (j['status_preview'] as List?)?.whereType<Map<String, dynamic>>().map(TrackerSectionGroup.fromJson).toList(),
        mostViewedWindows: (j['most_viewed_windows'] as List?)?.whereType<Map<String, dynamic>>().map(MostViewedWindow.fromJson).toList() ?? [],
      );

  static const empty = TrackerSections();
}
