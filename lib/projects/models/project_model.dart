// lib/projects/models/project_model.dart
import 'package:latlong2/latlong.dart';

import '../../news/models/article_model.dart';
import '../../auth/models/user_model.dart';

const String _kBase = 'https://mjengohub.co.ke';

List<LatLng>? _parseRoute(dynamic v) {
  if (v is! List) return null;
  final points = <LatLng>[];
  for (final entry in v) {
    if (entry is List && entry.length >= 2) {
      final lat = _parseCoord(entry[0]);
      final lng = _parseCoord(entry[1]);
      if (lat != null && lng != null) points.add(LatLng(lat, lng));
    }
  }
  return points.isEmpty ? null : points;
}

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

  factory ProjectClientDetail.fromJson(Map<String, dynamic> j) =>
      ProjectClientDetail(
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
    media:
        (j['media'] as List?)
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

  const ProjectTeamMember({
    required this.id,
    required this.role,
    required this.name,
    this.url,
  });

  factory ProjectTeamMember.fromJson(Map<String, dynamic> j) =>
      ProjectTeamMember(
        id: (j['id'] as num?)?.toInt() ?? 0,
        role: (j['role'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        url: j['url'] as String?,
      );
}

/// Official project documents (PDFs/reports/planning approvals), admin-
/// managed via a "Documents" tab on the website's project edit form (per
/// project_detail.html: "Project Documents: official PDFs/reports/planning
/// approvals..."). Confirmed live as of the `documents` field going out on
/// `GET projects/{slug}` — sent as `[]` on every sampled project today (no
/// rows seeded yet), same shape family as `media`/`milestones`/
/// `team_members`.
class ProjectDocument {
  final int id;
  final String fileName;
  final String filePath;
  final String? source;
  final String? description;

  const ProjectDocument({
    required this.id,
    required this.fileName,
    required this.filePath,
    this.source,
    this.description,
  });

  factory ProjectDocument.fromJson(Map<String, dynamic> j) => ProjectDocument(
    id: (j['id'] as num?)?.toInt() ?? 0,
    fileName:
        (j['file_name'] as String?) ?? (j['title'] as String?) ?? 'Document',
    filePath:
        (j['file_url'] as String?) ??
        (j['file_path'] as String?) ??
        (j['url'] as String?) ??
        '',
    source: j['source'] as String?,
    description: j['description'] as String?,
  );

  String get url {
    if (filePath.startsWith('http')) return filePath;
    return '$_kBase/static/$filePath';
  }

  /// PDF/DOC/XLS/etc, uppercased from the file extension, for a badge.
  String get fileType {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) return 'FILE';
    return fileName.substring(dot + 1).toUpperCase();
  }
}

/// A financial backer of the project — `GET projects/{slug}`'s `financiers`
/// array. Unlike `Project.financier` (the older plain-text field, kept for
/// projects that haven't been migrated), each entry here always carries a
/// real entity slug so it can push straight to `EntityProfileScreen` with no
/// slugify() guessing.
class ProjectFinancier {
  final String name;
  final String slug;
  final String? fundingType;
  final num? sharePercentage;

  /// Sent as either a JSON number or a decimal string (same Numeric-column
  /// pattern as `Project.latitude`/`longitude`) — kept as `dynamic` and
  /// normalized in [contributionDisplay].
  final dynamic contributionAmount;

  const ProjectFinancier({
    required this.name,
    required this.slug,
    this.fundingType,
    this.sharePercentage,
    this.contributionAmount,
  });

  factory ProjectFinancier.fromJson(Map<String, dynamic> j) => ProjectFinancier(
    name: (j['name'] as String?) ?? '',
    slug: (j['slug'] as String?) ?? '',
    fundingType: j['funding_type'] as String?,
    sharePercentage: _parseCoord(j['share_percentage'] ?? j['share']),
    contributionAmount: j['contribution_amount'],
  );

  String? get contributionDisplay {
    final v = contributionAmount;
    final amount = v is num
        ? v.toDouble()
        : (v is String ? double.tryParse(v) : null);
    if (amount == null) return null;
    final s = amount.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'KSh $buf';
  }
}

/// One row of `GET projects/{slug}`'s `stakeholders` array — a real
/// entity-linked stakeholder (contractor/consultant/financier/etc.), with
/// consortium support: several stakeholders sharing the same
/// [consortiumName] are joint partners on that role, with at most one
/// flagged [isConsortiumLead].
class ProjectStakeholder {
  final String name;
  final String? slug;
  final String? role;
  final bool isConsortiumLead;
  final String? consortiumName;

  const ProjectStakeholder({
    required this.name,
    this.slug,
    this.role,
    this.isConsortiumLead = false,
    this.consortiumName,
  });

  factory ProjectStakeholder.fromJson(Map<String, dynamic> j) =>
      ProjectStakeholder(
        name: (j['name'] as String?) ?? '',
        slug: j['slug'] as String?,
        role: j['role'] as String?,
        isConsortiumLead: (j['is_consortium_lead'] as bool?) ?? false,
        consortiumName: j['consortium_name'] as String?,
      );
}

/// Who submitted and who approved/published this project — `attribution` on
/// `GET projects/{slug}`. The live API currently sends `submitter_name` /
/// `submitter_type` rather than `is_anonymous` / `submitted_by`; both shapes
/// are tolerated here so this doesn't silently break if the naming changes.
class ProjectAttribution {
  final bool isAnonymous;
  final String? submittedBy;
  final String? publishedBy;

  const ProjectAttribution({
    this.isAnonymous = false,
    this.submittedBy,
    this.publishedBy,
  });

  factory ProjectAttribution.fromJson(Map<String, dynamic> j) {
    final submitterName =
        (j['submitted_by'] as String?) ?? (j['submitter_name'] as String?);
    final submitterType = j['submitter_type'] as String?;
    final isAnonymousRaw = j['is_anonymous'];
    final bool anonymous = isAnonymousRaw is bool
        ? isAnonymousRaw
        : submitterType != null
        ? submitterType == 'anonymous'
        : (submitterName == null || submitterName.trim().isEmpty);
    return ProjectAttribution(
      isAnonymous: anonymous,
      submittedBy: anonymous ? null : submitterName,
      publishedBy: j['published_by'] as String?,
    );
  }

  bool get hasContent =>
      isAnonymous || submittedBy != null || publishedBy != null;
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
    media:
        (j['media'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(ProjectMedia.fromJson)
            .toList() ??
        [],
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
  final List<String> additionalCounties;
  final double? latitude;
  final double? longitude;
  final ProjectClient? client;
  final String? contractor;
  final String? consultant;
  // Sent by the backend as a plain string (like contractor/consultant) but
  // was previously dropped by this model — added so _buildDetailsCard can
  // surface it.
  final String? financier;
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
  final double? costKes;
  final double? costUsdValue;
  final List<String> clients;
  final List<String> contractors;
  final List<String> consortiumMembers;
  final Map<String, String> mediaSources;
  final UserProfileSummary? submittedByProfile;
  final UserProfileSummary? publishedByProfile;
  final bool isAnonymousSubmission;
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
  final int? submittedById;
  final int? editedBy;
  final List<ProjectTeamMember> teamMembers;
  final List<ProjectDocument> documents;
  final List<ProjectFinancier> financiers;
  final List<ProjectStakeholder> stakeholders;
  final ProjectAttribution? attribution;
  final bool isFollowing;

  // Linear route mapping (roads/railways/pipelines) — defensive/dormant:
  // confirmed absent from the live backend today, parsed only in case it's
  // ever added (`is_linear` / `route_data`, an ordered [[lat,lng],...] list).
  final bool isLinear;
  final List<LatLng>? routeData;
  final double? routeLengthKm;

  // Bi-directional article linking — defensive/dormant, same reasoning:
  // `related_articles` doesn't exist in the API response today.
  final List<Article> relatedArticles;

  const Project({
    required this.id,
    required this.title,
    required this.slug,
    this.summary,
    this.description,
    this.location,
    this.county,
    this.additionalCounties = const [],
    this.latitude,
    this.longitude,
    this.client,
    this.contractor,
    this.consultant,
    this.financier,
    required this.progressPercent,
    required this.status,
    this.projectType = 'infrastructure',
    this.featuredImage,
    required this.isFeatured,
    this.averageRating,
    required this.ratingCount,
    required this.viewCount,
    this.costKes,
    this.costUsdValue,
    this.clients = const [],
    this.contractors = const [],
    this.consortiumMembers = const [],
    this.mediaSources = const {},
    this.submittedByProfile,
    this.publishedByProfile,
    this.isAnonymousSubmission = false,
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
    this.submittedById,
    this.editedBy,
    this.teamMembers = const [],
    this.documents = const [],
    this.financiers = const [],
    this.stakeholders = const [],
    this.attribution,
    this.isFollowing = false,
    this.isLinear = false,
    this.routeData,
    this.routeLengthKm,
    this.relatedArticles = const [],
  });

  factory Project.fromJson(Map<String, dynamic> j) => Project(
    id: (j['id'] as num).toInt(),
    title: (j['title'] as String?) ?? '',
    slug: (j['slug'] as String?) ?? '',
    summary: j['summary'] as String?,
    description: j['description'] as String?,
    location: j['location'] as String?,
    county: j['county'] as String?,
    additionalCounties:
        (j['additional_counties'] as List?)?.whereType<String>().toList() ??
        const [],
    // The backend serializes these as decimal strings (e.g. "-1.21360000",
    // from a SQLAlchemy Numeric column), not JSON numbers — tolerate both.
    latitude: _parseCoord(j['latitude']),
    longitude: _parseCoord(j['longitude']),
    client: j['client'] != null
        ? ProjectClient.fromJson(j['client'] as Map<String, dynamic>)
        : null,
    contractor: j['contractor'] as String?,
    consultant: j['consultant'] as String?,
    financier: j['financier'] as String?,
    progressPercent: (j['progress_percent'] as num?)?.toInt() ?? 0,
    status: (j['status'] as String?) ?? 'ongoing',
    projectType: (j['project_type'] as String?) ?? 'infrastructure',
    featuredImage: j['featured_image'] as String?,
    isFeatured: (j['is_featured'] as bool?) ?? false,
    averageRating: (j['average_rating'] as num?)?.toDouble(),
    ratingCount: (j['rating_count'] as num?)?.toInt() ?? 0,
    viewCount: (j['view_count'] as num?)?.toInt() ?? 0,
    costKes: _parseCoord(j['cost_kes'] ?? j['contract_value'] ?? j['cost']),
    costUsdValue: _parseCoord(j['cost_usd']),
    clients:
        (j['clients'] as List?)
            ?.map(
              (v) => v is Map ? (v['name']?.toString() ?? '') : v.toString(),
            )
            .where((v) => v.isNotEmpty)
            .toList() ??
        const [],
    contractors:
        (j['contractors'] as List?)
            ?.map(
              (v) => v is Map ? (v['name']?.toString() ?? '') : v.toString(),
            )
            .where((v) => v.isNotEmpty)
            .toList() ??
        const [],
    consortiumMembers:
        (j['consortium_members'] as List?)?.map((v) => v.toString()).toList() ??
        const [],
    mediaSources:
        (j['media_sources'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ) ??
        const {},
    submittedByProfile: j['submitted_by'] is Map
        ? UserProfileSummary.fromJson(j['submitted_by'])
        : null,
    publishedByProfile: j['published_by'] is Map
        ? UserProfileSummary.fromJson(j['published_by'])
        : null,
    isAnonymousSubmission:
        (j['is_anonymous_submission'] as bool?) ??
        (j['is_anonymous'] as bool?) ??
        false,
    startDate: j['start_date'] as String?,
    expectedEndDate: j['expected_end_date'] as String?,
    createdAt: j['created_at'] as String?,
    contractValue: (j['contract_value'] as num?)?.toDouble(),
    actualEndDate: j['actual_end_date'] as String?,
    milestones:
        (j['milestones'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(ProjectMilestone.fromJson)
            .toList() ??
        [],
    media:
        (j['media'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(ProjectMedia.fromJson)
            .toList() ??
        [],
    featuredMedia:
        (j['featured_media'] as List?)
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
    submittedById: (j['submitted_by'] as num?)?.toInt(),
    editedBy: (j['edited_by'] as num?)?.toInt(),
    teamMembers:
        (j['team_members'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(ProjectTeamMember.fromJson)
            .toList() ??
        [],
    documents:
        (j['documents'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(ProjectDocument.fromJson)
            .toList() ??
        [],
    financiers:
        (j['financiers'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(ProjectFinancier.fromJson)
            .toList() ??
        [],
    stakeholders:
        (j['stakeholders'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(ProjectStakeholder.fromJson)
            .toList() ??
        [],
    attribution: j['attribution'] != null
        ? ProjectAttribution.fromJson(j['attribution'] as Map<String, dynamic>)
        : null,
    isFollowing: (j['is_following'] as bool?) ?? false,
    isLinear: (j['is_linear'] as bool?) ?? false,
    routeData: _parseRoute(j['route_coordinates'] ?? j['route_data']),
    routeLengthKm: (j['route_length_km'] as num?)?.toDouble(),
    relatedArticles:
        (j['related_articles'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(Article.fromJson)
            .toList() ??
        [],
  );

  /// Only [isFollowing] is ever patched client-side (optimistic follow
  /// toggle) — every other field stays a direct copy so the currently
  /// displayed detail (media, milestones, team members, ...) never
  /// disappears from an unrelated local update.
  Project copyWith({bool? isFollowing}) => Project(
    id: id,
    title: title,
    slug: slug,
    summary: summary,
    description: description,
    location: location,
    county: county,
    additionalCounties: additionalCounties,
    latitude: latitude,
    longitude: longitude,
    client: client,
    contractor: contractor,
    consultant: consultant,
    financier: financier,
    progressPercent: progressPercent,
    status: status,
    projectType: projectType,
    featuredImage: featuredImage,
    isFeatured: isFeatured,
    averageRating: averageRating,
    ratingCount: ratingCount,
    viewCount: viewCount,
    costKes: costKes,
    costUsdValue: costUsdValue,
    clients: clients,
    contractors: contractors,
    consortiumMembers: consortiumMembers,
    mediaSources: mediaSources,
    submittedByProfile: submittedByProfile,
    publishedByProfile: publishedByProfile,
    isAnonymousSubmission: isAnonymousSubmission,
    startDate: startDate,
    expectedEndDate: expectedEndDate,
    createdAt: createdAt,
    plusCode: plusCode,
    isLegacy: isLegacy,
    isProjectOfWeek: isProjectOfWeek,
    isBuiltHistory: isBuiltHistory,
    heritageCategory: heritageCategory,
    ownershipType: ownershipType,
    completionDecade: completionDecade,
    geoScope: geoScope,
    region: region,
    country: country,
    upvoteCount: upvoteCount,
    downvoteCount: downvoteCount,
    contractValue: contractValue,
    actualEndDate: actualEndDate,
    milestones: milestones,
    media: media,
    featuredMedia: featuredMedia,
    descriptionOverview: descriptionOverview,
    originalArchitect: originalArchitect,
    commissioningAuthority: commissioningAuthority,
    renovationTimeline: renovationTimeline,
    submittedById: submittedById,
    editedBy: editedBy,
    teamMembers: teamMembers,
    documents: documents,
    financiers: financiers,
    stakeholders: stakeholders,
    attribution: attribution,
    isFollowing: isFollowing ?? this.isFollowing,
    isLinear: isLinear,
    routeData: routeData,
    routeLengthKm: routeLengthKm,
    relatedArticles: relatedArticles,
  );

  List<ProjectMedia> get renderGallery =>
      media.where((m) => m.isRender).toList();
  List<ProjectMedia> get progressGallery =>
      media.where((m) => !m.isRender).toList();

  bool get hasCoordinates => latitude != null && longitude != null;
  List<LatLng>? get routeCoordinates => routeData;
  int get views => viewCount;
  double? get costUsd =>
      costUsdValue ?? (costKes == null ? null : costKes! / 129.5);
  double? get computedCostUsd => costUsd;
  UserProfileSummary? get submittedBy => submittedByProfile;
  UserProfileSummary? get publishedBy => publishedByProfile;

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
      case 'planned':
        return 'Planned';
      case 'ongoing':
        return 'Ongoing';
      case 'completed':
        return 'Completed';
      case 'commissioned':
        return 'Commissioned';
      case 'stalled':
        return 'Stalled';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String? get ratingDisplay =>
      averageRating != null ? '${averageRating!.toStringAsFixed(1)}/10' : null;
}
