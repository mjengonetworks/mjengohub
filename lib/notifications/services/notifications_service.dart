// lib/notifications/services/notifications_service.dart
import 'package:get/get.dart';
import '../../services/mjengo_service.dart';
import '../models/notification_model.dart';
import '../models/notification_preferences.dart';

class NotificationsService {
  final MjengoService _api = Get.find<MjengoService>();

  // ── Fetch paginated notifications ─────────────────────────────────────────
  Future<({List<NotificationModel> items, int total, int pages})>
  fetchNotifications({int page = 1, int perPage = 20}) async {
    final res = await _api.apiGet(
      'notifications',
      query: {'page': page, 'per_page': perPage},
    );
    if (res.statusCode == 200) {
      final body = res.body as Map<String, dynamic>;
      final data = (body['data'] as List<dynamic>?) ?? [];
      final pag = body['pagination'] as Map<String, dynamic>? ?? {};
      return (
        items: data
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: pag['total'] as int? ?? 0,
        pages: pag['pages'] as int? ?? 1,
      );
    }
    return (items: <NotificationModel>[], total: 0, pages: 1);
  }

  // ── Unread count only ─────────────────────────────────────────────────────
  Future<int> fetchUnreadCount() async {
    final res = await _api.apiGet('notifications/unread-count');
    if (res.statusCode == 200) {
      final body = res.body as Map<String, dynamic>;
      return (body['data'] as Map<String, dynamic>?)?['count'] as int? ?? 0;
    }
    return 0;
  }

  // ── Mark single as read ───────────────────────────────────────────────────
  Future<bool> markRead(int id) async {
    final res = await _api.apiPut('notifications/$id/read', {});
    return res.statusCode == 200;
  }

  // ── Mark all as read ──────────────────────────────────────────────────────
  Future<bool> markAllRead() async {
    final res = await _api.apiPut('notifications/read-all', {});
    return res.statusCode == 200;
  }

  // ── Delete single notification ────────────────────────────────────────────
  Future<bool> deleteNotification(int id) async {
    final res = await _api.apiDelete('notifications/$id');
    return res.statusCode == 200;
  }

  // ── Clear all notifications ───────────────────────────────────────────────
  Future<bool> clearAll() async {
    final res = await _api.apiDelete('notifications');
    return res.statusCode == 200;
  }

  // ── Notification preferences ──────────────────────────────────────────────
  Future<NotificationPreferences> getPreferences() async {
    try {
      final res = await _api.apiGet('user/notification-preferences');
      if (res.statusCode == 200 && res.body is Map<String, dynamic>) {
        final data = (res.body as Map<String, dynamic>)['data'];
        if (data is Map<String, dynamic>) {
          return NotificationPreferences.fromJson(data);
        }
      }
    } catch (e) {
      print('NotificationsService.getPreferences error: $e');
    }
    return const NotificationPreferences();
  }

  Future<bool> updatePreferences(NotificationPreferences prefs) async {
    try {
      final res = await _api.apiPost(
        'user/notification-preferences',
        prefs.toJson(),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('NotificationsService.updatePreferences error: $e');
      return false;
    }
  }

  // ── FCM device token registration ─────────────────────────────────────────
  // `POST notifications/subscribe` is unconfirmed against api.py, same status
  // as the preferences endpoint above — degrades silently on failure like
  // every other best-effort call in this app.
  Future<bool> registerDeviceToken(String token, {String? platform}) async {
    try {
      final res = await _api.apiPost('notifications/subscribe', {
        'token': token,
        if (platform != null) 'platform': platform,
      });
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('NotificationsService.registerDeviceToken error: $e');
      return false;
    }
  }
}
