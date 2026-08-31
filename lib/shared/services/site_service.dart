// lib/shared/services/site_service.dart
//
// Site-wide, admin-configured settings: footer store links (SiteSetting)
// and the social link cluster (SocialLink). Both are now real backend
// endpoints — see api.py's `/site/settings` and `/site/social-links`.
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
}
