// lib/point/services/gamification_service.dart
//
// Points and referral API calls — `points/summary`, `points/log`,
// `referrals/me` and `referrals/redeem` are all live in api.py (PointsScreen
// and ReferralScreen call these directly). Every method still degrades to a
// safe default (null/empty list) on any failure, matching every other
// service in the app, so callers never need their own try/catch.
import 'package:get/get.dart';

import '../../services/mjengo_service.dart';
import '../models/points_models.dart';

class GamificationService {
  MjengoService get _api => Get.find<MjengoService>();

  Future<PointsSummary?> getPointsSummary() async {
    try {
      final res = await _api.apiGet('points/summary');
      if (res.statusCode == 200 && res.body is Map) {
        final data = (res.body as Map)['data'];
        if (data is Map<String, dynamic>) return PointsSummary.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  Future<List<PointsLogEntry>> getPointsLog() async {
    try {
      final res = await _api.apiGet('points/log');
      if (res.statusCode == 200 && res.body is Map) {
        final data = (res.body as Map)['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map(PointsLogEntry.fromJson)
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<ReferralInfo?> getReferralInfo() async {
    try {
      final res = await _api.apiGet('referrals/me');
      if (res.statusCode == 200 && res.body is Map) {
        final data = (res.body as Map)['data'];
        if (data is Map<String, dynamic>) return ReferralInfo.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  /// Redeem a referral code for the current signed-in user (Google
  /// OAuth / existing accounts that skipped the ?ref= signup flow).
  Future<String?> redeemReferralCode(String code) async {
    try {
      final res = await _api.apiPost('referrals/redeem', {'referral_code': code});
      if (res.statusCode == 200 || res.statusCode == 201) return null; // null = success
      final body = res.body;
      if (body is Map) {
        return (body['error'] ?? body['message'] ?? 'Could not redeem this code').toString();
      }
      return 'Could not redeem this code';
    } catch (e) {
      return 'Network error — please try again.';
    }
  }
}
