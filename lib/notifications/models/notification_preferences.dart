// Server contract for `GET`/`POST user/notification-preferences` isn't
// confirmed against a live api.py route yet (same status as the rest of the
// notification-settings feature) — field names below are this app's best
// guess and degrade to sane defaults (everything on) if the shape differs.
class NotificationPreferences {
  final bool pushEnabled;
  final bool breakingNewsMajorProjects;
  final bool documentedProgressUpdates;
  final bool siteSafetyAlerts;

  const NotificationPreferences({
    this.pushEnabled = true,
    this.breakingNewsMajorProjects = true,
    this.documentedProgressUpdates = true,
    this.siteSafetyAlerts = true,
  });

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? breakingNewsMajorProjects,
    bool? documentedProgressUpdates,
    bool? siteSafetyAlerts,
  }) => NotificationPreferences(
    pushEnabled: pushEnabled ?? this.pushEnabled,
    breakingNewsMajorProjects:
        breakingNewsMajorProjects ?? this.breakingNewsMajorProjects,
    documentedProgressUpdates:
        documentedProgressUpdates ?? this.documentedProgressUpdates,
    siteSafetyAlerts: siteSafetyAlerts ?? this.siteSafetyAlerts,
  );

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        pushEnabled:
            (json['push_enabled'] as bool?) ??
            (json['master_push_enabled'] as bool?) ??
            true,
        breakingNewsMajorProjects:
            (json['breaking_news_major_projects'] as bool?) ??
            (json['infrastructure_projects'] as bool?) ??
            true,
        documentedProgressUpdates:
            (json['documented_progress_updates'] as bool?) ?? true,
        siteSafetyAlerts:
            (json['site_safety_alerts'] as bool?) ??
            (json['safety_incidents'] as bool?) ??
            true,
      );

  Map<String, dynamic> toJson() => {
    'push_enabled': pushEnabled,
    'breaking_news_major_projects': breakingNewsMajorProjects,
    'documented_progress_updates': documentedProgressUpdates,
    'site_safety_alerts': siteSafetyAlerts,
  };
}
