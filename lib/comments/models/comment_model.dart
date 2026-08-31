// lib/comments/models/comment_model.dart
//
// Generic threaded comment, matching the website's polymorphic `Comment`
// model (commentable_type/commentable_id + self-referential parent_id).
class ThreadedComment {
  final int id;
  final int? userId;
  final String authorName;
  final String? authorPhotoUrl;
  final int authorPoints; // used to render the reviewer-level badge live
  final String content;
  final int? parentId;
  final int upvotes;
  final int downvotes;
  final DateTime? createdAt;
  final List<ThreadedComment> replies;
  final String? myVote; // 'up' | 'down' | null — client-local optimistic state

  const ThreadedComment({
    required this.id,
    this.userId,
    required this.authorName,
    this.authorPhotoUrl,
    this.authorPoints = 0,
    required this.content,
    this.parentId,
    this.upvotes = 0,
    this.downvotes = 0,
    this.createdAt,
    this.replies = const [],
    this.myVote,
  });

  int get netScore => upvotes - downvotes;

  factory ThreadedComment.fromJson(Map<String, dynamic> j) {
    final repliesJson = j['replies'] as List? ?? const [];
    return ThreadedComment(
      id: (j['id'] as num?)?.toInt() ?? 0,
      userId: (j['user_id'] as num?)?.toInt(),
      authorName: (j['commenter_name'] as String?) ??
          (j['author_name'] as String?) ??
          'Anonymous',
      authorPhotoUrl: j['author_photo'] as String? ?? j['author_image'] as String?,
      authorPoints: (j['author_points'] as num?)?.toInt() ?? 0,
      content: (j['content'] as String?) ?? '',
      parentId: (j['parent_id'] as num?)?.toInt(),
      upvotes: (j['upvotes'] as num?)?.toInt() ?? 0,
      downvotes: (j['downvotes'] as num?)?.toInt() ?? 0,
      createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at'].toString()) : null,
      replies: repliesJson
          .whereType<Map<String, dynamic>>()
          .map(ThreadedComment.fromJson)
          .toList(),
    );
  }

  ThreadedComment copyWith({
    int? upvotes,
    int? downvotes,
    String? myVote,
    List<ThreadedComment>? replies,
  }) {
    return ThreadedComment(
      id: id,
      userId: userId,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      authorPoints: authorPoints,
      content: content,
      parentId: parentId,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      createdAt: createdAt,
      replies: replies ?? this.replies,
      myVote: myVote ?? this.myVote,
    );
  }

  /// Builds a top-level -> replies tree from a flat list, mirroring the
  /// website's `comment_utils.build_comment_tree()`: top-level sorted by
  /// (score desc, newest first), replies chronological.
  static List<ThreadedComment> buildTree(List<ThreadedComment> flat) {
    final byId = <int, ThreadedComment>{for (final c in flat) c.id: c};
    final childrenOf = <int, List<ThreadedComment>>{};
    final roots = <ThreadedComment>[];

    for (final c in flat) {
      if (c.parentId != null && byId.containsKey(c.parentId)) {
        childrenOf.putIfAbsent(c.parentId!, () => []).add(c);
      } else {
        roots.add(c);
      }
    }

    ThreadedComment attach(ThreadedComment c) {
      final kids = (childrenOf[c.id] ?? [])
        ..sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
      return c.copyWith(replies: kids.map(attach).toList());
    }

    roots.sort((a, b) {
      final scoreCmp = b.netScore.compareTo(a.netScore);
      if (scoreCmp != 0) return scoreCmp;
      return (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0));
    });

    return roots.map(attach).toList();
  }
}
