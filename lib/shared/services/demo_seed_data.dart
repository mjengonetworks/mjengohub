// lib/shared/services/demo_seed_data.dart
//
// Fallback content for the Home feed sections when the live API can't be
// reached (host WAF/bot-protection 403s, 401s, or any other failure that
// leaves a section empty). This is clearly-generic placeholder content —
// deliberately NOT phrased to resemble real news/projects/incidents — and
// every screen that uses it must pair it with a visible "preview" badge
// (see `preview_data_badge.dart`). This app publishes real civic
// infrastructure and public-safety records, so fabricated content must
// never be presented as indistinguishable from a live API response.
import '../../incidents/models/incident_model.dart';
import '../../news/models/article_model.dart';
import '../../projects/models/project_model.dart';

List<Article> demoFeaturedArticles() {
  final now = DateTime.now();
  return [
    Article(
      id: -1,
      title: 'Preview headline — live articles unavailable right now',
      slug: 'demo-article-1',
      summary: 'This is placeholder content shown while the news feed reconnects.',
      isFeatured: true,
      isBreaking: false,
      viewCount: 128,
      readTime: 3,
      publishedAt: now.subtract(const Duration(hours: 2)).toIso8601String(),
      category: const ArticleCategory(id: -1, name: 'Preview', slug: 'preview'),
    ),
    Article(
      id: -2,
      title: 'Sample construction-industry update',
      slug: 'demo-article-2',
      summary: 'Live content will appear here automatically once the connection is restored.',
      isFeatured: true,
      isBreaking: false,
      viewCount: 96,
      readTime: 2,
      publishedAt: now.subtract(const Duration(hours: 5)).toIso8601String(),
      category: const ArticleCategory(id: -2, name: 'Preview', slug: 'preview'),
    ),
  ];
}

List<Article> demoBreakingArticles() {
  final now = DateTime.now();
  return [
    Article(
      id: -3,
      title: 'Preview item — breaking news feed unavailable',
      slug: 'demo-breaking-1',
      isFeatured: false,
      isBreaking: true,
      viewCount: 41,
      publishedAt: now.subtract(const Duration(minutes: 45)).toIso8601String(),
    ),
    Article(
      id: -4,
      title: 'Sample road-safety bulletin placeholder',
      slug: 'demo-breaking-2',
      isFeatured: false,
      isBreaking: true,
      viewCount: 33,
      publishedAt: now.subtract(const Duration(hours: 1)).toIso8601String(),
    ),
    Article(
      id: -5,
      title: 'Sample site-safety bulletin placeholder',
      slug: 'demo-breaking-3',
      isFeatured: false,
      isBreaking: true,
      viewCount: 27,
      publishedAt: now.subtract(const Duration(hours: 3)).toIso8601String(),
    ),
  ];
}

List<Project> demoProjects() => const [
      Project(
        id: -1,
        title: 'Sample road upgrade project (preview)',
        slug: 'demo-project-1',
        county: 'Nairobi',
        progressPercent: 62,
        status: 'ongoing',
        isFeatured: true,
        ratingCount: 0,
        viewCount: 0,
      ),
      Project(
        id: -2,
        title: 'Sample housing development (preview)',
        slug: 'demo-project-2',
        county: 'Kiambu',
        progressPercent: 38,
        status: 'ongoing',
        isFeatured: true,
        ratingCount: 0,
        viewCount: 0,
      ),
      Project(
        id: -3,
        title: 'Sample bridge rehabilitation (preview)',
        slug: 'demo-project-3',
        county: 'Machakos',
        progressPercent: 100,
        status: 'completed',
        isFeatured: true,
        ratingCount: 0,
        viewCount: 0,
      ),
      Project(
        id: -4,
        title: 'Sample commercial complex (preview)',
        slug: 'demo-project-4',
        county: 'Mombasa',
        progressPercent: 15,
        status: 'planned',
        isFeatured: true,
        ratingCount: 0,
        viewCount: 0,
      ),
    ];

List<Incident> demoIncidents() => const [
      Incident(
        id: -1,
        incidentType: 'road_safety',
        title: 'Sample road hazard report (preview)',
        slug: 'demo-incident-1',
        county: 'Nairobi',
        severity: 'moderate',
        isFeatured: true,
        viewCount: 0,
      ),
      Incident(
        id: -2,
        incidentType: 'site_safety',
        title: 'Sample site safety report (preview)',
        slug: 'demo-incident-2',
        county: 'Nakuru',
        severity: 'serious',
        isFeatured: true,
        viewCount: 0,
      ),
      Incident(
        id: -3,
        incidentType: 'road_safety',
        title: 'Sample road hazard report (preview)',
        slug: 'demo-incident-3',
        county: 'Kisumu',
        severity: 'minor',
        isFeatured: true,
        viewCount: 0,
      ),
      Incident(
        id: -4,
        incidentType: 'site_safety',
        title: 'Sample site safety report (preview)',
        slug: 'demo-incident-4',
        county: 'Uasin Gishu',
        severity: 'moderate',
        isFeatured: true,
        viewCount: 0,
      ),
    ];
