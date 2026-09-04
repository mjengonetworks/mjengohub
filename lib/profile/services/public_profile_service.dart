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
}
