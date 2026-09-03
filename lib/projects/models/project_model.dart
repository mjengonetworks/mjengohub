// lib/projects/models/project_model.dart
const String _kBase = 'https://mjengohub.co.ke';

class ProjectClient {
  final int id;
  final String name;
  final String slug;
  final String? logo;
  final String? clientType;

  /// Admin-set external site for the client (ministry / developer homepage).
  final String? websiteUrl;

  const ProjectClient({
    required this.id,
    required this.name,
    required this.slug,
    this.logo,
    this.clientType,
    this.websiteUrl,
  });

  factory ProjectClient.fromJson(Map<String, dynamic> j) => ProjectClient(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: (j['name'] as String?) ?? '',
        slug: (j['slug'] as String?) ?? '',
        logo: j['logo'] as String?,
        clientType: j['client_type'] as String?,
        websiteUrl: j['website_url'] as String?,
      );

  String? get logoUrl {
    if (logo == null || logo!.isEmpty) return null;
    if (logo!.startsWith('http')) return logo;
    return '$_kBase/static/$logo';
  }
}

/// `GET clients/{slug}` adds `description` + `project_count` on top of the
/// list-shaped [ProjectClient]. Kept as a separate class so the list model
/// stays a cheap value object.
class ProjectClientDetail {
  final ProjectClient client;
  final String? description;
  final int projectCount;

  const ProjectClientDetail({
    required this.client,
    this.description,
    this.projectCount = 0,
  });

  factory ProjectClientDetail.fromJson(Map<String, dynamic> j) => ProjectClientDetail(
        client: ProjectClient.fromJson(j),
        description: j['description'] as String?,
        projectCount: (j['project_count'] as num?)?.toInt() ?? 0,
      );

  int get id => client.id;
  String get name => client.name;
  String get slug => client.slug;
  String? get logoUrl => client.logoUrl;
  String? get clientType => client.clientType;
  String? get websiteUrl => client.websiteUrl;
}

class ProjectMilestone {
  final int id;
  final String title;
  final String? description;
  final String? milestoneDate;
  final String? milestoneType;
  final bool isAchieved;
  final int sortOrder;

  /// Up to 5 photos attached to this milestone (`_milestone_dict` in api.py).
  final List<ProjectMedia> media;

  const ProjectMilestone({
    required this.id,
    required this.title,
    this.description,
    this.milestoneDate,
    this.milestoneType,
    required this.isAchieved,
    this.sortOrder = 0,
    this.media = const [],
  });

