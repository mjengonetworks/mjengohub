// lib/projects/models/project_model.dart
const String _kBase = 'https://mjengohub.co.ke';

class ProjectClient {
  final int id;
  final String name;
  final String slug;
  final String? logo;
  final String? clientType;

  const ProjectClient({
    required this.id,
    required this.name,
    required this.slug,
    this.logo,
    this.clientType,
  });

  factory ProjectClient.fromJson(Map<String, dynamic> j) => ProjectClient(
        id: (j['id'] as num).toInt(),
        name: (j['name'] as String?) ?? '',
        slug: (j['slug'] as String?) ?? '',
        logo: j['logo'] as String?,
        clientType: j['client_type'] as String?,
      );

  String? get logoUrl {
    if (logo == null || logo!.isEmpty) return null;
    if (logo!.startsWith('http')) return logo;
    return '$_kBase/static/$logo';
  }
}

class ProjectMilestone {
  final int id;
  final String title;
  final String? description;
  final String? milestoneDate;
  final String? milestoneType;
  final bool isAchieved;

  const ProjectMilestone({
    required this.id,
    required this.title,
    this.description,
    this.milestoneDate,
    this.milestoneType,
    required this.isAchieved,
  });

  factory ProjectMilestone.fromJson(Map<String, dynamic> j) => ProjectMilestone(
        id: (j['id'] as num).toInt(),
        title: (j['title'] as String?) ?? '',
        description: j['description'] as String?,
        milestoneDate: j['milestone_date'] as String?,
        milestoneType: j['milestone_type'] as String?,
        isAchieved: (j['is_achieved'] as bool?) ?? false,
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

  const ProjectMedia({
    required this.id,
    required this.filePath,
    required this.mediaType,
    this.caption,
    this.credit,
    this.monthYear,
    required this.isFeatured,
  });

  factory ProjectMedia.fromJson(Map<String, dynamic> j) => ProjectMedia(
        id: (j['id'] as num).toInt(),
        filePath: (j['file_path'] as String?) ?? '',
        mediaType: (j['media_type'] as String?) ?? 'image',
        caption: j['caption'] as String?,
        credit: j['credit'] as String?,
        monthYear: j['month_year'] as String?,
        isFeatured: (j['is_featured'] as bool?) ?? false,
      );

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
  final String? featuredImage;
  final bool isFeatured;
  final double? averageRating;
  final int ratingCount;
  final int viewCount;
  final String? startDate;
  final String? expectedEndDate;
  // Detail-only
  final List<ProjectMilestone> milestones;
  final List<ProjectMedia> media;

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
    this.featuredImage,
    required this.isFeatured,
    this.averageRating,
    required this.ratingCount,
    required this.viewCount,
    this.startDate,
    this.expectedEndDate,
    this.milestones = const [],
    this.media = const [],
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
        featuredImage: j['featured_image'] as String?,
        isFeatured: (j['is_featured'] as bool?) ?? false,
        averageRating: (j['average_rating'] as num?)?.toDouble(),
        ratingCount: (j['rating_count'] as num?)?.toInt() ?? 0,
        viewCount: (j['view_count'] as num?)?.toInt() ?? 0,
        startDate: j['start_date'] as String?,
        expectedEndDate: j['expected_end_date'] as String?,
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
      );

  String? get imageUrl {
    if (featuredImage == null || featuredImage!.isEmpty) return null;
    if (featuredImage!.startsWith('http')) return featuredImage;
    return '$_kBase/static/$featuredImage';
  }

  String get statusLabel {
    switch (status) {
      case 'ongoing': return 'Ongoing';
      case 'completed': return 'Completed';
      case 'suspended': return 'Suspended';
      case 'planned': return 'Planned';
      default: return status;
    }
  }

  String? get ratingDisplay =>
      averageRating != null ? '${averageRating!.toStringAsFixed(1)}/10' : null;
}
