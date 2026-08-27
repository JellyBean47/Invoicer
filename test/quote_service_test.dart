import 'package:business_buddy/core/utils/app_exception.dart';
import 'package:business_buddy/models/quote.dart';
import 'package:business_buddy/services/quote_service.dart';
import 'package:flutter_test/flutter_test.dart';

Quote _quote(QuoteStatus status) {
  return Quote(
    quoteId: 'q1',
    businessId: 'b1',
    customerId: 'c1',
    quoteNumber: 'QUO-2026-000001',
    status: status,
    subtotalCents: 10000,
    discountCents: 0,
    taxPercent: 15,
    taxAmountCents: 1500,
    totalCents: 11500,
    notes: '',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    customerName: 'John',
  );
}

void main() {
  group('QuoteTransitions', () {
    test('allows draft to sent and accepted', () {
      expect(
        () => QuoteTransitions.assertAllowed(
          from: QuoteStatus.draft,
          to: QuoteStatus.sent,
        ),
        returnsNormally,
      );
      expect(
        () => QuoteTransitions.assertAllowed(
          from: QuoteStatus.draft,
          to: QuoteStatus.accepted,
        ),
        returnsNormally,
      );
    });

    test('blocks accepted returning to draft', () {
      expect(
        () => QuoteTransitions.assertAllowed(
          from: QuoteStatus.accepted,
          to: QuoteStatus.draft,
        ),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('QuoteQuery', () {
    final list = [
      _quote(QuoteStatus.draft),
      Quote(
        quoteId: 'q2',
        businessId: 'b1',
        customerId: 'c1',
        quoteNumber: 'QUO-2026-000002',
        status: QuoteStatus.accepted,
        subtotalCents: 20000,
        discountCents: 0,
        taxPercent: 15,
        taxAmountCents: 3000,
        totalCents: 23000,
        notes: '',
        createdAt: DateTime(2026, 1, 2),
        updatedAt: DateTime(2026, 1, 2),
        customerName: 'Sarah',
      ),
    ];

    test('filters accepted quotes', () {
      final result = QuoteQuery.filter(
        quotes: list,
        query: '',
        filter: QuoteListFilter.accepted,
      );
      expect(result.length, 1);
      expect(result.first.customerName, 'Sarah');
    });

    test('searches by quote number', () {
      final result = QuoteQuery.filter(
        quotes: list,
        query: '000002',
        filter: QuoteListFilter.all,
      );
      expect(result.length, 1);
      expect(result.first.quoteNumber, 'QUO-2026-000002');
    });
  });
}
