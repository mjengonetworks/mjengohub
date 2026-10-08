import 'package:get/get.dart';

import '../models/feed_discussion_model.dart';
import '../services/feed_discussion_service.dart';

class FeedDiscussionController extends GetxController {
  final int postId;
  final FeedDiscussionService _service;

  FeedDiscussionController(this.postId, {FeedDiscussionService? service})
    : _service = service ?? FeedDiscussionService();

  final comments = <FeedComment>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = RxnString();
  final pendingMessage = RxnString();
  final hasNext = false.obs;
  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = null;
    _page = 1;
    try {
      final result = await _service.getDiscussion(postId);
      comments.assignAll(result.comments);
      hasNext.value = result.hasNext;
      _page = result.page;
    } catch (error) {
      errorMessage.value = error is FeedDiscussionException
          ? error.message
          : 'Could not load the discussion.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasNext.value) return;
    isLoadingMore.value = true;
    try {
      final result = await _service.getDiscussion(postId, page: _page + 1);
      final known = comments.map((comment) => comment.id).toSet();
      comments.addAll(
        result.comments.where((comment) => !known.contains(comment.id)),
      );
      hasNext.value = result.hasNext;
      _page = result.page;
    } catch (error) {
      errorMessage.value = error is FeedDiscussionException
          ? error.message
          : 'Could not load more discussion.';
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<FeedCommentResult> submit(String content, {int? parentId}) async {
    pendingMessage.value = null;
    try {
      final result = await _service.createComment(
        postId,
        content: content,
        parentId: parentId,
      );
      if (result.isPending) {
        pendingMessage.value =
            result.message ??
            'Your comment was submitted and is awaiting moderation.';
      } else {
        await load();
      }
      return result;
    } catch (_) {
      rethrow;
    }
  }
}
