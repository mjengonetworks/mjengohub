// lib/service_catalog/services/service_catalog_service.dart
//
// Wraps api.py's `/services` endpoints (GET list, GET detail, POST request).
// Follows the house pattern: every method try/catches and returns an empty /
// null / false-ish value so screens only need null/empty checks.
import 'package:get/get.dart';

import '../../services/base_service.dart';
import '../models/service_model.dart';

class ServiceCatalogService {
  BaseService get _api => Get.find<BaseService>();

  /// All active services, ordered by the admin's `sort_order`.
  Future<List<ServiceOffering>> getServices() async {
    try {
      final res = await _api.getRequest('services');
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map(ServiceOffering.fromJson)
              .toList();
        }
      }
    } catch (e) {
      print('❌ getServices failed: $e');
    }
    return [];
  }

  /// Single service with the detail-only fields (benefits/features/process).
  Future<ServiceOffering?> getService(String slug) async {
    try {
      final res = await _api.getRequest('services/$slug');
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is Map<String, dynamic>) return ServiceOffering.fromJson(data);
      }
    } catch (e) {
      print('❌ getService($slug) failed: $e');
    }
    return null;
  }

  /// Submits a service enquiry. `clientName`, `clientEmail`, `clientPhone` and
  /// `projectDescription` are required by the backend; the rest are optional.
  ///
  /// Returns `{success: bool, message: String}` so the form can show the
  /// backend's own validation message instead of a generic failure.
  Future<Map<String, dynamic>> submitRequest({
    required String slug,
    required String clientName,
    required String clientEmail,
    required String clientPhone,
    required String projectDescription,
    String? company,
    String? projectTitle,
    String? location,
    String? budgetRange,
    String? timeline,
  }) async {
    try {
      final res = await _api.postRequest('services/$slug/request', {
        'client_name': clientName,
        'client_email': clientEmail,
        'client_phone': clientPhone,
        'project_description': projectDescription,
        if (company != null && company.isNotEmpty) 'company': company,
        if (projectTitle != null && projectTitle.isNotEmpty) 'project_title': projectTitle,
        if (location != null && location.isNotEmpty) 'location': location,
        if (budgetRange != null && budgetRange.isNotEmpty) 'budget_range': budgetRange,
        if (timeline != null && timeline.isNotEmpty) 'timeline': timeline,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = res.body?['data'];
        return {
          'success': true,
          'message': (data is Map ? data['message'] as String? : null) ??
              'Request submitted successfully',
        };
      }
      return {'success': false, 'message': _errorMessage(res.body)};
    } catch (e) {
      print('❌ submitRequest failed: $e');
      return {'success': false, 'message': 'Could not submit request. Check your connection.'};
    }
  }

  /// api.py's `error()` helper puts the human-readable text in `error`;
  /// BaseService's normaliser puts it in `message`. Accept either.
  String _errorMessage(dynamic body) {
    if (body is Map) {
      final msg = body['message'] ?? body['error'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return 'Could not submit request. Please try again.';
  }
}
