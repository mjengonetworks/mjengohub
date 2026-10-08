import 'feed_model.dart';

class FeedComment {
  final int id;
  final String content;
  final FeedAuthor author;
  final DateTime? createdAt;
  final int? parentId;
  final int? rootId;
  final int? replyCount;
  final String? status;
  final int upvotes;
  final int downvotes;
  final String? voteType;
  final List<FeedComment> replies;

  const FeedComment({
    required this.id,
    required this.content,
    this.author = const FeedAuthor(),
    this.createdAt,
    this.parentId,
    this.rootId,
    this.replyCount,
    this.status,
    this.upvotes = 0,
    this.downvotes = 0,
    this.voteType,
    this.replies = const [],
  });

  factory FeedComment.fromJson(dynamic value) {
    if (value is! Map) {
      throw const FormatException('Invalid Feed discussion comment.');
    }
    final rawReplies = value['replies'];
    return FeedComment(
      id: _int(value['id']) ?? 0,
      content: _string(value['text']) ?? _string(value['content']) ?? '',
      author: FeedAuthor.fromJson(value['author']),
      createdAt: _date(value['published_at'] ?? value['created_at']),
      parentId: _int(value['parent_id']),
      rootId: _int(value['root_id']),
      replyCount: _int(value['reply_count'] ?? value['comment_count']),
      status: _string(value['status']),
      upvotes:
          _int(
            value['engagement'] is Map
                ? value['engagement']['upvote_count']
                : value['upvotes'],
          ) ??
          0,
      downvotes:
          _int(
            value['engagement'] is Map
                ? value['engagement']['downvote_count']
                : value['downvotes'],
          ) ??
          0,
      voteType: _string(
        value['engagement'] is Map
            ? value['engagement']['vote_type']
            : value['vote_type'],
      ),
      replies: rawReplies is List
          ? rawReplies.map(FeedComment.fromJson).toList()
          : const [],
    );
  }

  bool get isPending => status == 'moderation';
  int get netScore => upvotes - downvotes;

  FeedComment copyWith({
    int? upvotes,
    int? downvotes,
    String? voteType,
    List<FeedComment>? replies,
  }) => FeedComment(
    id: id,
    content: content,
    author: author,
    createdAt: createdAt,
    parentId: parentId,
    rootId: rootId,
    replyCount: replyCount,
    status: status,
    upvotes: upvotes ?? this.upvotes,
    downvotes: downvotes ?? this.downvotes,
    voteType: voteType ?? this.voteType,
    replies: replies ?? this.replies,
  );
}

class FeedDiscussionPage {
  final FeedItem? post;
  final List<FeedComment> comments;
  final int page;
  final int perPage;
  final bool hasNext;
  final int? nextPage;

  const FeedDiscussionPage({
    this.post,
    this.comments = const [],
    this.page = 1,
    this.perPage = 20,
    this.hasNext = false,
    this.nextPage,
  });

  factory FeedDiscussionPage.fromResponse(dynamic body) {
    if (body is! Map || body['data'] is! Map) {
      throw const FormatException('Invalid Feed discussion response.');
    }
    final data = body['data'] as Map;
    final rawComments = data['comments'];
    final pagination = body['pagination'];
    return FeedDiscussionPage(
      post: data['post'] is Map ? FeedItem.fromJson(data['post']) : null,
      comments: rawComments is List
          ? rawComments.map(FeedComment.fromJson).toList()
          : const [],
      page: _int(pagination is Map ? pagination['page'] : null) ?? 1,
      perPage: _int(pagination is Map ? pagination['per_page'] : null) ?? 20,
      hasNext: pagination is Map && pagination['has_next'] == true,
      nextPage: _int(pagination is Map ? pagination['next_page'] : null),
    );
  }
}

class FeedCommentResult {
  final FeedComment comment;
  final String status;
  final String? message;

  const FeedCommentResult({
    required this.comment,
    required this.status,
    this.message,
  });

  bool get isPublished => status == 'published';
  bool get isPending => status == 'moderation';

  factory FeedCommentResult.fromResponse(dynamic body) {
    if (body is! Map || body['data'] is! Map) {
      throw const FormatException('Invalid Feed comment response.');
    }
    final data = body['data'] as Map;
    final comment = FeedComment.fromJson(data);
    final status = _string(data['status']) ?? comment.status;
    if (status == null) {
      throw const FormatException('Feed comment response has no status.');
    }
    return FeedCommentResult(
      comment: comment,
      status: status,
      message: _string(body['message']),
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
