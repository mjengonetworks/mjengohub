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

  /// Submits a community video to Mshikamano. The backend requires `title`,
  /// `uploaderName`, and at least one of [youtubeId] / [filePath].
  ///
  /// Videos land with `is_approved=False`, so a freshly submitted video will
  /// not appear in [getVideos] until an admin approves it — tell the user it's
  /// pending review rather than optimistically inserting it.
  Future<Map<String, dynamic>> submitVideo({
    required String title,
    required String uploaderName,
    String? description,
    String? youtubeId,
    String? filePath,
    String? thumbnail,
  }) async {
    if ((youtubeId == null || youtubeId.isEmpty) && (filePath == null || filePath.isEmpty)) {
      return {'success': false, 'message': 'Provide a YouTube link or upload a file.'};
    }
    try {
      final res = await _api.postRequest('mental-health/videos', {
        'title': title,
        'uploader_name': uploaderName,
        if (description != null && description.isNotEmpty) 'description': description,
        if (youtubeId != null && youtubeId.isNotEmpty) 'youtube_id': youtubeId,
        if (filePath != null && filePath.isNotEmpty) 'file_path': filePath,
        if (thumbnail != null && thumbnail.isNotEmpty) 'thumbnail': thumbnail,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = res.body?['data'];
        return {
          'success': true,
          'message': (data is Map ? data['message'] as String? : null) ??
              'Video submitted for review and approval',
        };
      }
      final body = res.body;
      final msg = body is Map ? (body['message'] ?? body['error']) : null;
      return {
        'success': false,
        'message': msg is String && msg.isNotEmpty ? msg : 'Could not submit video.',
      };
    } catch (e) {
      print('MentalHealthService.submitVideo error: $e');
      return {'success': false, 'message': 'Could not submit video. Check your connection.'};
    }
  }
}
