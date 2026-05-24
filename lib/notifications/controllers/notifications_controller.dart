// lib/notifications/controllers/notifications_controller.dart
import 'package:get/get.dart';
import '../../auth/controllers/mjengo_auth_controller.dart';
import '../models/notification_model.dart';
import '../services/notifications_service.dart';

class NotificationsController extends GetxController {
  final _svc = NotificationsService();

  // ── State ─────────────────────────────────────────────────────────────────
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxInt  unreadCount   = 0.obs;
  final RxBool isLoading     = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore       = false.obs;
  final RxString errorMsg    = ''.obs;

  int _page = 1;
  static const _perPage = 20;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    // Only load when the user is authenticated
    final auth = Get.find<MjengoAuthController>();
    if (auth.isAuthenticated) {
      _loadInitial();
    }
    // Re-poll when auth state flips
    ever(auth.isAuthenticated.obs, (bool v) {
      if (v) _loadInitial();
    });
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> _loadInitial() async {
    _page = 1;
    isLoading.value = true;
    errorMsg.value  = '';
    try {
      final result = await _svc.fetchNotifications(page: 1, perPage: _perPage);
      notifications.assignAll(result.items);
      hasMore.value   = _page < result.pages;
      unreadCount.value = notifications.where((n) => !n.isRead).length;
    } catch (e) {
      errorMsg.value = 'Could not load notifications.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refresh() => _loadInitial();

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    _page++;
    isLoadingMore.value = true;
    try {
      final result = await _svc.fetchNotifications(page: _page, perPage: _perPage);
      notifications.addAll(result.items);
      hasMore.value = _page < result.pages;
    } catch (_) {
      _page--; // roll back on failure
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ── Unread count (called from bell badge) ─────────────────────────────────

  Future<void> refreshUnreadCount() async {
    final auth = Get.find<MjengoAuthController>();
    if (!auth.isAuthenticated) return;
    try {
      unreadCount.value = await _svc.fetchUnreadCount();
    } catch (_) {}
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> markRead(NotificationModel n) async {
    if (n.isRead) return;
    final ok = await _svc.markRead(n.id);
    if (ok) {
      final idx = notifications.indexWhere((x) => x.id == n.id);
      if (idx != -1) {
        notifications[idx] = n.copyWith(isRead: true);
        unreadCount.value  = (unreadCount.value - 1).clamp(0, 9999);
      }
    }
  }

  Future<void> markAllRead() async {
    final ok = await _svc.markAllRead();
    if (ok) {
      notifications.assignAll(notifications.map((n) => n.copyWith(isRead: true)));
      unreadCount.value = 0;
    }
  }

  Future<void> deleteNotification(NotificationModel n) async {
    final ok = await _svc.deleteNotification(n.id);
    if (ok) {
      notifications.removeWhere((x) => x.id == n.id);
      if (!n.isRead) {
        unreadCount.value = (unreadCount.value - 1).clamp(0, 9999);
      }
    }
  }

  Future<void> clearAll() async {
    final ok = await _svc.clearAll();
    if (ok) {
      notifications.clear();
      unreadCount.value = 0;
    }
  }

  // ── Computed ──────────────────────────────────────────────────────────────

  List<NotificationModel> get unreadOnly =>
      notifications.where((n) => !n.isRead).toList();
}
