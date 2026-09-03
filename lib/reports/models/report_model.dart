// lib/reports/models/report_model.dart
//
// Mirrors api.py's `_report_dict` (InfrastructureReport). This is the
// citizen-submitted "report broken infrastructure" feature on the website
// (templates/infrastructure_reports.html) — distinct from `lib/incidents/`,
// which covers road-safety / site-safety *incidents*.

/// Allowed `category` values — kept in sync with api.py's
/// VALID_REPORT_CATEGORIES. Sending anything else is a 400.
const List<String> kReportCategories = [
  'roads',
  'bridges',
  'buildings',
  'water',
  'electricity',
  'drainage',
  'other',
];

/// Allowed `severity` values — api.py's VALID_SEVERITIES.
const List<String> kReportSeverities = ['low', 'medium', 'high', 'critical'];

class InfrastructureReport {
  final int id;
  final String title;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String category;
  final String severity;
  final String status;
  final int upvotes;
  final int downvotes;
  final int viewCount;
  final bool isVerified;
  final DateTime? createdAt;

  // Detail-only (`full=True`)
  final String? description;
  final String? reporterName;

  const InfrastructureReport({
    required this.id,
    required this.title,
    this.location,
    this.latitude,
    this.longitude,
    this.category = 'other',
    this.severity = 'low',
    this.status = 'submitted',
    this.upvotes = 0,
    this.downvotes = 0,
    this.viewCount = 0,
    this.isVerified = false,
    this.createdAt,
    this.description,
    this.reporterName,
  });

  factory InfrastructureReport.fromJson(Map<String, dynamic> j) => InfrastructureReport(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: (j['title'] as String?) ?? '',
        location: j['location'] as String?,
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        category: (j['category'] as String?) ?? 'other',
        severity: (j['severity'] as String?) ?? 'low',
        status: (j['status'] as String?) ?? 'submitted',
        upvotes: (j['upvotes'] as num?)?.toInt() ?? 0,
        downvotes: (j['downvotes'] as num?)?.toInt() ?? 0,
        viewCount: (j['view_count'] as num?)?.toInt() ?? 0,
        isVerified: (j['is_verified'] as bool?) ?? false,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
        description: j['description'] as String?,
        reporterName: j['reporter_name'] as String?,
      );

  /// Copy used for optimistic vote updates.
  InfrastructureReport copyWith({int? upvotes, int? downvotes}) =>
      InfrastructureReport(
        id: id,
        title: title,
        location: location,
        latitude: latitude,
        longitude: longitude,
        category: category,
        severity: severity,
        status: status,
        upvotes: upvotes ?? this.upvotes,
        downvotes: downvotes ?? this.downvotes,
        viewCount: viewCount,
        isVerified: isVerified,
        createdAt: createdAt,
        description: description,
        reporterName: reporterName,
      );

  /// Human-readable time since submission, e.g. "2 d ago" — mirrors
  /// Article.timeAgo. Matches the website placeholder copy's intent
  /// ("Reported 2 days ago") without needing a full date/time library.
  String get timeAgo {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} yr ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} mo ago';
    if (diff.inDays >= 1) return '${diff.inDays} d ago';
    if (diff.inHours >= 1) return '${diff.inHours} h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes} min ago';
    return 'Just now';
  }
}
