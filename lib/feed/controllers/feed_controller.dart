// lib/feed/controllers/feed_controller.dart
import 'package:get/get.dart';

import '../models/feed_model.dart';
import '../services/feed_api_service.dart';
import '../services/feed_vote_service.dart';

class FeedController extends GetxController {
  final FeedApiService _service;
  final bool loadOnInit;

  FeedController({FeedApiService? service, this.loadOnInit = true})
    : _service = service ?? FeedApiService();

  final items = <FeedItem>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = RxnString();
  final hasNext = false.obs;
  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    if (loadOnInit) load();
  }

  Future<void> load() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = null;
    _page = 1;
    try {
      final result = await _service.getFeed(page: 1);
      items.assignAll(result.items);
      hasNext.value = result.hasNext;
      _page = result.page;
    } catch (error) {
      errorMessage.value = error is FeedApiException
          ? error.message
          : 'Could not load the Feed. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshFeed() => load();

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasNext.value) return;
    isLoadingMore.value = true;
    try {
      final result = await _service.getFeed(page: _page + 1);
      items.addAll(result.items);
      hasNext.value = result.hasNext;
      _page = result.page;
    } catch (error) {
      errorMessage.value = error is FeedApiException
          ? error.message
          : 'Could not load more Feed posts.';
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<FeedPublishResult> publishPost(
    String content, {
    List<FeedUploadAttachment> attachments = const [],
  }) => _service.createPost(content: content, attachments: attachments);

  Future<FeedVoteResult> vote(FeedItem item, String voteType) async {
    final id = item.id ?? item.feedPostId;
    if (id == null) {
      throw const FeedVoteException('This Feed item cannot be voted on.');
    }
    final result = await _service.vote(id, voteType);
    final index = items.indexWhere(
      (current) => (current.id ?? current.feedPostId) == id,
    );
    if (index >= 0) {
      items[index] = items[index].copyWith(
        engagement: FeedEngagement(
          upvoteCount: result.upvotes,
          downvoteCount: result.downvotes,
          score: result.score,
          voteType: result.voteType,
        ),
      );
    }
    return result;
  }

  void insertPublished(FeedItem item) {
    items.insert(0, item);
  }
}
