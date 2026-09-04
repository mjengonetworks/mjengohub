// lib/profile/models/public_profile_model.dart
//
// `GET /users/<id>` — a public-safe view of another user's profile (no
// email/phone), opened by tapping a name in the Contributors leaderboard or
// elsewhere in the app.
import '../../news/models/article_model.dart';
import '../../projects/models/project_model.dart';

class PublicProfile {
  final int id;
  final String name;
  final String? avatar;
  final String? coverImage;
  final String? bio;
  final String? company;
  final String? location;
  final String? role;
  final int points;
  final bool isVerified;
  final String? mjengoNetworksUrl;
  final String? shareBarabaraUrl;
  final DateTime? createdAt;
  final int articleCount;
  final int projectCount;
  final List<Article> articles;
  final List<Project> projects;

  const PublicProfile({
    required this.id,
    required this.name,
    this.avatar,
    this.coverImage,
    this.bio,
    this.company,
    this.location,
    this.role,
    this.points = 0,
    this.isVerified = false,
    this.mjengoNetworksUrl,
    this.shareBarabaraUrl,
    this.createdAt,
    this.articleCount = 0,
    this.projectCount = 0,
    this.articles = const [],
    this.projects = const [],
  });

  factory PublicProfile.fromJson(Map<String, dynamic> j) => PublicProfile(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: (j['name'] as String?) ?? 'User',
        avatar: j['avatar'] as String?,
        coverImage: j['cover_image'] as String?,
        bio: j['bio'] as String?,
        company: j['company'] as String?,
        location: j['location'] as String?,
        role: j['role'] as String?,
        points: (j['points'] as num?)?.toInt() ?? 0,
        isVerified: j['is_verified'] as bool? ?? false,
        mjengoNetworksUrl: j['mjengo_networks_url'] as String?,
        shareBarabaraUrl: j['share_barabara_url'] as String?,
        createdAt: DateTime.tryParse((j['created_at'] as String?) ?? ''),
        articleCount: (j['article_count'] as num?)?.toInt() ?? 0,
        projectCount: (j['project_count'] as num?)?.toInt() ?? 0,
        articles: (j['articles'] as List?)?.whereType<Map<String, dynamic>>().map(Article.fromJson).toList() ?? [],
        projects: (j['projects'] as List?)?.whereType<Map<String, dynamic>>().map(Project.fromJson).toList() ?? [],
      );
}
