// lib/incidents/models/incident_model.dart
const String _kBase = 'https://mjengohub.co.ke';

class Incident {
  final int id;
  final String incidentType;
  final String title;
  final String slug;
  final String? summary;
  final String? description;
  final String? location;
  final String? county;
  final String regionalScope;
  final String? imageCaption;
  final String? imageSourceCredit;
  final String? incidentDate;
  final String severity;
  final int? casualties;
  final int? injuries;
  final String? lessonsLearned;
  final String? recommendations;
  final String? source;
  final String? featuredImage;
  final bool isFeatured;
  final int viewCount;
  // Detail-only
  final List<IncidentMedia> media;
  final List<IncidentUpdate> updates;
  final List<IncidentComment> comments;

  const Incident({
    required this.id,
    required this.incidentType,
    required this.title,
    required this.slug,
    this.summary,
    this.description,
    this.location,
    this.county,
    this.regionalScope = 'Kenya',
    this.imageCaption,
    this.imageSourceCredit,
    this.incidentDate,
    required this.severity,
    this.casualties,
    this.injuries,
    this.lessonsLearned,
    this.recommendations,
    this.source,
    this.featuredImage,
    required this.isFeatured,
    required this.viewCount,
    this.media = const [],
    this.updates = const [],
    this.comments = const [],
  });

  factory Incident.fromJson(Map<String, dynamic> j) => Incident(
    id: (j['id'] as num).toInt(),
    incidentType: (j['incident_type'] as String?) ?? 'road_safety',
    title: (j['title'] as String?) ?? '',
    slug: (j['slug'] as String?) ?? '',
    summary: j['summary'] as String?,
    description: j['description'] as String?,
    location: j['location'] as String?,
    county: j['county'] as String?,
    regionalScope:
        (j['regional_scope'] as String?) ?? (j['region'] as String?) ?? 'Kenya',
    imageCaption: j['image_caption'] as String?,
    imageSourceCredit:
        (j['image_source_credit'] as String?) ??
        (j['source_credit'] as String?),
    incidentDate: j['incident_date'] as String?,
    severity: (j['severity'] as String?) ?? 'moderate',
    casualties: (j['casualties'] as num?)?.toInt(),
    injuries: (j['injuries'] as num?)?.toInt(),
    lessonsLearned: j['lessons_learned'] as String?,
    recommendations: j['recommendations'] as String?,
    source: j['source'] as String?,
    featuredImage: j['featured_image'] as String?,
    isFeatured: (j['is_featured'] as bool?) ?? false,
    viewCount: (j['view_count'] as num?)?.toInt() ?? 0,
    media:
        (j['media'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(IncidentMedia.fromJson)
            .toList() ??
        [],
    updates:
        (j['updates'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(IncidentUpdate.fromJson)
            .toList() ??
        [],
    comments:
        (j['comments'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(IncidentComment.fromJson)
            .toList() ??
        [],
  );

  String? get imageUrl {
    if (featuredImage == null || featuredImage!.isEmpty) return null;
    if (featuredImage!.startsWith('http')) return featuredImage;
    return '$_kBase/static/$featuredImage';
  }

  bool get isRoadSafety => incidentType == 'road_safety';
  int get views => viewCount;
  List<String> get paragraphs => (description ?? '')
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();

  String get formattedDate {
    if (incidentDate == null) return '';
    try {
      final d = DateTime.parse(incidentDate!);
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${d.day} ${months[d.month]} ${d.year}';
    } catch (_) {
      return incidentDate!;
    }
  }
}

/// Contract-facing name used by the web platform documentation.
typedef SafetyIncident = Incident;

class IncidentMedia {
  final int id;
  final String filePath;
  final String mediaType;
  final String? caption;

  const IncidentMedia({
    required this.id,
    required this.filePath,
    required this.mediaType,
    this.caption,
  });

  factory IncidentMedia.fromJson(Map<String, dynamic> j) => IncidentMedia(
    id: (j['id'] as num).toInt(),
    filePath: (j['file_path'] as String?) ?? '',
    mediaType: (j['media_type'] as String?) ?? 'image',
    caption: j['caption'] as String?,
  );

  String get url {
    if (filePath.startsWith('http')) return filePath;
    return '$_kBase/static/$filePath';
  }
}

class IncidentUpdate {
  final int id;
  final String? title;
  final String content;
  final String? createdAt;

  const IncidentUpdate({
    required this.id,
    this.title,
    required this.content,
    this.createdAt,
  });

  factory IncidentUpdate.fromJson(Map<String, dynamic> j) => IncidentUpdate(
    id: (j['id'] as num).toInt(),
    title: j['title'] as String?,
    content: (j['content'] as String?) ?? '',
    createdAt: j['created_at'] as String?,
  );

  String get formattedDate {
    if (createdAt == null) return '';
    try {
      final d = DateTime.parse(createdAt!);
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${d.day} ${months[d.month]} ${d.year}';
    } catch (_) {
      return '';
    }
  }
}

class IncidentComment {
  final int id;
  final String commenterName;
  final String content;
  final String? createdAt;
  final List<IncidentComment> replies;

  const IncidentComment({
    required this.id,
    required this.commenterName,
    required this.content,
    this.createdAt,
    this.replies = const [],
  });

  factory IncidentComment.fromJson(Map<String, dynamic> j) => IncidentComment(
    id: (j['id'] as num).toInt(),
    commenterName: (j['commenter_name'] as String?) ?? 'Anonymous',
    content: (j['content'] as String?) ?? '',
    createdAt: j['created_at'] as String?,
    replies:
        (j['replies'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(IncidentComment.fromJson)
            .toList() ??
        [],
  );

  String get formattedDate {
    if (createdAt == null) return '';
    try {
      final d = DateTime.parse(createdAt!);
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${d.day} ${months[d.month]} ${d.year}';
    } catch (_) {
      return '';
    }
  }
}