  factory ProjectMilestone.fromJson(Map<String, dynamic> j) => ProjectMilestone(
        id: (j['id'] as num).toInt(),
        title: (j['title'] as String?) ?? '',
        description: j['description'] as String?,
        milestoneDate: j['milestone_date'] as String?,
        milestoneType: j['milestone_type'] as String?,
        isAchieved: (j['is_achieved'] as bool?) ?? false,
        sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
        media: (j['media'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(ProjectMedia.fromJson)
                .toList() ??
            [],
      );
}

class ProjectMedia {
  final int id;
  final String filePath;
  final String mediaType;
  final String? caption;
  final String? credit;
  final String? monthYear;
  final bool isFeatured;

  /// 'progress' (real on-site photos) or 'render' (architectural renders /
  /// artistic impressions), mirroring the website's `media_kind` column.
  /// Exposed by `_project_media_dict` in api.py; defaults to 'progress' for
  /// older rows where the admin never set it.
  final String mediaKind;

  const ProjectMedia({
    required this.id,
    required this.filePath,
    required this.mediaType,
    this.caption,
    this.credit,
    this.monthYear,
    required this.isFeatured,
    this.mediaKind = 'progress',
  });

  factory ProjectMedia.fromJson(Map<String, dynamic> j) => ProjectMedia(
        id: (j['id'] as num).toInt(),
        filePath: (j['file_path'] as String?) ?? '',
        mediaType: (j['media_type'] as String?) ?? 'image',
        caption: j['caption'] as String?,
        credit: j['credit'] as String?,
        monthYear: j['month_year'] as String?,
        isFeatured: (j['is_featured'] as bool?) ?? false,
        mediaKind: (j['media_kind'] as String?) ?? 'progress',
      );

  bool get isRender => mediaKind == 'render';

  String get url {
    if (filePath.startsWith('http')) return filePath;
    return '$_kBase/static/$filePath';
  }
}

class Project {
  final int id;
  final String title;
  final String slug;
  final String? summary;
  final String? description;
  final String? location;
  final String? county;
  final ProjectClient? client;
  final String? contractor;
  final String? consultant;
  final int progressPercent;
  final String status;

  /// 'infrastructure' (public tracker, the default) or 'private_development'
  /// (Private Projects) — same `Project` row shape, filtered views. Both the
  /// Infrastructure Tracker and Private Projects screens filter on this via
  /// `GET projects?project_type=...` so the two trackers never mix rows.
  final String projectType;

  final String? featuredImage;
  final bool isFeatured;
  final double? averageRating;
  final int ratingCount;
  final int viewCount;
  final String? startDate;
  final String? expectedEndDate;
  final String? createdAt;
  // Detail-only
  final double? contractValue;
  final String? actualEndDate;
  final List<ProjectMilestone> milestones;
  final List<ProjectMedia> media;
  final List<ProjectMedia> featuredMedia;

  const Project({
    required this.id,
    required this.title,
    required this.slug,
    this.summary,
    this.description,
    this.location,
    this.county,
    this.client,
    this.contractor,
    this.consultant,
    required this.progressPercent,
    required this.status,
    this.projectType = 'infrastructure',
    this.featuredImage,
    required this.isFeatured,
    this.averageRating,
    required this.ratingCount,
    required this.viewCount,
    this.startDate,
    this.expectedEndDate,
    this.createdAt,
    this.contractValue,
    this.actualEndDate,
    this.milestones = const [],
    this.media = const [],
    this.featuredMedia = const [],
  });

  factory Project.fromJson(Map<String, dynamic> j) => Project(
        id: (j['id'] as num).toInt(),
        title: (j['title'] as String?) ?? '',
        slug: (j['slug'] as String?) ?? '',
        summary: j['summary'] as String?,
        description: j['description'] as String?,
        location: j['location'] as String?,
        county: j['county'] as String?,
        client: j['client'] != null
            ? ProjectClient.fromJson(j['client'] as Map<String, dynamic>)
            : null,
        contractor: j['contractor'] as String?,
        consultant: j['consultant'] as String?,
        progressPercent: (j['progress_percent'] as num?)?.toInt() ?? 0,
        status: (j['status'] as String?) ?? 'ongoing',
        projectType: (j['project_type'] as String?) ?? 'infrastructure',
        featuredImage: j['featured_image'] as String?,
        isFeatured: (j['is_featured'] as bool?) ?? false,
        averageRating: (j['average_rating'] as num?)?.toDouble(),
        ratingCount: (j['rating_count'] as num?)?.toInt() ?? 0,
        viewCount: (j['view_count'] as num?)?.toInt() ?? 0,
        startDate: j['start_date'] as String?,
        expectedEndDate: j['expected_end_date'] as String?,
        createdAt: j['created_at'] as String?,
        contractValue: (j['contract_value'] as num?)?.toDouble(),
        actualEndDate: j['actual_end_date'] as String?,
        milestones: (j['milestones'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(ProjectMilestone.fromJson)
                .toList() ??
            [],
        media: (j['media'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(ProjectMedia.fromJson)
                .toList() ??
            [],
        featuredMedia: (j['featured_media'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(ProjectMedia.fromJson)
                .toList() ??
            [],
      );

  List<ProjectMedia> get renderGallery => media.where((m) => m.isRender).toList();
  List<ProjectMedia> get progressGallery => media.where((m) => !m.isRender).toList();

  String? get imageUrl {
    if (featuredImage == null || featuredImage!.isEmpty) return null;
    if (featuredImage!.startsWith('http')) return featuredImage;
    return '$_kBase/static/$featuredImage';
  }

  String get statusLabel => labelForStatus(status);

  /// Matches the backend's `project_status_enum` exactly: planned, ongoing,
  /// completed, stalled, cancelled. The previous 'suspended' case never
  /// matched a real value, so stalled/cancelled projects fell through to the
  /// raw lowercase enum string instead of a proper label. Static so callers
  /// (status filter chips, badges) can label a status without a Project
  /// instance on hand.
  static String labelForStatus(String status) {
    switch (status) {
      case 'planned': return 'Planned';
      case 'ongoing': return 'Ongoing';
      case 'completed': return 'Completed';
      case 'stalled': return 'Stalled';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }

  String? get ratingDisplay =>
      averageRating != null ? '${averageRating!.toStringAsFixed(1)}/10' : null;
}
