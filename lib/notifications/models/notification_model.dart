// lib/notifications/models/notification_model.dart

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type; // info | success | warning | error
  final bool isRead;
  final String? actionUrl;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.actionUrl,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id        : json['id'] as int,
      title     : json['title'] as String? ?? '',
      message   : json['message'] as String? ?? '',
      type      : json['type'] as String? ?? 'info',
      isRead    : json['is_read'] as bool? ?? false,
      actionUrl : json['action_url'] as String?,
      createdAt : json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id        : id,
        title     : title,
        message   : message,
        type      : type,
        isRead    : isRead ?? this.isRead,
        actionUrl : actionUrl,
        createdAt : createdAt,
      );
}
