// lib/service_catalog/models/service_model.dart
//
// Mirrors api.py's `_service_dict`. Named "service_catalog" rather than
// "services" because `lib/services/` is already the app-wide HTTP layer.
//
// `benefits`, `features` and `process` are admin-authored JSON columns on the
// website; they come back as either a JSON list or a newline/pipe separated
// string depending on how the admin filled the form, so both shapes are
// normalised to List<String> here.

class ServiceOffering {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? icon;
  final String? image;
  final String? basePrice;
  final bool isFeatured;

  // Detail-only (`full=True`)
  final String? detailedDescription;
  final String? formIntro;
  final String? whyChooseTitle;
  final List<String> benefits;
  final List<String> features;
  final List<String> process;

  const ServiceOffering({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.icon,
    this.image,
    this.basePrice,
    this.isFeatured = false,
    this.detailedDescription,
    this.formIntro,
    this.whyChooseTitle,
    this.benefits = const [],
    this.features = const [],
    this.process = const [],
  });

  factory ServiceOffering.fromJson(Map<String, dynamic> j) => ServiceOffering(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: (j['name'] as String?) ?? '',
        slug: (j['slug'] as String?) ?? '',
        description: j['description'] as String?,
        icon: j['icon'] as String?,
        image: j['image'] as String?,
        basePrice: j['base_price']?.toString(),
        isFeatured: (j['is_featured'] as bool?) ?? false,
        detailedDescription: j['detailed_description'] as String?,
        formIntro: j['form_intro'] as String?,
        whyChooseTitle: j['why_choose_title'] as String?,
        benefits: _stringList(j['benefits']),
        features: _stringList(j['features']),
        process: _stringList(j['process']),
      );

  /// Accepts a JSON list, a newline/pipe-delimited string, or null.
  static List<String> _stringList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .map((e) => e is Map ? (e['title'] ?? e['name'] ?? '').toString() : e.toString())
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (raw is String) {
      return raw
          .split(RegExp(r'[\n|]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }
}
