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

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? '',
      slug: (json['slug'] as String?) ?? '',
      description: json['description'] as String?,
      showOnHomepage: (json['show_on_homepage'] as bool?) ?? false,
    );
  }
}
