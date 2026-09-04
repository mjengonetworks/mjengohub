// lib/shared/services/webview_checkout_service.dart
//
// Mints the short-lived SSO handoff token (`POST /auth/webview-token`) that
// lets the app open the existing session-based web checkout/verification
// pages inside an in-app WebView, reusing all of the Paystack redirect+
// webhook logic those pages already have rather than re-implementing
// payment handling natively.
import 'package:get/get.dart';

import '../../services/base_service.dart';

class WebviewCheckoutService {
  BaseService get _api => Get.find<BaseService>();

  static const _baseUrl = 'https://mjengohub.co.ke';

  /// Returns the full `/webview-login/<token>?...` URL to open, or null on
  /// failure (caller should show an error rather than open a broken link).
  Future<String?> getHandoffUrl(String nextPath) async {
    try {
      final res = await _api.postRequest('auth/webview-token', {'next_path': nextPath});
      if (res.statusCode == 200 && res.body != null) {
        final token = res.body['data']?['token'] as String?;
        if (token != null) return '$_baseUrl/webview-login/$token';
      }
      return null;
    } catch (e) {
      print('WebviewCheckoutService.getHandoffUrl error: $e');
      return null;
    }
  }
}
