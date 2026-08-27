import 'package:business_buddy/core/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money', () {
    test('calculates line totals in cents', () {
      expect(Money.lineTotal(quantity: 3, unitPriceCents: 12000), 36000);
    });

    test('applies discount before tax', () {
      final result = Money.calculate(
        lineTotalsCents: [100000, 5000], // R1,050.00
        discountCents: 10000, // R100.00
        taxPercent: 15,
      );
      expect(result.subtotalCents, 105000);
      expect(result.discountCents, 10000);
      // taxable = 95000; 15% = 14250
      expect(result.taxAmountCents, 14250);
      expect(result.totalCents, 109250);
    });

    test('rejects discount above subtotal', () {
      expect(
        () => Money.calculate(
          lineTotalsCents: [1000],
          discountCents: 2000,
          taxPercent: 15,
        ),
        throwsArgumentError,
      );
    });

    test('formats ZAR from cents', () {
      expect(Money.formatZar(125000), 'R 1,250.00');
      expect(Money.formatZar(99), 'R 0.99');
    });

    test('parses rand text to cents', () {
      expect(Money.tryParseRandToCents('R 1,250.50'), 125050);
      expect(Money.tryParseRandToCents('350'), 35000);
      expect(Money.tryParseRandToCents('bad'), isNull);
    });
  });
}
