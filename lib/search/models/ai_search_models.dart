// lib/search/models/ai_search_models.dart
//
// Models for the Omnibar's `GET ai-search?q=` call. **This route is not
// confirmed live** — a direct check against
// `https://mjengohub.co.ke/api/v1/ai-search` 404s (checked 2026-09-16, same
// for `/api/ai-search` and `/api/v1/ai_search`). Wired end-to-end anyway,
// same pattern as `auth/google`/`auth/forgot-password` in
// `MjengoAuthController` (see CLAUDE.md's Auth flows section): the call and
// parsing are ready to light up the moment the backend adds the route, and
// degrade to an empty/explicit-unavailable result rather than crashing until
// then. Shape below matches the request's spec exactly since there's no live
// response to verify it against.
class AISearchResultItem {
  final String id;
  final String title;

  /// Free-text role/subtitle — e.g. a Directory entry's role ("Contractor"),
  /// or a Guide's category label.
  final String? subtitle;
  final String? imageUrl;
  final String? county;

  /// Slug used to build the navigation target (article slug, entity slug).
  final String? slug;

  const AISearchResultItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.county,
    this.slug,
  });

  factory AISearchResultItem.fromJson(Map<String, dynamic> j) =>
      AISearchResultItem(
        id: (j['id'] ?? j['slug'] ?? '').toString(),
        title: (j['title'] ?? j['name'] ?? '').toString(),
        subtitle: (j['role'] ?? j['subtitle'] ?? j['category'])?.toString(),
        imageUrl: (j['image'] ?? j['image_url'] ?? j['logo'])?.toString(),
        county: j['county']?.toString(),
        slug: j['slug']?.toString(),
      );
}

/// One results section ("Guides & Insights", "Directory", "Materials", …).
/// [items] is always a real (possibly empty) list — never omitted — so a
/// category with no matches degrades to "not rendered" at the widget layer
/// rather than a null-check crash.
class AISearchCategory {
  final String key;
  final String label;
  final List<AISearchResultItem> items;

  const AISearchCategory({
    required this.key,
    required this.label,
    this.items = const [],
  });

  factory AISearchCategory.fromJson(String key, dynamic raw) {
    final items = raw is List
        ? raw
              .whereType<Map<String, dynamic>>()
              .map(AISearchResultItem.fromJson)
              .toList()
        : const <AISearchResultItem>[];
    return AISearchCategory(key: key, label: _labelFor(key), items: items);
  }

  static String _labelFor(String key) => switch (key) {
    'guides' || 'articles' || 'insights' => 'Guides & Insights',
    'directory' || 'entities' || 'contractors' => 'Directory',
    'materials' => 'Materials',
    _ => key,
  };
}

class AISearchResponse {
  final String query;
  final String? aiSummary;
  final List<AISearchCategory> categories;

  const AISearchResponse({
    this.query = '',
    this.aiSummary,
    this.categories = const [],
  });

  bool get isEmpty =>
      (aiSummary == null || aiSummary!.trim().isEmpty) &&
      categories.every((c) => c.items.isEmpty);

  factory AISearchResponse.fromJson(Map<String, dynamic> j) {
    const knownKeys = ['guides', 'directory', 'materials'];
    final categories = <AISearchCategory>[];
    for (final key in knownKeys) {
      if (j.containsKey(key)) {
        categories.add(AISearchCategory.fromJson(key, j[key]));
      }
    }
    return AISearchResponse(
      query: (j['query'] as String?) ?? '',
      aiSummary: (j['ai_summary'] as String?)?.trim().isEmpty == true
          ? null
          : j['ai_summary'] as String?,
      categories: categories,
    );
  }
}
