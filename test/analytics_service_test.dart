import 'package:business_buddy/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalyticsService privacy filter', () {
    test('strips blocked PII / money keys', () {
      final safe = AnalyticsService.sanitizeParameters({
        'source': 'dashboard',
        'phone': '0820000000',
        'amount': 125000,
        'customer_name': 'John',
        'period': 'month',
      });
      expect(safe.keys, unorderedEquals(['source', 'period']));
      expect(safe.containsKey('phone'), isFalse);
      expect(safe.containsKey('amount'), isFalse);
    });

    test('event name constants match architecture list', () {
      expect(AnalyticsService.appOpen, 'app_open');
      expect(AnalyticsService.invoiceCreated, 'invoice_created');
      expect(AnalyticsService.invoiceFinalized, 'invoice_finalized');
      expect(AnalyticsService.jobCompleted, 'job_completed');
      expect(AnalyticsService.quoteConverted, 'quote_converted');
      expect(AnalyticsService.paymentRecorded, 'payment_recorded');
      expect(AnalyticsService.reportViewed, 'report_viewed');
      expect(AnalyticsService.pdfShared, 'pdf_shared');
    });

    test('disabled service is a safe no-op without Firebase', () async {
      final analytics = AnalyticsService(enabled: false);
      await analytics.logInvoiceCreated();
      await analytics.logPaymentRecorded();
      await analytics.logEvent('custom', {'phone': '0820000000'});
    });
  });
}
