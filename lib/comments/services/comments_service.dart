// lib/comments/services/comments_service.dart
import 'package:get/get.dart';

import '../../services/base_service.dart';
import '../models/comment_model.dart';

/// Which polymorphic resource a comment thread is attached to. Maps to the
/// api.py path prefixes for `/api/v1/{prefix}/{id}/comments`.
enum CommentResource { article, project, incident, mentalHealthPost }

extension on CommentResource {
  String get pathPrefix {
    switch (this) {
      case CommentResource.article:
        return 'articles';
      case CommentResource.project:
        return 'projects';
      case CommentResource.incident:
        return 'incidents';
      case CommentResource.mentalHealthPost:
        return 'mental-health/posts';
    }
  }
}

class CommentsService {
  BaseService get _api => Get.find<BaseService>();

  Future<List<ThreadedComment>> getComments(CommentResource resource, int id) async {
    try {
      final res = await _api.getRequest('${resource.pathPrefix}/$id/comments');
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is List) {
          final flat = data
              .whereType<Map<String, dynamic>>()
              .map(ThreadedComment.fromJson)
              .toList();
          return ThreadedComment.buildTree(flat);
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<ThreadedComment?> postComment(
    CommentResource resource,
    int id, {
    required String content,
    required String name,
    String? email,
    int? parentId,
  }) async {
    try {
      final res = await _api.postRequest('${resource.pathPrefix}/$id/comments', {
        'content': content,
        'name': name,
        if (email != null) 'email': email,
        if (parentId != null) 'parent_id': parentId,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = res.body?['data'];
        if (data is Map<String, dynamic>) return ThreadedComment.fromJson(data);
        // Some endpoints only return {success:true} — synthesize a local echo.
        return ThreadedComment(
          id: DateTime.now().millisecondsSinceEpoch,
          authorName: name,
          content: content,
          parentId: parentId,
          createdAt: DateTime.now(),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> vote(int commentId, {required bool up}) async {
    try {
      final res = await _api.postRequest('comments/$commentId/vote', {
        'vote_type': up ? 'up' : 'down',
      });
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // NOTE: comment reporting is intentionally absent. The website has a
  // session-based `POST /comments/<id>/report` (application.py) backed by a
  // `comment_reports` table, but it was never exposed under `/api/v1/`, so the
  // previous `report()` helper here always 404'd. It was unused by any screen
  // and has been removed rather than left as a silent no-op; re-add it once
  // api.py grows a `/comments/<int:comment_id>/report` route.
}
