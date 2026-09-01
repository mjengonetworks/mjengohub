// lib/shared/services/site_service.dart
//
// Site-wide, admin-configured content plus the small "write" endpoints that
// don't belong to any one feature. All of these are real backend routes in
// api.py:
//   GET  site/settings       footer store links (SiteSetting)
//   GET  site/social-links   the social link cluster (SocialLink)
//   GET  site/figures        headline stat counters (SiteFigures)
//   GET  site/alerts         active site-wide banners (SiteAlert)
//   POST newsletter/subscribe
//   POST advertise           advertising enquiry (AdvertisingInquiry)
import 'package:get/get.dart';

import '../../services/base_service.dart';

class SocialLinkInfo {
  final String platform;
  final String? label;
  final String url;
  const SocialLinkInfo({required this.platform, this.label, required this.url});

  factory SocialLinkInfo.fromJson(Map<String, dynamic> j) => SocialLinkInfo(
        platform: (j['platform'] as String?) ?? 'other',
        label: j['label'] as String?,
        url: (j['url'] as String?) ?? '',
      );
}

class SiteSettings {
  final String? playStoreUrl;
  final String? appStoreUrl;
  const SiteSettings({this.playStoreUrl, this.appStoreUrl});

  factory SiteSettings.fromJson(Map<String, dynamic> j) => SiteSettings(
        playStoreUrl: j['footer_playstore_url'] as String?,
        appStoreUrl: j['footer_appstore_url'] as String?,
      );
}

/// A headline counter shown on the website ("1,200+ projects tracked").
/// [page] is the admin's `page_location`, used to decide which screen a figure
/// belongs to; [value] is a pre-formatted string, not necessarily numeric.
class SiteFigure {
  final String key;
  final String? name;
  final String? value;
  final String? suffix;
  final String? page;

  const SiteFigure({required this.key, this.name, this.value, this.suffix, this.page});

  factory SiteFigure.fromJson(Map<String, dynamic> j) => SiteFigure(
        key: (j['key'] as String?) ?? '',
        name: j['name'] as String?,
        value: j['value']?.toString(),
        suffix: j['suffix'] as String?,
        page: j['page'] as String?,
      );

  /// Display form, e.g. value "1200" + suffix "+" -> "1200+".
  String get display => '${value ?? ''}${suffix ?? ''}';
}

/// An admin-scheduled site-wide banner. The backend already filters by
/// start/end date and orders by priority, so the first item is the one to show.
class SiteAlert {
  final int id;
  final String? title;
  final String? message;

  /// 'info' | 'success' | 'warning' | 'danger' — the admin's `alert_type`.
  final String type;
  final bool isDismissible;
  final String? actionUrl;
  final String? actionText;

  const SiteAlert({
    required this.id,
    this.title,
    this.message,
    this.type = 'info',
    this.isDismissible = true,
    this.actionUrl,
    this.actionText,
  });

  factory SiteAlert.fromJson(Map<String, dynamic> j) => SiteAlert(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: j['title'] as String?,
        message: j['message'] as String?,
        type: (j['type'] as String?) ?? 'info',
        isDismissible: (j['is_dismissible'] as bool?) ?? true,
        actionUrl: j['action_url'] as String?,
        actionText: j['action_text'] as String?,
      );
}

class SiteService {
  BaseService get _api => Get.find<BaseService>();

