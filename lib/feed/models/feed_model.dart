// lib/feed/models/feed_model.dart

class FeedAuthor {
  final int? id;
  final String? displayName;
  final String? avatarUrl;
  final String? kind;
  final bool isEditorial;

  const FeedAuthor({
    this.id,
    this.displayName,
    this.avatarUrl,
    this.kind,
    this.isEditorial = false,
  });

  factory FeedAuthor.fromJson(dynamic value) {
    if (value is! Map) return const FeedAuthor();
    return FeedAuthor(
      id: _int(value['id']),
      displayName: _string(value['display_name']),
      avatarUrl: _string(value['avatar_url']),
      kind: _string(value['kind']),
      isEditorial: value['is_editorial'] == true,
    );
  }
}

class FeedMedia {
  final int? id;
  final String? mediaType;
  final String? url;
  final String? caption;
  final String? altText;
  final String? credit;

  const FeedMedia({
    this.id,
    this.mediaType,
    this.url,
    this.caption,
    this.altText,
    this.credit,
  });

  factory FeedMedia.fromJson(dynamic value) {
    if (value is! Map) return const FeedMedia();
    return FeedMedia(
      id: _int(value['id']),
      mediaType: _string(value['media_type']),
      url: _string(value['url']),
      caption: _string(value['caption']),
      altText: _string(value['alt_text']),
      credit: _string(value['credit']),
    );
  }
}

class FeedSource {
  final String? type;
  final int? id;
  final String? title;
  final String? summary;
  final String? imageUrl;
  final String? canonicalUrl;
  final String? articleSlug;
  final String? articleCategory;
  final String? projectSlug;
  final String? incidentSlug;

  const FeedSource({
    this.type,
    this.id,
    this.title,
    this.summary,
    this.imageUrl,
    this.canonicalUrl,
    this.articleSlug,
    this.articleCategory,
    this.projectSlug,
    this.incidentSlug,
  });

  factory FeedSource.fromJson(dynamic value) {
    if (value is! Map) return const FeedSource();
    return FeedSource(
      type: _string(value['type']),
      id: _int(value['id']),
      title: _string(value['title']),
      summary: _string(value['summary']),
      imageUrl: _string(value['image_url']),
      canonicalUrl: _string(value['canonical_url']),
      articleSlug: _string(value['article_slug']),
      articleCategory: _string(value['article_category']),
      projectSlug: _string(value['project_slug']),
      incidentSlug: _string(value['incident_slug']),
    );
  }

  bool get hasNativeDestination =>
      articleSlug != null || projectSlug != null || incidentSlug != null;
}

class FeedEngagement {
  final int? upvoteCount;
  final int? downvoteCount;
  final int? shareCount;

  const FeedEngagement({this.upvoteCount, this.downvoteCount, this.shareCount});

  factory FeedEngagement.fromJson(dynamic value) {
    if (value is! Map) return const FeedEngagement();
    return FeedEngagement(
      upvoteCount: _int(value['upvote_count']),
      downvoteCount: _int(value['downvote_count']),
      shareCount: _int(value['share_count']),
    );
  }
}

class FeedItem {
  final int? id;
  final int? feedPostId;
  final String postType;
  final String? status;
  final FeedAuthor author;
  final DateTime? publishedAt;
  final String? text;
  final List<FeedMedia> media;
  final String? sourceType;
  final int? sourceId;
  final FeedSource? source;
  final String? canonicalUrl;
  final int? commentCount;
  final FeedEngagement? engagement;

  const FeedItem({
    this.id,
    this.feedPostId,
    this.postType = 'community',
    this.status,
    this.author = const FeedAuthor(),
    this.publishedAt,
    this.text,
    this.media = const [],
    this.sourceType,
    this.sourceId,
    this.source,
    this.canonicalUrl,
    this.commentCount,
    this.engagement,
  });

  factory FeedItem.fromJson(dynamic value) {
    if (value is! Map) return const FeedItem();
    final rawMedia = value['media'];
    return FeedItem(
      id: _int(value['id']),
      feedPostId: _int(value['feed_post_id']),
      postType: _string(value['post_type']) ?? 'community',
      status: _string(value['status']),
      author: FeedAuthor.fromJson(value['author']),
      publishedAt: _date(value['published_at']),
      text: _string(value['text']),
      media: rawMedia is List
          ? rawMedia.map(FeedMedia.fromJson).toList()
          : const [],
      sourceType: _string(value['source_type']),
      sourceId: _int(value['source_id']),
      source: value['source'] is Map
          ? FeedSource.fromJson(value['source'])
          : null,
      canonicalUrl: _string(value['canonical_url']),
      commentCount: _int(value['comment_count']),
      engagement: value['engagement'] is Map
          ? FeedEngagement.fromJson(value['engagement'])
          : null,
    );
  }
}

class FeedPublishResult {
  final FeedItem item;
  final String status;
  final String? message;

  const FeedPublishResult({
    required this.item,
    required this.status,
    this.message,
  });

  bool get isPublished => status == 'published';
  bool get isPending => status == 'moderation';

  factory FeedPublishResult.fromResponse(dynamic body) {
    if (body is! Map) {
      throw const FormatException('Invalid Feed publish response.');
    }
    final raw = body['data'];
    if (raw is! Map) {
      throw const FormatException('Feed publish response has no post.');
    }
    final item = FeedItem.fromJson(raw);
    final status = item.status ?? _string(raw['status']);
    if (status == null) {
      throw const FormatException('Feed publish response has no status.');
    }
    return FeedPublishResult(
      item: item,
      status: status,
      message: _string(body['message']),
    );
  }
}

class FeedPage {
  final List<FeedItem> items;
  final int page;
  final int perPage;
  final bool hasNext;
  final int? nextPage;

  const FeedPage({
    this.items = const [],
    this.page = 1,
    this.perPage = 15,
    this.hasNext = false,
    this.nextPage,
  });

  factory FeedPage.fromResponse(dynamic body) {
    if (body is! Map) return const FeedPage();
    final rawItems = body['data'];
    final pagination = body['pagination'];
    return FeedPage(
      items: rawItems is List
          ? rawItems.map(FeedItem.fromJson).toList()
          : const [],
      page: _int(pagination is Map ? pagination['page'] : null) ?? 1,
      perPage: _int(pagination is Map ? pagination['per_page'] : null) ?? 15,
      hasNext: pagination is Map && pagination['has_next'] == true,
      nextPage: _int(pagination is Map ? pagination['next_page'] : null),
    );
  }
}

String? _string(dynamic value) {
  if (value is! String) return null;
  final result = value.trim();
  return result.isEmpty ? null : result;
}

int? _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value');

DateTime? _date(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;
