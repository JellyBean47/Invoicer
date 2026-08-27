import 'package:cloud_firestore/cloud_firestore.dart';

/// Per-business settings document (`settings/{businessId}`).
class AppSettings {
  const AppSettings({
    required this.businessId,
    required this.theme,
    required this.currency,
    required this.defaultTaxPercent,
    required this.invoicePrefix,
    required this.invoiceCounter,
    required this.paymentTermsDays,
    required this.notificationsEnabled,
    required this.jobNotifications,
    required this.invoiceNotifications,
    required this.paymentNotifications,
    required this.reminderNotifications,
    required this.businessInsights,
    required this.dailyBriefingEnabled,
    required this.detailedNotificationPreviews,
    required this.quietHoursStartMinute,
    required this.quietHoursEndMinute,
    required this.offlineEnabled,
    required this.autoBackup,
    required this.language,
    required this.updatedAt,
  });

  final String businessId;
  final String theme;
  final String currency;
  final int defaultTaxPercent;
  final String invoicePrefix;
  final int invoiceCounter;
  final int paymentTermsDays;
  final bool notificationsEnabled;
  final bool jobNotifications;
  final bool invoiceNotifications;
  final bool paymentNotifications;
  final bool reminderNotifications;
  final bool businessInsights;
  final bool dailyBriefingEnabled;
  final bool detailedNotificationPreviews;
  final int quietHoursStartMinute;
  final int quietHoursEndMinute;
  final bool offlineEnabled;
  final bool autoBackup;
  final String language;
  final DateTime updatedAt;

  static const int defaultQuietStart = 21 * 60; // 21:00
  static const int defaultQuietEnd = 7 * 60; // 07:00
  static const int defaultBriefingMinute = 7 * 60; // 07:00

