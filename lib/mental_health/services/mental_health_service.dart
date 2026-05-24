// lib/mental_health/services/mental_health_service.dart
import 'package:get/get.dart';
import '../../services/base_service.dart';
import '../models/mental_health_model.dart';

class MentalHealthService {
  BaseService get _api => Get.find<BaseService>();

  Future<List<MentalHealthPost>> getPosts({int page = 1}) async {
    try {
      final res = await _api.getRequest('mental-health/posts', query: {
        'page': '$page',
        'per_page': '20',
      });
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map(MentalHealthPost.fromJson)
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('MentalHealthService.getPosts error: $e');
      return [];
    }
  }

  Future<bool> submitPost({
    required String message,
    String? authorName,
    bool isAnonymous = true,
  }) async {
    try {
      final res = await _api.postRequest('mental-health/posts', {
        'message': message,
        'author_name': authorName ?? 'Anonymous',
        'is_anonymous': isAnonymous,
      });
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('MentalHealthService.submitPost error: $e');
      return false;
    }
  }

  Future<List<MentalHealthVideo>> getVideos({int page = 1}) async {
    try {
      final res = await _api.getRequest('mental-health/videos', query: {
        'page': '$page',
        'per_page': '12',
      });
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map(MentalHealthVideo.fromJson)
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('MentalHealthService.getVideos error: $e');
      return [];
    }
  }
}
