import 'package:get/get.dart';

import '../../services/base_service.dart';

const feedReportReasons = {
  'spam': 'Spam',
  'harassment': 'Harassment',
  'hate': 'Hateful content',
  'violence': 'Violence or threats',
  'misinformation': 'Misinformation',
  'privacy': 'Privacy violation',
  'other': 'Other',
};

class FeedReportException implements Exception {
  final String message;
  final int? statusCode;
  const FeedReportException(this.message, {this.statusCode});

  bool get requiresSignIn => statusCode == 401 || statusCode == 422;
  @override
  String toString() => message;
}

class FeedReportResult {
  final int postId;
  final bool alreadyReported;
  const FeedReportResult({required this.postId, this.alreadyReported = false});

  factory FeedReportResult.fromResponse(dynamic body) {
    if (body is! Map || body['success'] != true || body['data'] is! Map) {
      throw const FormatException('Invalid report response.');
    }
    final data = body['data'] as Map;
    final id = data['post_id'];
    final status = data['status'];
    if (id is! int ||
        id <= 0 ||
        (status != 'reported' && status != 'already_reported')) {
      throw const FormatException('Invalid report response.');
    }
    return FeedReportResult(
      postId: id,
      alreadyReported: status == 'already_reported',
    );
  }
}

class FeedReportService {
  final BaseService? api;
  FeedReportService({this.api});

  Future<FeedReportResult> report(
    int postId, {
    required String reason,
    String? explanation,
  }) async {
    if (postId <= 0 || !feedReportReasons.containsKey(reason)) {
      throw const FeedReportException('Choose a valid report reason.');
    }
    final text = explanation?.trim() ?? '';
    // Count Unicode code points, matching Python's character limit.
    if (text.runes.length > 400) {
      throw const FeedReportException(
        'Explanation must be at most 400 characters.',
      );
    }
    final response = await (api ?? Get.find<BaseService>()).postRequest(
      'feed/posts/$postId/report',
      {'reason': reason, if (text.isNotEmpty) 'explanation': text},
    );
    final body = response.body;
    if ((response.statusCode != 200 && response.statusCode != 201) ||
        body is! Map ||
        body['success'] != true) {
      final message = body is Map
          ? body['error'] ?? body['message'] ?? body['msg']
          : null;
      final fallback = switch (response.statusCode) {
        401 || 422 => 'Your session expired. Please sign in again.',
        403 => 'Your account cannot report this content.',
        404 => 'This content is no longer available for reporting.',
        429 => 'Too many reports. Please try again shortly.',
        _ => 'Could not send your report. Please try again.',
      };
      throw FeedReportException(
        response.statusCode == 401 || response.statusCode == 422
            ? fallback
            : message is String &&
                  message.isNotEmpty &&
                  message != 'NETWORK_ERROR'
            ? message
            : fallback,
        statusCode: response.statusCode,
      );
    }
    try {
      final result = FeedReportResult.fromResponse(body);
      if (result.postId != postId) {
        throw const FormatException('Wrong report target.');
      }
      return result;
    } on FormatException {
      throw const FeedReportException(
        'Could not confirm your report. Please try again.',
      );
    }
  }
}