  factory AppSettings.defaults(String businessId) {
    return AppSettings(
      businessId: businessId,
      theme: 'light',
      currency: 'ZAR',
      defaultTaxPercent: 15,
      invoicePrefix: 'INV',
      invoiceCounter: 0,
      paymentTermsDays: 14,
      notificationsEnabled: true,
      jobNotifications: true,
      invoiceNotifications: true,
      paymentNotifications: true,
      reminderNotifications: true,
      businessInsights: true,
      dailyBriefingEnabled: true,
      detailedNotificationPreviews: false,
      quietHoursStartMinute: defaultQuietStart,
      quietHoursEndMinute: defaultQuietEnd,
      offlineEnabled: true,
      autoBackup: true,
      language: 'en',
      updatedAt: DateTime.now(),
    );
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      businessId: map['businessId'] as String? ?? '',
      theme: map['theme'] as String? ?? 'light',
      currency: map['currency'] as String? ?? 'ZAR',
      defaultTaxPercent: map['defaultTaxPercent'] as int? ?? 15,
      invoicePrefix: map['invoicePrefix'] as String? ?? 'INV',
      invoiceCounter: map['invoiceCounter'] as int? ?? 0,
      paymentTermsDays: map['paymentTermsDays'] as int? ?? 14,
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      jobNotifications: map['jobNotifications'] as bool? ?? true,
      invoiceNotifications: map['invoiceNotifications'] as bool? ?? true,
      paymentNotifications: map['paymentNotifications'] as bool? ?? true,
      reminderNotifications: map['reminderNotifications'] as bool? ?? true,
      businessInsights: map['businessInsights'] as bool? ?? true,
      dailyBriefingEnabled: map['dailyBriefingEnabled'] as bool? ?? true,
      detailedNotificationPreviews:
          map['detailedNotificationPreviews'] as bool? ?? false,
      quietHoursStartMinute:
          map['quietHoursStartMinute'] as int? ?? defaultQuietStart,
      quietHoursEndMinute:
          map['quietHoursEndMinute'] as int? ?? defaultQuietEnd,
      offlineEnabled: map['offlineEnabled'] as bool? ?? true,
      autoBackup: map['autoBackup'] as bool? ?? true,
      language: map['language'] as String? ?? 'en',
      updatedAt: _readDate(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'theme': theme,
      'currency': currency,
      'defaultTaxPercent': defaultTaxPercent,
      'invoicePrefix': invoicePrefix,
      'invoiceCounter': invoiceCounter,
      'paymentTermsDays': paymentTermsDays,
      'notificationsEnabled': notificationsEnabled,
      'jobNotifications': jobNotifications,
      'invoiceNotifications': invoiceNotifications,
      'paymentNotifications': paymentNotifications,
      'reminderNotifications': reminderNotifications,
      'businessInsights': businessInsights,
      'dailyBriefingEnabled': dailyBriefingEnabled,
      'detailedNotificationPreviews': detailedNotificationPreviews,
      'quietHoursStartMinute': quietHoursStartMinute,
      'quietHoursEndMinute': quietHoursEndMinute,
      'offlineEnabled': offlineEnabled,
      'autoBackup': autoBackup,
      'language': language,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  AppSettings copyWith({
    String? theme,
    String? currency,
    int? defaultTaxPercent,
    String? invoicePrefix,
    int? invoiceCounter,
    int? paymentTermsDays,
    bool? notificationsEnabled,
    bool? jobNotifications,
    bool? invoiceNotifications,
    bool? paymentNotifications,
    bool? reminderNotifications,
    bool? businessInsights,
    bool? dailyBriefingEnabled,
    bool? detailedNotificationPreviews,
    int? quietHoursStartMinute,
    int? quietHoursEndMinute,
    bool? offlineEnabled,
    bool? autoBackup,
    String? language,
    DateTime? updatedAt,
  }) {
    return AppSettings(
      businessId: businessId,
      theme: theme ?? this.theme,
      currency: currency ?? this.currency,
      defaultTaxPercent: defaultTaxPercent ?? this.defaultTaxPercent,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      invoiceCounter: invoiceCounter ?? this.invoiceCounter,
      paymentTermsDays: paymentTermsDays ?? this.paymentTermsDays,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      jobNotifications: jobNotifications ?? this.jobNotifications,
      invoiceNotifications: invoiceNotifications ?? this.invoiceNotifications,
      paymentNotifications: paymentNotifications ?? this.paymentNotifications,
      reminderNotifications: reminderNotifications ?? this.reminderNotifications,
      businessInsights: businessInsights ?? this.businessInsights,
      dailyBriefingEnabled: dailyBriefingEnabled ?? this.dailyBriefingEnabled,
      detailedNotificationPreviews: detailedNotificationPreviews ??
          this.detailedNotificationPreviews,
      quietHoursStartMinute:
          quietHoursStartMinute ?? this.quietHoursStartMinute,
      quietHoursEndMinute: quietHoursEndMinute ?? this.quietHoursEndMinute,
      offlineEnabled: offlineEnabled ?? this.offlineEnabled,
      autoBackup: autoBackup ?? this.autoBackup,
      language: language ?? this.language,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool allowsType(NotificationType type) {
    if (!notificationsEnabled) return false;
    switch (type) {
      case NotificationType.job:
        return jobNotifications;
      case NotificationType.invoice:
        return invoiceNotifications;
      case NotificationType.payment:
        return paymentNotifications;
      case NotificationType.reminder:
        return reminderNotifications;
      case NotificationType.insight:
        return businessInsights;
      case NotificationType.briefing:
        return dailyBriefingEnabled;
      case NotificationType.sync:
      case NotificationType.system:
        return true;
    }
  }

  /// Quiet hours may wrap past midnight (e.g. 21:00–07:00).
  bool isInQuietHours(DateTime now) {
    final minute = now.hour * 60 + now.minute;
    if (quietHoursStartMinute == quietHoursEndMinute) return false;
    if (quietHoursStartMinute < quietHoursEndMinute) {
      return minute >= quietHoursStartMinute && minute < quietHoursEndMinute;
    }
    return minute >= quietHoursStartMinute || minute < quietHoursEndMinute;
  }

  static String formatMinuteOfDay(int minuteOfDay) {
    final hour = (minuteOfDay ~/ 60).clamp(0, 23);
    final minute = (minuteOfDay % 60).clamp(0, 59);
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

enum NotificationType {
  job,
  invoice,
  payment,
  reminder,
  insight,
  briefing,
  sync,
  system;

  static NotificationType fromString(String? value) {
    return NotificationType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => NotificationType.system,
    );
  }

  String get label {
    switch (this) {
      case NotificationType.job:
        return 'Jobs';
      case NotificationType.invoice:
        return 'Invoices';
      case NotificationType.payment:
        return 'Payments';
      case NotificationType.reminder:
        return 'Reminders';
      case NotificationType.insight:
        return 'Insights';
      case NotificationType.briefing:
        return 'Daily briefing';
      case NotificationType.sync:
        return 'Sync';
      case NotificationType.system:
        return 'System';
    }
  }
}
