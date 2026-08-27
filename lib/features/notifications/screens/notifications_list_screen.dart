import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_exception.dart';
import '../../../models/app_notification.dart';
import '../../../models/app_settings.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/notification_providers.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/empty_state.dart';

class NotificationsListScreen extends ConsumerWidget {
  const NotificationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(context, ref),
            child: const Text('Mark all read'),
          ),
          IconButton(
            tooltip: 'Clear history',
            onPressed: () => _clear(context, ref),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const AppLoading(message: 'Loading notifications...'),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_outlined,
              title: 'No notifications yet',
              message: 'Reminders and daily briefings will show up here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screen),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = notifications[index];
              return _NotificationTile(notification: item);
            },
          );
        },
      ),
    );
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    final businessId =
        ref.read(userProfileProvider).valueOrNull?.businessId ?? '';
    if (businessId.isEmpty) return;
    try {
      await ref.read(notificationServiceProvider).markAllRead(businessId);
    } on AppException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear notification history?'),
        content: const Text('This removes notification history from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final businessId =
        ref.read(userProfileProvider).valueOrNull?.businessId ?? '';
    if (businessId.isEmpty) return;
    try {
      await ref.read(notificationServiceProvider).clearHistory(businessId);
    } on AppException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: notification.read
          ? null
          : AppColors.information.withValues(alpha: 0.06),
      child: ListTile(
        leading: Icon(
          _iconFor(notification.type),
          color: notification.read
              ? AppColors.textSecondary
              : AppColors.primary,
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.read ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${notification.message}\n${DateFormat.yMMMd().add_jm().format(notification.createdAt)}',
        ),
        isThreeLine: true,
        onTap: () async {
          if (!notification.read) {
            await ref
                .read(notificationServiceProvider)
                .markRead(notification.notificationId);
          }
          if (!context.mounted) return;
          final route = notification.route.trim();
          if (route.isNotEmpty) {
            context.push(route);
          }
        },
      ),
    );
  }

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.job:
        return Icons.handyman_outlined;
      case NotificationType.invoice:
        return Icons.receipt_long_outlined;
      case NotificationType.payment:
        return Icons.payments_outlined;
      case NotificationType.briefing:
        return Icons.wb_sunny_outlined;
      case NotificationType.sync:
        return Icons.sync;
      case NotificationType.reminder:
        return Icons.alarm_outlined;
      case NotificationType.insight:
        return Icons.insights_outlined;
      case NotificationType.system:
        return Icons.notifications_outlined;
    }
  }
}
