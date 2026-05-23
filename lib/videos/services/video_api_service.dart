// lib/videos/services/video_api_service.dart
import 'package:get/get.dart';
import '../../services/base_service.dart';
import '../models/video_model.dart';

class VideoApiService {
  BaseService get _api => Get.find<BaseService>();

  /// Fetch paginated videos. Pass [categoryId] or [playlistId] to filter.
  Future<List<Video>> getVideos({
    int page = 1,
    int perPage = 20,
    int? categoryId,
    String? playlistId,
    bool featuredOnly = false,
    String? q,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': '$page',
        'per_page': '$perPage',
      };
      if (categoryId != null) query['category_id'] = '$categoryId';
      if (playlistId != null && playlistId.isNotEmpty) {
        query['playlist_id'] = playlistId;
      }
      if (featuredOnly) query['featured'] = 'true';
      if (q != null && q.isNotEmpty) query['q'] = q;

      final res = await _api.getRequest('youtube/videos', query: query);
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map(Video.fromJson)
              .toList();
        }
      }
      return [];
    } catch (e) {
      _log('getVideos', e);
      return [];
    }
  }

  /// Fetch playlists (each contains up to 10 preview videos).
  Future<List<VideoPlaylist>> getPlaylists() async {
    try {
      final res = await _api.getRequest('youtube/playlists');
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map(VideoPlaylist.fromJson)
              .toList();
        }
      }
      return [];
    } catch (e) {
      _log('getPlaylists', e);
      return [];
    }
  }

  /// Fetch categories that have at least one video.
  Future<List<VideoCategory>> getCategories() async {
    try {
      final res = await _api.getRequest('youtube/categories');
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map(VideoCategory.fromJson)
              .toList();
        }
      }
      return [];
    } catch (e) {
      _log('getCategories', e);
      return [];
    }
  }

  void _log(String method, Object e) =>
      print('VideoApiService.$method error: $e');
}
