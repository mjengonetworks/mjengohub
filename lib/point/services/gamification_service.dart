// lib/point/services/gamification_service.dart
//
// Points and referral API calls. WARNING: verified against the live backend
// (models.py/api.py) — none of `points/summary`, `points/log`, `referrals/me`,
// or `referrals/redeem` exist there yet (no PointsLog/Referral model, no
// `points`/`referral_code` column on User). Every call 404s today. Kept
// ready for when the backend ships these routes; until then, callers must
// not rely on them and should fall back to local-only state (see
// PointsScreen/ReferralScreen, which are gated rather than wired to these).
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