  Future<SiteSettings?> getSiteSettings() async {
    try {
      final res = await _api.getRequest('site/settings');
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is Map<String, dynamic>) return SiteSettings.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  Future<List<SocialLinkInfo>> getSocialLinks() async {
    try {
      final res = await _api.getRequest('site/social-links');
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is List) {
          return data.whereType<Map<String, dynamic>>().map(SocialLinkInfo.fromJson).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Headline stat counters. [page] filters client-side on `page_location`
  /// (the endpoint returns every active figure in one call).
  Future<List<SiteFigure>> getSiteFigures({String? page}) async {
    try {
      final res = await _api.getRequest('site/figures');
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is List) {
          final figures =
              data.whereType<Map<String, dynamic>>().map(SiteFigure.fromJson).toList();
          if (page == null || page.isEmpty) return figures;
          return figures.where((f) => f.page == page).toList();
        }
      }
    } catch (e) {
      print('❌ getSiteFigures failed: $e');
    }
    return [];
  }

  /// Currently-active site alerts, highest priority first.
  Future<List<SiteAlert>> getSiteAlerts() async {
    try {
      final res = await _api.getRequest('site/alerts');
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is List) {
          return data.whereType<Map<String, dynamic>>().map(SiteAlert.fromJson).toList();
        }
      }
    } catch (e) {
      print('❌ getSiteAlerts failed: $e');
    }
    return [];
  }

  /// Newsletter signup. A 409 means the address is already subscribed — that
  /// is surfaced as a failure carrying the backend's own message, so the UI
  /// can say "already subscribed" instead of a generic error.
  Future<Map<String, dynamic>> subscribeNewsletter({
    required String email,
    String? name,
  }) async {
    try {
      final res = await _api.postRequest('newsletter/subscribe', {
        'email': email,
        if (name != null && name.isNotEmpty) 'name': name,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = res.body?['data'];
        return {
          'success': true,
          'message':
              (data is Map ? data['message'] as String? : null) ?? 'Subscribed successfully',
        };
      }
      return {'success': false, 'message': _errorMessage(res.body, 'Could not subscribe.')};
    } catch (e) {
      print('❌ subscribeNewsletter failed: $e');
      return {'success': false, 'message': 'Could not subscribe. Check your connection.'};
    }
  }

  /// Advertising enquiry. `companyName`, `contactPerson`, `email` and `phone`
  /// are required by the backend; everything else is optional. On success the
  /// returned map carries a `reference` the user can quote in follow-ups.
  Future<Map<String, dynamic>> submitAdvertisingInquiry({
    required String companyName,
    required String contactPerson,
    required String email,
    required String phone,
    String? industry,
    String? packageInterest,
    String? campaignObjectives,
    String? targetAudience,
    String? budgetRange,
    String? campaignDuration,
    String? additionalInfo,
  }) async {
    try {
      final res = await _api.postRequest('advertise', {
        'company_name': companyName,
        'contact_person': contactPerson,
        'email': email,
        'phone': phone,
        if (industry != null && industry.isNotEmpty) 'industry': industry,
        if (packageInterest != null && packageInterest.isNotEmpty)
          'package_interest': packageInterest,
        if (campaignObjectives != null && campaignObjectives.isNotEmpty)
          'campaign_objectives': campaignObjectives,
        if (targetAudience != null && targetAudience.isNotEmpty)
          'target_audience': targetAudience,
        if (budgetRange != null && budgetRange.isNotEmpty) 'budget_range': budgetRange,
        if (campaignDuration != null && campaignDuration.isNotEmpty)
          'campaign_duration': campaignDuration,
        if (additionalInfo != null && additionalInfo.isNotEmpty)
          'additional_info': additionalInfo,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = res.body?['data'];
        return {
          'success': true,
          'reference': data is Map ? data['reference'] : null,
          'message': (data is Map ? data['message'] as String? : null) ??
              'Advertising inquiry submitted successfully',
        };
      }
      return {
        'success': false,
        'message': _errorMessage(res.body, 'Could not submit your enquiry.'),
      };
    } catch (e) {
      print('❌ submitAdvertisingInquiry failed: $e');
      return {
        'success': false,
        'message': 'Could not submit your enquiry. Check your connection.',
      };
    }
  }

  /// api.py's `error()` puts the human text in `error`; BaseService's
  /// normaliser puts it in `message`. Accept either, fall back to [fallback].
  String _errorMessage(dynamic body, String fallback) {
    if (body is Map) {
      final msg = body['message'] ?? body['error'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return fallback;
  }
}
