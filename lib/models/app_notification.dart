import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_settings.dart';

class AppNotification {
  const AppNotification({
    required this.notificationId,
    required this.businessId,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    required this.createdAt,
    this.route = '',
    this.entityType = '',
    this.entityId = '',
  });

  final String notificationId;
  final String businessId;
  final String title;
  final String message;
  final NotificationType type;
  final bool read;
  final DateTime createdAt;
  final String route;
  final String entityType;
  final String entityId;

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      notificationId: map['notificationId'] as String? ?? '',
      businessId: map['businessId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      type: NotificationType.fromString(map['type'] as String?),
      read: map['read'] as bool? ?? false,
      createdAt: _readDate(map['createdAt']) ?? DateTime.now(),
      route: map['route'] as String? ?? '',
      entityType: map['entityType'] as String? ?? '',
      entityId: map['entityId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'businessId': businessId,
      'title': title,
      'message': message,
      'type': type.name,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
      'route': route,
      'entityType': entityType,
      'entityId': entityId,
    };
  }

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      notificationId: notificationId,
      businessId: businessId,
      title: title,
      message: message,
      type: type,
      read: read ?? this.read,
      createdAt: createdAt,
      route: route,
      entityType: entityType,
      entityId: entityId,
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
