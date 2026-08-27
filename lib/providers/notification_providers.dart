import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_notification.dart';
import '../repositories/notification_repository.dart';
import '../services/fcm_service.dart';
import '../services/notification_service.dart';
import 'app_providers.dart';
import 'settings_providers.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    notificationRepository: ref.watch(notificationRepositoryProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
  );
});

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService();
});

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final businessId = profile?.businessId;
  if (businessId == null || businessId.isEmpty) {
    return Stream.value(const []);
  }
  return ref.watch(notificationServiceProvider).watchNotifications(businessId);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).valueOrNull ?? const [];
  return NotificationService.unreadCount(notifications);
});
