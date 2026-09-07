// lib/entities/models/entity_model.dart
//
// `GET entities/{slug}` — a shared "entity" record backing project
// stakeholders (client/contractor/consultant/financier) on the website's
// Mjengo Networks side. Verified live shape (2026-09-07) against
// https://mjengohub.co.ke/api/v1/entities/kenya-national-highways-authority-kenha:
// the detail payload is `{success, data}` like every other endpoint (no
// wrapping "entity" key), `logo` is a bare path (not `logo_url`), and
// `projects` is keyed by the stakeholder role the entity played on each
// project rather than an arbitrary category.
//
// Today the entities table has exactly one populated row (KeNHA) with an
// empty `projects` map, so [EntityProjectRef]'s fields are inferred from the
// standard project-list shape (`GET projects`) rather than confirmed against
// a live example. Project's own contractor/consultant/financier fields are
// still plain free-text strings with no entity linkage — see
// shared/utils/slugify.dart for how a stakeholder name gets turned into a
// best-effort slug lookup.
const String _kBase = 'https://mjengohub.co.ke';

class EntityProjectRef {
  final int id;
  final String slug;
  final String title;
  final String? status;
  final int progressPercent;
  final String? featuredImage;

  const EntityProjectRef({
    required this.id,
    required this.slug,
    required this.title,
    this.status,
    this.progressPercent = 0,
    this.featuredImage,
  });

  factory EntityProjectRef.fromJson(Map<String, dynamic> j) => EntityProjectRef(
        id: (j['id'] as num?)?.toInt() ?? 0,
        slug: (j['slug'] as String?) ?? '',
        title: (j['title'] as String?) ?? '',
        status: j['status'] as String?,
        progressPercent: (j['progress_percent'] as num?)?.toInt() ?? 0,
        featuredImage: j['featured_image'] as String?,
      );

  String? get imageUrl {
    if (featuredImage == null || featuredImage!.isEmpty) return null;
    if (featuredImage!.startsWith('http')) return featuredImage;
    return '$_kBase/static/$featuredImage';
  }
}

class EntityModel {
  final int id;
  final String name;
  final String slug;
  final String? bio;
  final String? description;
  final String? logo;
  final String? clientType;
  final String? originCountry;
  final String? mjengoNetworksUrl;
  final String? websiteUrl;
  final List<String> roles;
  final int projectCount;
  final int totalProjects;

  /// Keyed by stakeholder role ('client', 'contractor', 'consultant',
  /// 'financier') as sent by the backend.
  final Map<String, List<EntityProjectRef>> projectsByRole;

  const EntityModel({
    required this.id,
    required this.name,
    required this.slug,
    this.bio,
    this.description,
    this.logo,
    this.clientType,
    this.originCountry,
    this.mjengoNetworksUrl,
    this.websiteUrl,
    this.roles = const [],
    this.projectCount = 0,
    this.totalProjects = 0,
    this.projectsByRole = const {},
  });

  factory EntityModel.fromJson(Map<String, dynamic> j) {
    final rawProjects = j['projects'];
    final byRole = <String, List<EntityProjectRef>>{};
    if (rawProjects is Map) {
      rawProjects.forEach((key, value) {
        if (value is List) {
          byRole[key.toString()] = value
              .whereType<Map<String, dynamic>>()
              .map(EntityProjectRef.fromJson)
              .toList();
        }
      });
    }
    return EntityModel(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] as String?) ?? '',
      slug: (j['slug'] as String?) ?? '',
      bio: j['bio'] as String?,
      description: j['description'] as String?,
      logo: j['logo'] as String?,
      clientType: j['client_type'] as String?,
      originCountry: j['origin_country'] as String?,
      mjengoNetworksUrl: j['mjengo_networks_url'] as String?,
      websiteUrl: j['website_url'] as String?,
      roles: (j['roles'] as List?)?.whereType<String>().toList() ?? const [],
      projectCount: (j['project_count'] as num?)?.toInt() ?? 0,
      totalProjects: (j['total_projects'] as num?)?.toInt() ?? 0,
      projectsByRole: byRole,
    );
  }

  String? get logoUrl {
    if (logo == null || logo!.isEmpty) return null;
    if (logo!.startsWith('http')) return logo;
    return '$_kBase/static/$logo';
  }

  /// The backend sends both `bio` and `description` (both null on the one
  /// live entity today) — prefer `bio` since it's the field the endpoint is
  /// presumably named for, falling back to `description`.
  String? get bioText => (bio != null && bio!.isNotEmpty) ? bio : description;

  int get totalLinkedProjects =>
      projectsByRole.values.fold(0, (sum, list) => sum + list.length);
}
