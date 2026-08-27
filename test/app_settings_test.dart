import 'package:business_buddy/models/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettings', () {
    test('quiet hours wrap past midnight', () {
      final settings = AppSettings.defaults('b1').copyWith(
        quietHoursStartMinute: 21 * 60,
        quietHoursEndMinute: 7 * 60,
      );
      expect(settings.isInQuietHours(DateTime(2026, 8, 2, 22)), isTrue);
      expect(settings.isInQuietHours(DateTime(2026, 8, 2, 6)), isTrue);
      expect(settings.isInQuietHours(DateTime(2026, 8, 2, 12)), isFalse);
    });

    test('category preferences gate notification types', () {
      final settings = AppSettings.defaults('b1').copyWith(
        paymentNotifications: false,
        dailyBriefingEnabled: true,
      );
      expect(settings.allowsType(NotificationType.payment), isFalse);
      expect(settings.allowsType(NotificationType.briefing), isTrue);
      expect(settings.allowsType(NotificationType.sync), isTrue);

      final disabled = settings.copyWith(notificationsEnabled: false);
      expect(disabled.allowsType(NotificationType.briefing), isFalse);
      expect(disabled.allowsType(NotificationType.sync), isFalse);
    });

    test('formats minute of day', () {
      expect(AppSettings.formatMinuteOfDay(7 * 60 + 5), '07:05');
      expect(AppSettings.formatMinuteOfDay(21 * 60), '21:00');
    });
  });
}
