// lib/profile/services/public_profile_service.dart
import 'package:get/get.dart';

import '../../services/base_service.dart';
import '../models/public_profile_model.dart';

class PublicProfileService {
  BaseService get _api => Get.find<BaseService>();

  Future<PublicProfile?> getUser(int userId) async {
    try {
      final res = await _api.getRequest('users/$userId');
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is Map<String, dynamic>) return PublicProfile.fromJson(data);
      }
      return null;
    } catch (e) {
      print('PublicProfileService.getUser error: $e');
      return null;
    }
  }

  /// This user's public comments — `GET users/{id}/comments`. Unconfirmed
  /// against api.py (no documented route, unlike the signed-in-user
  /// equivalent `auth/me/comments`), wired defensively the same way
  /// `ProjectsService.getProjects`'s `submittedBy` is: degrades to an empty
  /// list rather than a crash if the backend doesn't have it yet.
  Future<List<PublicComment>> getUserComments(
    int userId, {
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final res = await _api.getRequest(
        'users/$userId/comments',
        query: {'page': '$page', 'per_page': '$perPage'},
      );
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map(PublicComment.fromJson)
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('PublicProfileService.getUserComments error: $e');
      return [];
    }
  }
}
