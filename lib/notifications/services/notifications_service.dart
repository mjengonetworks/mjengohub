// lib/notifications/services/notifications_service.dart
import 'package:get/get.dart';
import '../../services/mjengo_service.dart';
import '../models/notification_model.dart';

class NotificationsService {
  final MjengoService _api = Get.find<MjengoService>();

  // ── Fetch paginated notifications ─────────────────────────────────────────
  Future<({List<NotificationModel> items, int total, int pages})> fetchNotifications({
    int page = 1,
    int perPage = 20,
  }) async {
    final res = await _api.apiGet(
      'notifications',
      query: {'page': page, 'per_page': perPage},
    );
    if (res.statusCode == 200) {
      final body = res.body as Map<String, dynamic>;
      final data  = (body['data']  as List<dynamic>?) ?? [];
      final pag   = body['pagination'] as Map<String, dynamic>? ?? {};
      return (
        items : data.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList(),
        total : pag['total'] as int? ?? 0,
        pages : pag['pages'] as int? ?? 1,
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
}
