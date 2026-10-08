import 'package:get/get.dart';

import '../../services/base_service.dart';
import '../models/feed_discussion_model.dart';

class FeedDiscussionException implements Exception {
  final String message;
  const FeedDiscussionException(this.message);
}

class FeedDiscussionService {
  BaseService get _api => Get.find<BaseService>();

  Future<FeedDiscussionPage> getDiscussion(
    int postId, {
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _api.getRequest(
      'feed/posts/$postId/comments',
      query: {'page': '$page', 'per_page': '$perPage'},
    );
    if (response.statusCode != 200 || response.body is! Map) {
      throw FeedDiscussionException(
        response.statusText ?? 'Could not load the discussion.',
      );
    }
    final body = response.body as Map;
    if (body['success'] == false) {
      throw FeedDiscussionException(
        body['error'] is String
            ? body['error'] as String
            : 'Could not load the discussion.',
      );
    }
    return FeedDiscussionPage.fromResponse(body);
  }

  Future<FeedCommentResult> createComment(
    int postId, {
    required String content,
    int? parentId,
  }) async {
    final response = await _api.postRequest('feed/posts/$postId/comments', {
      'content': content,
      ...?parentId == null ? null : {'parent_id': parentId},
    });
    final body = response.body;
    if (response.statusCode != 201 || body is! Map || body['success'] != true) {
      final message = body is Map ? body['error'] ?? body['message'] : null;
      throw FeedDiscussionException(
        message is String && message.isNotEmpty
            ? message
            : 'Could not publish your comment.',
      );
    }
    return FeedCommentResult.fromResponse(body);
  }
}
