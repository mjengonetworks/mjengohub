import 'package:flutter_test/flutter_test.dart';

import 'package:mjengo_hub_app/feed/controllers/feed_discussion_controller.dart';
import 'package:mjengo_hub_app/feed/models/feed_discussion_model.dart';
import 'package:mjengo_hub_app/feed/services/feed_discussion_service.dart';

class _FakeDiscussionService extends FeedDiscussionService {
  FeedDiscussionPage page = const FeedDiscussionPage(
    comments: [
      FeedComment(
        id: 1,
        content: 'Root comment',
        replies: [FeedComment(id: 2, content: 'Nested reply', parentId: 1)],
      ),
    ],
  );
  FeedCommentResult result = const FeedCommentResult(
    comment: FeedComment(id: 3, content: 'Pending'),
    status: 'moderation',
    message: 'Awaiting moderation.',
  );

  @override
  Future<FeedDiscussionPage> getDiscussion(
    int postId, {
    int page = 1,
    int perPage = 20,
  }) async => page == 1 ? this.page : const FeedDiscussionPage();

  @override
  Future<FeedCommentResult> createComment(
    int postId, {
    required String content,
    int? parentId,
  }) async => result;
}

void main() {
  test('parses nested Feed discussion comments without vote fields', () {
    final page = FeedDiscussionPage.fromResponse({
      'success': true,
      'data': {
        'post': {'id': 8, 'text': 'Post'},
        'comments': [
          {
            'id': 1,
            'content': 'Comment',
            'author': {'display_name': 'A builder'},
            'replies': [
              {'id': 2, 'content': 'Reply', 'parent_id': 1},
            ],
          },
        ],
      },
      'pagination': {'page': 1, 'per_page': 20, 'has_next': false},
    });

    expect(page.post?.id, 8);
    expect(page.comments.single.replies.single.parentId, 1);
    expect(page.comments.single.author.displayName, 'A builder');
  });

  test(
    'controller keeps moderated submissions out of the public tree',
    () async {
      final fake = _FakeDiscussionService();
      final controller = FeedDiscussionController(8, service: fake);

      await controller.load();
      expect(controller.comments.single.replies.single.id, 2);

      final result = await controller.submit('pending');
      expect(result.isPending, isTrue);
      expect(controller.pendingMessage.value, 'Awaiting moderation.');
      expect(controller.comments.single.id, 1);
    },
  );
}
