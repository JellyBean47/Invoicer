import '../core/utils/app_exception.dart';
import '../core/utils/money.dart';
import '../models/app_notification.dart';
import '../models/app_settings.dart';
import '../models/invoice.dart';
import '../models/job.dart';
import '../models/payment.dart';
import '../repositories/notification_repository.dart';
import '../repositories/settings_repository.dart';
import 'daily_briefing_service.dart';

class NotificationService {
  NotificationService({
    required NotificationRepository notificationRepository,
    required SettingsRepository settingsRepository,
  })  : _notificationRepository = notificationRepository,
        _settingsRepository = settingsRepository;

  final NotificationRepository _notificationRepository;
  final SettingsRepository _settingsRepository;

  Stream<List<AppNotification>> watchNotifications(String businessId) {
    return _notificationRepository.watchByBusiness(businessId);
  }

  Future<void> markRead(String notificationId) {
    return _notificationRepository.markRead(notificationId);
  }

  Future<void> markAllRead(String businessId) {
    return _notificationRepository.markAllRead(businessId);
  }

  Future<void> clearHistory(String businessId) {
    return _notificationRepository.clearHistory(businessId);
  }

  Future<AppNotification?> createIfAllowed({
    required String businessId,
    required String title,
    required String message,
    required NotificationType type,
    String route = '',
    String entityType = '',
    String entityId = '',
    DateTime? now,
    bool bypassQuietHours = false,
  }) async {
    final settings =
        await _settingsRepository.getByBusinessId(businessId) ??
            AppSettings.defaults(businessId);
    if (!settings.allowsType(type)) return null;

    final moment = now ?? DateTime.now();
    if (!bypassQuietHours &&
        type != NotificationType.sync &&
        type != NotificationType.system &&
        settings.isInQuietHours(moment)) {
      return null;
    }

    return _notificationRepository.create(
      AppNotification(
        notificationId: '',
        businessId: businessId,
        title: title,
        message: message,
        type: type,
        read: false,
        createdAt: moment,
        route: route,
        entityType: entityType,
        entityId: entityId,
      ),
    );
  }

  Future<AppNotification?> notifyPaymentReceived({
    required Invoice invoice,
    required Payment payment,
    required AppSettings? settings,
  }) {
    final detailed = settings?.detailedNotificationPreviews ?? false;
    final fullyPaid = invoice.balanceRemainingCents <= 0 ||
        invoice.status == InvoiceStatus.paid;
    final title = fullyPaid ? 'Invoice fully paid' : 'Payment received';
    final message = detailed
        ? '${Money.formatZar(payment.amountCents)} on ${invoice.invoiceNumber}. '
            'Remaining ${Money.formatZar(invoice.balanceRemainingCents)}.'
        : 'Payment received for ${invoice.invoiceNumber}.';

    return createIfAllowed(
      businessId: invoice.businessId,
      title: title,
      message: message,
      type: NotificationType.payment,
      route: '/invoices/${invoice.invoiceId}',
      entityType: 'invoice',
      entityId: invoice.invoiceId,
      bypassQuietHours: true,
    );
  }

  Future<AppNotification?> notifyInvoiceFinalized(Invoice invoice) {
    return createIfAllowed(
      businessId: invoice.businessId,
      title: 'Invoice finalized',
      message: '${invoice.invoiceNumber} is ready to share and collect.',
      type: NotificationType.invoice,
      route: '/invoices/${invoice.invoiceId}',
      entityType: 'invoice',
      entityId: invoice.invoiceId,
    );
  }

  Future<AppNotification?> notifyInvoiceOverdue(Invoice invoice) {
    return createIfAllowed(
      businessId: invoice.businessId,
      title: 'Invoice overdue',
      message: '${invoice.invoiceNumber} is now overdue.',
      type: NotificationType.invoice,
      route: '/invoices/${invoice.invoiceId}',
      entityType: 'invoice',
      entityId: invoice.invoiceId,
    );
  }

  Future<AppNotification?> notifySync({
    required String businessId,
    required bool success,
    int pendingCount = 0,
  }) {
    if (success) {
      return createIfAllowed(
        businessId: businessId,
        title: 'Sync complete',
        message: 'All changes have been successfully synchronized.',
        type: NotificationType.sync,
        bypassQuietHours: true,
      );
    }
    return createIfAllowed(
      businessId: businessId,
      title: 'Sync issue',
      message: pendingCount > 0
          ? 'Some changes could not be synchronized ($pendingCount pending).'
          : 'Some changes could not be synchronized.',
      type: NotificationType.sync,
      route: '/settings',
      bypassQuietHours: true,
    );
  }

  /// Builds and stores today's daily briefing once per calendar day.
  Future<AppNotification?> createDailyBriefing({
    required String businessId,
    required String ownerName,
    required List<Job> jobs,
    required List<Invoice> invoices,
    required List<Payment> payments,
    required Set<String> existingBriefingKeys,
    DateTime? now,
  }) async {
    final moment = now ?? DateTime.now();
    final dayKey =
        '${moment.year}-${moment.month.toString().padLeft(2, '0')}-${moment.day.toString().padLeft(2, '0')}';
    if (existingBriefingKeys.contains(dayKey)) return null;

    final settings =
        await _settingsRepository.getByBusinessId(businessId) ??
            AppSettings.defaults(businessId);
    if (!settings.allowsType(NotificationType.briefing)) return null;

    final briefing = DailyBriefingService.build(
      jobs: jobs,
      invoices: invoices,
      payments: payments,
      now: moment,
    );

    return _notificationRepository.create(
      AppNotification(
        notificationId: '',
        businessId: businessId,
        title: briefing.morningTitle(ownerName),
        message: briefing.morningBody(),
        type: NotificationType.briefing,
        read: false,
        createdAt: moment,
        route: '/dashboard',
        entityType: 'briefing',
        entityId: dayKey,
      ),
    );
  }

  static int unreadCount(List<AppNotification> notifications) {
    return notifications.where((item) => !item.read).length;
  }

  static void validateClear(String businessId) {
    if (businessId.isEmpty) {
      throw const AppException('Business is required.');
    }
  }
}
