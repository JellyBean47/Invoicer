import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/analytics_service.dart';
import '../services/crash_reporting_service.dart';

/// Set true from [main] once Firebase is initialized.
final telemetryEnabledProvider = Provider<bool>((ref) => false);

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(enabled: ref.watch(telemetryEnabledProvider));
});

final crashReportingServiceProvider = Provider<CrashReportingService>((ref) {
  return CrashReportingService(enabled: ref.watch(telemetryEnabledProvider));
});
