// lib/news/models/article_model.dart

const String _kBaseUrl = 'https://mjengohub.co.ke';

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
  });

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

  /// Strip HTML tags from content for plain-text rendering.
  String get plainContent {
    if (content == null) return '';
    return content!
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&quot;'), '"')
        .trim();
  }
}
