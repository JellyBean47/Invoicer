import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Crashlytics wrapper. Safe no-op when Firebase / Crashlytics is unavailable.
class CrashReportingService {
  CrashReportingService({
    FirebaseCrashlytics? crashlytics,
    bool enabled = true,
  })  : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance,
        _enabled = enabled;

  final FirebaseCrashlytics _crashlytics;
  final bool _enabled;

  Future<void> initialize() async {
    if (!_enabled) return;
    try {
      await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        _crashlytics.recordFlutterFatalError(details);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (error, stack) {
      debugPrint('Crashlytics initialize skipped: $error\n$stack');
    }
  }

  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) async {
    if (!_enabled) return;
    try {
      await _crashlytics.recordError(
        error,
        stack,
        fatal: fatal,
        reason: reason,
      );
    } catch (_) {
      // Swallow — reporting must never break the app.
    }
  }

  Future<void> log(String message) async {
    if (!_enabled) return;
    try {
      await _crashlytics.log(message);
    } catch (_) {}
  }
}
