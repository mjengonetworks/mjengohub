// lib/notifications/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/app_header.dart';
import '../controllers/notifications_controller.dart';
import '../models/notification_model.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _blue     = Color(0xFF2563EB);
const _blueDark = Color(0xFF1D4ED8);
const _bg       = Color(0xFFF0F4FF);
const _surface  = Colors.white;
const _textPri  = Color(0xFF1A1A2E);
const _textSec  = Color(0xFF888888);
const _divider  = Color(0xFFEEEEF5);

// ── Type colours ─────────────────────────────────────────────────────────────
Color _typeColor(String type) {
  switch (type) {
    case 'success': return const Color(0xFF22C55E);
    case 'warning': return const Color(0xFFF59E0B);
    case 'error':   return const Color(0xFFEF4444);
    default:        return _blue;
  }
}

IconData _typeIcon(String type) {
  switch (type) {
    case 'success': return Icons.check_circle_rounded;
    case 'warning': return Icons.warning_amber_rounded;
    case 'error':   return Icons.error_rounded;
    default:        return Icons.notifications_rounded;
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final NotificationsController _ctrl;
  late final TabController _tabCtrl;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _ctrl    = Get.find<NotificationsController>();
    _tabCtrl = TabController(length: 2, vsync: this);

    // Infinite scroll
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200) {
        _ctrl.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            const AppHeader(),
            _Header(ctrl: _ctrl),
            _TabRow(controller: _tabCtrl),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _NotifList(
                    ctrl      : _ctrl,
                    scrollCtrl: _scrollCtrl,
                    unreadOnly: false,
                  ),
                  _NotifList(
                    ctrl      : _ctrl,
                    scrollCtrl: ScrollController(),
                    unreadOnly: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final NotificationsController ctrl;
  const _Header({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_blue, _blueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 8, 16),
          child: Row(
            children: [
              // Back
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Get.back(),
              ),
              // Title
              Expanded(
                child: Text(
                  'Notifications',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              // Unread count badge
              Obx(() {
                final c = ctrl.unreadCount.value;
                if (c == 0) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$c unread',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                );
              }),
              // Menu
              Obx(() => ctrl.notifications.isEmpty
                  ? const SizedBox.shrink()
                  : PopupMenuButton<_MenuAction>(
                      icon: const Icon(Icons.more_vert_rounded,
                          color: Colors.white),
                      color: _surface,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onSelected: (a) => _onAction(a),
                      itemBuilder: (_) => [
                        _menuItem(
                          _MenuAction.markAll,
                          Icons.done_all_rounded,
                          'Mark all as read',
                        ),
                        _menuItem(
                          _MenuAction.clearAll,
                          Icons.delete_sweep_rounded,
                          'Clear all',
                          isDestructive: true,
                        ),
                      ],
                    )),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<_MenuAction> _menuItem(
    _MenuAction action,
    IconData icon,
    String label, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? const Color(0xFFEF4444) : _textPri;
    return PopupMenuItem(
      value: action,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _onAction(_MenuAction action) {
    switch (action) {
      case _MenuAction.markAll:
        ctrl.markAllRead();
        break;
      case _MenuAction.clearAll:
        _confirmClear();
        break;
    }
  }

  void _confirmClear() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear all notifications?',
          style: GoogleFonts.montserrat(
              fontSize: 15, fontWeight: FontWeight.w700, color: _textPri),
        ),
        content: Text(
          'This will permanently remove all your notifications.',
          style: GoogleFonts.montserrat(fontSize: 13, color: _textSec),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600, color: _textSec)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              ctrl.clearAll();
            },
            child: Text('Clear',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }
}

enum _MenuAction { markAll, clearAll }

// ── Tab row ───────────────────────────────────────────────────────────────────

class _TabRow extends StatelessWidget {
  final TabController controller;
  const _TabRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _surface,
      child: TabBar(
        controller: controller,
        labelColor: _blue,
        unselectedLabelColor: _textSec,
        indicatorColor: _blue,
        indicatorWeight: 2.5,
        labelStyle: GoogleFonts.montserrat(
            fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.montserrat(
            fontSize: 13, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Unread'),
        ],
      ),
    );
  }
}

// ── Notification list ─────────────────────────────────────────────────────────

class _NotifList extends StatelessWidget {
  final NotificationsController ctrl;
  final ScrollController scrollCtrl;
  final bool unreadOnly;

  const _NotifList({
    required this.ctrl,
    required this.scrollCtrl,
    required this.unreadOnly,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: _blue,
          ),
        );
      }

      final items = unreadOnly ? ctrl.unreadOnly : ctrl.notifications.toList();

      if (items.isEmpty) {
        return _EmptyState(unreadOnly: unreadOnly);
      }

      return RefreshIndicator(
        color: _blue,
        onRefresh: ctrl.refresh,
        child: ListView.builder(
          controller: scrollCtrl,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length + (ctrl.hasMore.value ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == items.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _blue),
                  ),
                ),
              );
            }
            return _NotifCard(notif: items[i], ctrl: ctrl);
          },
        ),
      );
    });
  }
}

// ── Notification card ─────────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  final NotificationModel notif;
  final NotificationsController ctrl;

  const _NotifCard({required this.notif, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(notif.type);
    final icon  = _typeIcon(notif.type);

    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 24),
      ),
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        await ctrl.deleteNotification(notif);
        return false; // we delete manually so list updates via Obx
      },
      child: GestureDetector(
        onTap: () => ctrl.markRead(notif),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: notif.isRead ? _surface : color.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: notif.isRead ? _divider : color.withValues(alpha: 0.25),
              width: notif.isRead ? 0.8 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Type icon ────────────────────────────────────────────
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),

                // ── Text ─────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: GoogleFonts.montserrat(
                                fontSize: 13.5,
                                fontWeight: notif.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: _textPri,
                              ),
                            ),
                          ),
                          // Unread dot
                          if (!notif.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 6, top: 2),
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.message,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: _textSec,
                          height: 1.45,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 11, color: _textSec.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Text(
                            _relativeTime(notif.createdAt),
                            style: GoogleFonts.montserrat(
                              fontSize: 10.5,
                              color: _textSec.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds  < 60)  return 'Just now';
    if (diff.inMinutes  < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours    < 24)  return '${diff.inHours}h ago';
    if (diff.inDays     < 7)   return '${diff.inDays}d ago';
    if (diff.inDays     < 30)  return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays     < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool unreadOnly;
  const _EmptyState({required this.unreadOnly});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _blue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                unreadOnly
                    ? Icons.mark_email_read_outlined
                    : Icons.notifications_off_outlined,
                size: 36,
                color: _blue.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              unreadOnly ? 'All caught up!' : 'No notifications yet',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _textPri,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              unreadOnly
                  ? 'You have no unread notifications.'
                  : "You'll be notified about updates,\narticles and announcements here.",
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: _textSec,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
