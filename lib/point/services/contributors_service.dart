// lib/point/services/contributors_service.dart
import 'package:get/get.dart';

import '../../services/base_service.dart';
import '../models/contributors_model.dart';

class ContributorsService {
  BaseService get _api => Get.find<BaseService>();

  Future<CommunityLeaderboards> getContributors({
    LeaderboardWindow window = LeaderboardWindow.past7Days,
    int limit = 10,
  }) async {
    try {
      final res = await _api.getRequest('contributors', query: {
        'window': window.apiValue,
        'limit': '$limit',
      });
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is Map<String, dynamic>) return CommunityLeaderboards.fromJson(data);
      }
      return CommunityLeaderboards.empty;
    } catch (e) {
      print('ContributorsService.getContributors error: $e');
      return CommunityLeaderboards.empty;
    }
  }
}
