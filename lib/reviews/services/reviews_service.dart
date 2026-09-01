// lib/reviews/services/reviews_service.dart
//
// Wraps api.py's `/reviews` endpoints. Note the asymmetry: GET returns only
// approved reviews, POST creates one with `is_approved=False`, so the UI must
// tell the user their review is pending moderation rather than optimistically
// inserting it into the list.
import 'package:get/get.dart';

import '../../services/base_service.dart';
import '../models/review_model.dart';

class ReviewsService {
  BaseService get _api => Get.find<BaseService>();

  Future<({List<ClientReview> items, int total, int pages})> getReviews({
    int page = 1,
    int perPage = 12,
  }) async {
    try {
      final res = await _api.getRequest('reviews', query: {
        'page': '$page',
        'per_page': '$perPage',
      });
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        final pag = res.body['pagination'];
        if (data is List) {
          return (
            items: data
                .whereType<Map<String, dynamic>>()
                .map(ClientReview.fromJson)
                .toList(),
            total: (pag is Map ? (pag['total'] as num?)?.toInt() : null) ?? 0,
            pages: (pag is Map ? (pag['pages'] as num?)?.toInt() : null) ?? 1,
          );
        }
      }
    } catch (e) {
      print('❌ getReviews failed: $e');
    }
    return (items: <ClientReview>[], total: 0, pages: 1);
  }

  /// [rating] must be an int 1–5; the backend rejects anything else with a 400.
  Future<Map<String, dynamic>> submitReview({
    required String clientName,
    required String clientEmail,
    required String reviewText,
    required int rating,
  }) async {
    try {
      final res = await _api.postRequest('reviews', {
        'client_name': clientName,
        'client_email': clientEmail,
        'review_text': reviewText,
        'rating': rating,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = res.body?['data'];
        return {
          'success': true,
          'message': (data is Map ? data['message'] as String? : null) ??
              'Review submitted and awaiting approval',
        };
      }
      return {'success': false, 'message': _errorMessage(res.body)};
    } catch (e) {
      print('❌ submitReview failed: $e');
      return {'success': false, 'message': 'Could not submit review. Check your connection.'};
    }
  }

  String _errorMessage(dynamic body) {
    if (body is Map) {
      final msg = body['message'] ?? body['error'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return 'Could not submit review. Please try again.';
  }
}
