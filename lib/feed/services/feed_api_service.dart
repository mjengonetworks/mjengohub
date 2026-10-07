// lib/feed/services/feed_api_service.dart
import 'package:get/get.dart';

import '../../services/base_service.dart';
import '../models/feed_model.dart';

class FeedApiException implements Exception {
  final String message;
  const FeedApiException(this.message);

  @override
  String toString() => message;
}

class FeedApiService {
  BaseService get _api => Get.find<BaseService>();

  Future<FeedPage> getFeed({int page = 1, int perPage = 15}) async {
    final response = await _api.getRequest(
      'feed',
      query: {'page': '$page', 'per_page': '$perPage'},
    );
    if (response.statusCode != 200 || response.body is! Map) {
      throw FeedApiException(response.statusText ?? 'Could not load the Feed.');
    }
    final body = response.body as Map;
    if (body['success'] == false) {
      throw FeedApiException(
        body['error'] is String
            ? body['error'] as String
            : 'Could not load the Feed.',
      );
    }
    return FeedPage.fromResponse(body);
  }
}
