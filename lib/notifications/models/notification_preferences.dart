class NotificationPreferences {
  final bool pushEnabled;
  final bool infrastructureProjects;
  final bool safetyIncidents;
  final bool editorialArticles;

  const NotificationPreferences({
    this.pushEnabled = true,
    this.infrastructureProjects = true,
    this.safetyIncidents = true,
    this.editorialArticles = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        pushEnabled:
            (json['push_enabled'] as bool?) ??
            (json['master_push_enabled'] as bool?) ??
            true,
        infrastructureProjects:
            (json['infrastructure_projects'] as bool?) ?? true,
        safetyIncidents: (json['safety_incidents'] as bool?) ?? true,
        editorialArticles: (json['editorial_articles'] as bool?) ?? true,
      );

  Map<String, dynamic> toJson() => {
    'push_enabled': pushEnabled,
    'infrastructure_projects': infrastructureProjects,
    'safety_incidents': safetyIncidents,
    'editorial_articles': editorialArticles,
  };
}
