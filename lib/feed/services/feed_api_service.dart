// lib/feed/services/feed_api_service.dart
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

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

  Future<FeedPublishResult> createPost({
    required String content,
    int? pageId,
    List<FeedUploadAttachment> attachments = const [],
  }) async {
    final payload = <String, dynamic>{
      'content': content,
      if (pageId != null) 'page_id': pageId,
    };
    final response = attachments.isEmpty
        ? await _api.postRequest('feed/posts', payload)
        : await _api.postMultipart(
            'feed/posts',
            fields: payload.map((key, value) => MapEntry(key, '$value')),
            files: attachments
                .map(
                  (attachment) => http.MultipartFile.fromBytes(
                    'media',
                    attachment.bytes,
                    filename: attachment.filename,
                  ),
                )
                .toList(),
          );
    final body = response.body;
    if (response.statusCode != 201 || body is! Map || body['success'] != true) {
      final message = body is Map
          ? body['error'] ?? body['message']
          : response.statusText;
      throw FeedApiException(
        message is String && message.isNotEmpty
            ? message
            : 'Could not publish your Feed post.',
      );
    }
    try {
      return FeedPublishResult.fromResponse(body);
    } on FormatException catch (error) {
      throw FeedApiException(error.message);
    }
  }
}
