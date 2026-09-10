// lib/news/models/category_model.dart

class Category {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final bool showOnHomepage;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.showOnHomepage = false,
  });

  String get displayName {
    final value = name.trim();
    if (value.isNotEmpty) return value;
    const fallback = {
      'infrastructure': 'Infrastructure',
      'construction': 'Construction',
      'safety': 'Safety & Compliance',
      'business': 'Construction Business',
    };
    return fallback[slug.toLowerCase()] ?? 'Construction News';
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?)?.trim() ?? '',
      slug: (json['slug'] as String?) ?? '',
      description: json['description'] as String?,
      showOnHomepage: (json['show_on_homepage'] as bool?) ?? false,
    );
  }
}
