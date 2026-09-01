// lib/reports/services/reports_service.dart
//
// Wraps api.py's `/reports` endpoints (infrastructure reports): list with
// filters + pagination, detail, submit, and up/down vote.
//
// Voting is IP-scoped on the backend (no auth required) and toggles: sending
// the same vote_type twice removes the vote. The response always carries the
// authoritative counts, so callers should replace their local counts with
// what comes back rather than incrementing.
import 'package:get/get.dart';

import '../../services/base_service.dart';
import '../models/report_model.dart';

class ReportsService {
  BaseService get _api => Get.find<BaseService>();

  /// Paginated report list. [category], [severity] and [status] map straight
  /// onto the backend's query filters; pass null to leave a filter off.
  Future<({List<InfrastructureReport> items, int total, int pages})> getReports({
    int page = 1,
    int perPage = 12,
    String? category,
    String? severity,
    String? status,
  }) async {
    try {
      final res = await _api.getRequest('reports', query: {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (category != null && category.isNotEmpty) 'category': category,
        if (severity != null && severity.isNotEmpty) 'severity': severity,
        if (status != null && status.isNotEmpty) 'status': status,
      });
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        final pag = res.body['pagination'];
        if (data is List) {
          return (
            items: data
                .whereType<Map<String, dynamic>>()
                .map(InfrastructureReport.fromJson)
                .toList(),
            total: (pag is Map ? (pag['total'] as num?)?.toInt() : null) ?? 0,
            pages: (pag is Map ? (pag['pages'] as num?)?.toInt() : null) ?? 1,
          );
        }
      }
    } catch (e) {
      print('❌ getReports failed: $e');
    }
    return (items: <InfrastructureReport>[], total: 0, pages: 1);
  }

  /// Single report including `description` / `reporter_name`. Also increments
  /// the server-side view count.
  Future<InfrastructureReport?> getReport(int id) async {
    try {
      final res = await _api.getRequest('reports/$id');
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is Map<String, dynamic>) {
          return InfrastructureReport.fromJson(data);
        }
      }
    } catch (e) {
      print('❌ getReport($id) failed: $e');
    }
    return null;
  }

  /// Submits a new infrastructure report. Anonymous submission is allowed;
  /// a JWT is attached automatically when the user is signed in, which links
  /// the report to their account server-side.
  ///
  /// [category] must be one of [kReportCategories] and [severity] one of
  /// [kReportSeverities], otherwise the backend returns a 400.
  Future<Map<String, dynamic>> submitReport({
    required String title,
    required String description,
    required String location,
    required String category,
    required String severity,
    String? reporterName,
    String? reporterEmail,
    String? reporterPhone,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final res = await _api.postRequest('reports', {
        'title': title,
        'description': description,
        'location': location,
        'category': category,
        'severity': severity,
        if (reporterName != null && reporterName.isNotEmpty) 'reporter_name': reporterName,
        if (reporterEmail != null && reporterEmail.isNotEmpty) 'reporter_email': reporterEmail,
        if (reporterPhone != null && reporterPhone.isNotEmpty) 'reporter_phone': reporterPhone,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = res.body?['data'];
        return {
          'success': true,
          'id': data is Map ? data['id'] : null,
          'message': (data is Map ? data['message'] as String? : null) ??
              'Report submitted successfully',
        };
      }
      return {'success': false, 'message': _errorMessage(res.body)};
    } catch (e) {
      print('❌ submitReport failed: $e');
      return {'success': false, 'message': 'Could not submit report. Check your connection.'};
    }
  }

  /// Up/down votes a report. Returns the authoritative counts from the server,
  /// or null if the vote didn't go through.
  Future<({int upvotes, int downvotes})?> voteReport(int id, {required bool up}) async {
    try {
      final res = await _api.postRequest('reports/$id/vote', {
        'vote_type': up ? 'up' : 'down',
      });
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is Map) {
          return (
            upvotes: (data['upvotes'] as num?)?.toInt() ?? 0,
            downvotes: (data['downvotes'] as num?)?.toInt() ?? 0,
          );
        }
      }
    } catch (e) {
      print('❌ voteReport($id) failed: $e');
    }
    return null;
  }

  String _errorMessage(dynamic body) {
    if (body is Map) {
      final msg = body['message'] ?? body['error'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return 'Could not submit report. Please try again.';
  }
}
