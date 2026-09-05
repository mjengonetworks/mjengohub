// lib/news/models/article_model.dart

import 'package:latlong2/latlong.dart';

const String _kBaseUrl = 'https://mjengohub.co.ke';

/// A project tagged onto an article for the "View Tracker Project" card.
/// Parsed from an optional `tagged_project` object — not sent by the
/// current backend, so this is always null today; the app is ready for it.
class ArticleTaggedProject {
  final String slug;
  final String title;
  final String? image;
  final String? trackerLabel;

  const ArticleTaggedProject({
    required this.slug,
    required this.title,
    this.image,
    this.trackerLabel,
  });

  factory ArticleTaggedProject.fromJson(Map<String, dynamic> json) {
    return ArticleTaggedProject(
      slug: (json['slug'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      image: json['image'] as String?,
      trackerLabel: json['tracker_label'] as String?,
    );
  }

  String? get imageUrl {
    if (image == null || image!.isEmpty) return null;
    if (image!.startsWith('http')) return image;
    return '$_kBaseUrl$image';
  }
}

class ArticleAuthor {
  final int id;
  final String name;
  final String? image;

  const ArticleAuthor({required this.id, required this.name, this.image});

  factory ArticleAuthor.fromJson(Map<String, dynamic> json) {
    return ArticleAuthor(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? '',
      image: json['image'] as String?,
    );
  }

  String get imageUrl {
    if (image == null || image!.isEmpty) return '';
    if (image!.startsWith('http')) return image!;
    return '$_kBaseUrl$image';
  }
}

class ArticleCategory {
  final int id;
  final String name;
  final String slug;

  const ArticleCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory ArticleCategory.fromJson(Map<String, dynamic> json) {
    return ArticleCategory(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? '',
      slug: (json['slug'] as String?) ?? '',
    );
  }
}

class Article {
  final int id;
  final String title;
  final String slug;
  final String? summary;
  final String? featuredImage;
  final String? featuredImageAlt;
  final bool isFeatured;
  final bool isBreaking;
  final int viewCount;
  final int? readTime;
  final String? publishedAt;
  final ArticleCategory? category;
  final ArticleAuthor? author;
  // Detail-only fields
  final String? content;
  final String? featuredImageCaption;
  final String? featuredImageCredit;

  // In-article map + tagged-project fields (Spec 6). Not sent by the
  // current backend (`_article_dict` in api.py has no `map_enabled`/
  // `map_type`/`map_center`/`map_route`/`tagged_project` keys) — these all
  // default to absent so the map/tagged-project card widgets stay dormant
  // until the API adds them.
  final bool mapEnabled;
  final String? mapType;
  final LatLng? mapCenter;
  final List<LatLng>? mapRoute;
  final ArticleTaggedProject? taggedProject;

  const Article({
    required this.id,
    required this.title,
    required this.slug,
    this.summary,
    this.featuredImage,
    this.featuredImageAlt,
    required this.isFeatured,
    required this.isBreaking,
    required this.viewCount,
    this.readTime,
    this.publishedAt,
    this.category,
    this.author,
    this.content,
    this.featuredImageCaption,
    this.featuredImageCredit,
    this.mapEnabled = false,
    this.mapType,
    this.mapCenter,
    this.mapRoute,
    this.taggedProject,
  });

  static LatLng? _parseLatLng(dynamic value) {
    if (value is! List || value.length < 2) return null;
    final lat = (value[0] as num?)?.toDouble();
    final lng = (value[1] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  static List<LatLng>? _parseRoute(dynamic value) {
    if (value is! List) return null;
    final points = value.map(_parseLatLng).whereType<LatLng>().toList();
    return points.isEmpty ? null : points;
  }

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: (json['id'] as num).toInt(),
      title: (json['title'] as String?) ?? '',
      slug: (json['slug'] as String?) ?? '',
      summary: json['summary'] as String?,
      featuredImage: json['featured_image'] as String?,
      featuredImageAlt: json['featured_image_alt'] as String?,
      isFeatured: (json['is_featured'] as bool?) ?? false,
      isBreaking: (json['is_breaking'] as bool?) ?? false,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      readTime: (json['read_time'] as num?)?.toInt(),
      publishedAt: json['published_at'] as String?,
      category: json['category'] != null
          ? ArticleCategory.fromJson(
              json['category'] as Map<String, dynamic>)
          : null,
      author: json['author'] != null
          ? ArticleAuthor.fromJson(json['author'] as Map<String, dynamic>)
          : null,
      content: json['content'] as String?,
      featuredImageCaption: json['featured_image_caption'] as String?,
      featuredImageCredit: json['featured_image_credit'] as String?,
      mapEnabled: (json['map_enabled'] as bool?) ?? false,
      mapType: json['map_type'] as String?,
      mapCenter: _parseLatLng(json['map_center']),
      mapRoute: _parseRoute(json['map_route']),
      taggedProject: json['tagged_project'] != null
          ? ArticleTaggedProject.fromJson(json['tagged_project'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Full image URL (handles relative paths from the Flask server).
  String? get imageUrl {
    if (featuredImage == null || featuredImage!.isEmpty) return null;
    if (featuredImage!.startsWith('http')) return featuredImage;
    return '$_kBaseUrl$featuredImage';
  }

  /// Human-readable time since publication.
  String get timeAgo {
    if (publishedAt == null) return '';
    try {
      final date = DateTime.parse(publishedAt!).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} yr ago';
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} mo ago';
      if (diff.inDays >= 1) return '${diff.inDays} d ago';
      if (diff.inHours >= 1) return '${diff.inHours} h ago';
      if (diff.inMinutes >= 1) return '${diff.inMinutes} min ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }

  /// Formatted view count (e.g. 1.2k).
  String get formattedViews {
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M';
    }
    if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(0)}k';
    }
    return viewCount.toString();
  }

  /// Strip HTML tags from content for plain-text rendering, preserving
  /// paragraph breaks. Block-level closing tags become blank lines (and
  /// `<br>` a single line break) *before* the remaining tags are stripped —
  /// otherwise `</p><p>` collapses to nothing and every paragraph in the
  /// source HTML runs together into one unbroken block of text.
  String get plainContent {
    if (content == null) return '';
    return content!
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</(p|div|li|h[1-6])>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&quot;'), '"')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  /// [plainContent] split into individual paragraphs, so callers can render
  /// each with proper spacing between them instead of one run-on block.
  List<String> get paragraphs => plainContent
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();
}
