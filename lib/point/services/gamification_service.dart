// lib/point/services/gamification_service.dart
//
// Points, referral, and copyright-claim API calls. These follow the same
// REST conventions as the rest of api.py (`/api/v1/...`, `{success,data}`
// envelope) and are confirmed live on the backend (api.py points_summary /
// points_log / referrals / copyright-claim routes). Every call still
// degrades gracefully on any failure (network, unexpected shape, future
// backend changes) rather than crashing the UI.
import 'dart:typed_data';

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

  Future<bool> submitCopyrightClaim({
    required String contentType, // project | incident | event
    required int contentId,
    required String name,
    required String email,
    required String description,
    Uint8List? proofBytes,
    String? proofFilename,
  }) async {
    try {
      if (proofBytes != null && proofFilename != null) {
        final result = await _api.uploadMultipart(
          'copyright-claim',
          proofBytes,
          proofFilename,
          fieldName: 'proof',
          fields: {
            'content_type': contentType,
            'content_id': '$contentId',
            'name': name,
            'email': email,
            'description': description,
          },
        );
        final code = result['_statusCode'] as int? ?? 500;
        return code >= 200 && code < 300;
      }
      final res = await _api.apiPost('copyright-claim', {
        'content_type': contentType,
        'content_id': contentId,
        'name': name,
        'email': email,
        'description': description,
      });
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
