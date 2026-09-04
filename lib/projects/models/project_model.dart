// lib/projects/models/project_model.dart
const String _kBase = 'https://mjengohub.co.ke';

double? _parseCoord(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

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

/// A single credited team member/firm on a project (contractor, architect,
/// engineer, quantity surveyor) — mirrors `ProjectTeamMember` in models.py.
class ProjectTeamMember {
  final int id;
  final String role;
  final String name;
  final String? url;

  const ProjectTeamMember({required this.id, required this.role, required this.name, this.url});

  factory ProjectTeamMember.fromJson(Map<String, dynamic> j) => ProjectTeamMember(
        id: (j['id'] as num?)?.toInt() ?? 0,
        role: (j['role'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        url: j['url'] as String?,
      );
}

/// A crowdsourced progress update — `_update_dict` in api.py. Auto-approved
/// when posted by MODERATOR/EDITOR/ADMIN, otherwise lands in the review
/// queue (`isApproved=false`) until an admin approves it.
class ProjectUpdate {
  final int id;
  final int projectId;
  final int userId;
  final String? authorName;
  final String? authorAvatar;
  final String content;
  final String? externalVideoUrl;
  final bool isApproved;
  final List<ProjectMedia> media;
  final String? createdAt;

  const ProjectUpdate({
    required this.id,
    required this.projectId,
    required this.userId,
    this.authorName,
    this.authorAvatar,
    required this.content,
    this.externalVideoUrl,
    required this.isApproved,
    this.media = const [],
    this.createdAt,
  });

  factory ProjectUpdate.fromJson(Map<String, dynamic> j) => ProjectUpdate(
        id: (j['id'] as num?)?.toInt() ?? 0,
        projectId: (j['project_id'] as num?)?.toInt() ?? 0,
        userId: (j['user_id'] as num?)?.toInt() ?? 0,
        authorName: j['author_name'] as String?,
        authorAvatar: j['author_avatar'] as String?,
        content: (j['content'] as String?) ?? '',
        externalVideoUrl: j['external_video_url'] as String?,
        isApproved: j['is_approved'] as bool? ?? true,
        media: (j['media'] as List?)?.whereType<Map<String, dynamic>>().map(ProjectMedia.fromJson).toList() ?? [],
        createdAt: j['created_at'] as String?,
      );
}

class Project {
  final int id;
  final String title;
  final String slug;
  final String? summary;
  final String? description;
  final String? location;
  final String? county;
  final double? latitude;
  final double? longitude;
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
  // Present on every list row (see api.py's _project_dict) — Built History
  // and Africa & World are filtered views over this same Project row, not
  // separate content types (models.py: is_built_history/geo_scope).
  final String? plusCode;
  final bool isLegacy;
  final bool isProjectOfWeek;
  final bool isBuiltHistory;
  final String? heritageCategory;
  final String? ownershipType;
  final String? completionDecade;
  final String geoScope; // 'local' (default) or 'global' (Africa & World)
  final String? region;
  final String? country;
  final int upvoteCount;
  final int downvoteCount;

  // Detail-only
  final double? contractValue;
  final String? actualEndDate;
  final List<ProjectMilestone> milestones;
  final List<ProjectMedia> media;
  final List<ProjectMedia> featuredMedia;
  final String? descriptionOverview;
  final String? originalArchitect;
  final String? commissioningAuthority;
  final String? renovationTimeline;
  final int? submittedBy;
  final int? editedBy;
  final List<ProjectTeamMember> teamMembers;
  final bool isFollowing;

  const Project({
    required this.id,
    required this.title,
    required this.slug,
    this.summary,
    this.description,
    this.location,
    this.county,
    this.latitude,
    this.longitude,
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
    this.plusCode,
    this.isLegacy = false,
    this.isProjectOfWeek = false,
    this.isBuiltHistory = false,
    this.heritageCategory,
    this.ownershipType,
    this.completionDecade,
    this.geoScope = 'local',
    this.region,
    this.country,
    this.upvoteCount = 0,
    this.downvoteCount = 0,
    this.contractValue,
    this.actualEndDate,
    this.milestones = const [],
    this.media = const [],
    this.featuredMedia = const [],
    this.descriptionOverview,
    this.originalArchitect,
    this.commissioningAuthority,
    this.renovationTimeline,
    this.submittedBy,
    this.editedBy,
    this.teamMembers = const [],
    this.isFollowing = false,
  });

  factory Project.fromJson(Map<String, dynamic> j) => Project(
        id: (j['id'] as num).toInt(),
        title: (j['title'] as String?) ?? '',
        slug: (j['slug'] as String?) ?? '',
        summary: j['summary'] as String?,
        description: j['description'] as String?,
        location: j['location'] as String?,
        county: j['county'] as String?,
        // The backend serializes these as decimal strings (e.g. "-1.21360000",
        // from a SQLAlchemy Numeric column), not JSON numbers — tolerate both.
        latitude: _parseCoord(j['latitude']),
        longitude: _parseCoord(j['longitude']),
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
        plusCode: j['plus_code'] as String?,
        isLegacy: (j['is_legacy'] as bool?) ?? false,
        isProjectOfWeek: (j['is_project_of_week'] as bool?) ?? false,
        isBuiltHistory: (j['is_built_history'] as bool?) ?? false,
        heritageCategory: j['heritage_category'] as String?,
        ownershipType: j['ownership_type'] as String?,
        completionDecade: j['completion_decade'] as String?,
        geoScope: (j['geo_scope'] as String?) ?? 'local',
        region: j['region'] as String?,
        country: j['country'] as String?,
        upvoteCount: (j['upvote_count'] as num?)?.toInt() ?? 0,
        downvoteCount: (j['downvote_count'] as num?)?.toInt() ?? 0,
        descriptionOverview: j['description_overview'] as String?,
        originalArchitect: j['original_architect'] as String?,
        commissioningAuthority: j['commissioning_authority'] as String?,
        renovationTimeline: j['renovation_timeline'] as String?,
        submittedBy: (j['submitted_by'] as num?)?.toInt(),
        editedBy: (j['edited_by'] as num?)?.toInt(),
        teamMembers: (j['team_members'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(ProjectTeamMember.fromJson)
                .toList() ??
            [],
        isFollowing: (j['is_following'] as bool?) ?? false,
      );

  /// Only [isFollowing] is ever patched client-side (optimistic follow
  /// toggle) — every other field stays a direct copy so the currently
  /// displayed detail (media, milestones, team members, ...) never
  /// disappears from an unrelated local update.
  Project copyWith({bool? isFollowing}) => Project(
        id: id, title: title, slug: slug, summary: summary,
        description: description, location: location, county: county,
        latitude: latitude, longitude: longitude, client: client,
        contractor: contractor, consultant: consultant,
        progressPercent: progressPercent, status: status,
        projectType: projectType, featuredImage: featuredImage,
        isFeatured: isFeatured, averageRating: averageRating,
        ratingCount: ratingCount, viewCount: viewCount,
        startDate: startDate, expectedEndDate: expectedEndDate,
        createdAt: createdAt, plusCode: plusCode, isLegacy: isLegacy,
        isProjectOfWeek: isProjectOfWeek, isBuiltHistory: isBuiltHistory,
        heritageCategory: heritageCategory, ownershipType: ownershipType,
        completionDecade: completionDecade, geoScope: geoScope,
        region: region, country: country, upvoteCount: upvoteCount,
        downvoteCount: downvoteCount, contractValue: contractValue,
        actualEndDate: actualEndDate, milestones: milestones, media: media,
        featuredMedia: featuredMedia, descriptionOverview: descriptionOverview,
        originalArchitect: originalArchitect,
        commissioningAuthority: commissioningAuthority,
        renovationTimeline: renovationTimeline, submittedBy: submittedBy,
        editedBy: editedBy, teamMembers: teamMembers,
        isFollowing: isFollowing ?? this.isFollowing,
      );

  List<ProjectMedia> get renderGallery => media.where((m) => m.isRender).toList();
  List<ProjectMedia> get progressGallery => media.where((m) => !m.isRender).toList();

  bool get hasCoordinates => latitude != null && longitude != null;

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
