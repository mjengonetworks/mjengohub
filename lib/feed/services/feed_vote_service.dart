import 'package:get/get.dart';

import '../../services/base_service.dart';

class FeedVoteException implements Exception {
  final String message;
  const FeedVoteException(this.message);
}

class FeedVoteResult {
  final String? voteType;
  final int upvotes;
  final int downvotes;
  final int score;
  final String? action;

  const FeedVoteResult({
    this.voteType,
    this.upvotes = 0,
    this.downvotes = 0,
    this.score = 0,
    this.action,
  });

  factory FeedVoteResult.fromResponse(dynamic body) {
    final data = body is Map && body['data'] is Map
        ? body['data'] as Map
        : body;
    if (data is! Map) throw const FormatException('Invalid vote response.');
    return FeedVoteResult(
      voteType: _string(data['vote_type']),
      upvotes: _int(data['upvotes']) ?? _int(data['upvote_count']) ?? 0,
      downvotes: _int(data['downvotes']) ?? _int(data['downvote_count']) ?? 0,
      score: _int(data['score']) ?? 0,
      action: _string(data['action']),
    );
  }
}

class FeedVoteService {
  BaseService get _api => Get.find<BaseService>();

  Future<FeedVoteResult> vote(int postId, String voteType) async {
    final response = await _api.postRequest('feed/posts/$postId/vote', {
      'vote_type': voteType,
    });
    final body = response.body;
    if (response.statusCode != 200 || body is! Map || body['success'] != true) {
      final message = body is Map ? body['error'] ?? body['message'] : null;
      throw FeedVoteException(
        message is String && message.isNotEmpty
            ? message
            : 'Could not record your vote.',
      );
    }
    return FeedVoteResult.fromResponse(body);
  }
}

String? _string(dynamic value) {
  if (value is! String) return null;
  final result = value.trim();
  return result.isEmpty ? null : result;
}

int? _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value');
