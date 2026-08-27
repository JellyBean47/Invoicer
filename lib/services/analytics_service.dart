import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Anonymous product analytics only — never customer or financial PII.
///
/// Allowed events from `05_FIREBASE_ARCHITECTURE.md`:
/// app opens, invoices created, jobs completed, quotes converted, reports viewed.
class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics, bool enabled = true})
      : _analyticsOverride = analytics,
        _enabled = enabled;

  final FirebaseAnalytics? _analyticsOverride;
  final bool _enabled;

  FirebaseAnalytics? get _analytics {
    if (!_enabled) return null;
    return _analyticsOverride ?? FirebaseAnalytics.instance;
  }

  static const String appOpen = 'app_open';
  static const String invoiceCreated = 'invoice_created';
  static const String invoiceFinalized = 'invoice_finalized';
  static const String jobCompleted = 'job_completed';
  static const String quoteConverted = 'quote_converted';
  static const String paymentRecorded = 'payment_recorded';
  static const String reportViewed = 'report_viewed';
  static const String pdfShared = 'pdf_shared';

  /// Keys that must never be forwarded to Analytics.
  static const Set<String> blockedParameterKeys = {
    'email',
    'phone',
    'name',
    'customer',
    'customer_name',
    'customername',
    'address',
    'invoice_number',
    'invoicenumber',
    'amount',
    'total',
    'notes',
  };

  /// Visible for tests — filters unsafe parameter keys.
  static Map<String, Object> sanitizeParameters(Map<String, Object>? parameters) {
    if (parameters == null || parameters.isEmpty) return const {};
    return {
      for (final entry in parameters.entries)
        if (!blockedParameterKeys.contains(entry.key.toLowerCase()))
          entry.key: entry.value,
    };
  }

  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      final safe = sanitizeParameters(parameters);
      await analytics.logEvent(
        name: name,
        parameters: safe.isEmpty ? null : safe,
      );
    } catch (error, stack) {
      debugPrint('Analytics skipped: $error\n$stack');
    }
  }

  Future<void> logAppOpen() => logEvent(appOpen);

  Future<void> logInvoiceCreated() => logEvent(invoiceCreated);

  Future<void> logInvoiceFinalized() => logEvent(invoiceFinalized);

  Future<void> logJobCompleted() => logEvent(jobCompleted);

  Future<void> logQuoteConverted() => logEvent(quoteConverted);

  Future<void> logPaymentRecorded() => logEvent(paymentRecorded);

  Future<void> logReportViewed() => logEvent(reportViewed);

  Future<void> logPdfShared() => logEvent(pdfShared);
}
