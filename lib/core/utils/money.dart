/// Integer-cents money helpers. Never use floating point for totals.
class Money {
  Money._();

  /// Round half-up when converting rand decimal strings is not used —
  /// all inputs are already cents.
  static int lineTotal({required int quantity, required int unitPriceCents}) {
    if (quantity <= 0) {
      throw ArgumentError('Quantity must be greater than zero.');
    }
    if (unitPriceCents < 0) {
      throw ArgumentError('Unit price cannot be negative.');
    }
    return quantity * unitPriceCents;
  }

  /// Calculation order: Subtotal → Discount → Tax → Grand Total
  static MoneyBreakdown calculate({
    required List<int> lineTotalsCents,
    required int discountCents,
    required int taxPercent,
  }) {
    if (taxPercent < 0 || taxPercent > 100) {
      throw ArgumentError('Tax percent must be between 0 and 100.');
    }
    if (discountCents < 0) {
      throw ArgumentError('Discount cannot be negative.');
    }

    final subtotal = lineTotalsCents.fold<int>(0, (sum, line) => sum + line);
    if (discountCents > subtotal) {
      throw ArgumentError('Discount cannot exceed subtotal.');
    }

    final afterDiscount = subtotal - discountCents;
    // Round half-up to nearest cent.
    final taxAmount = (afterDiscount * taxPercent + 50) ~/ 100;
    final total = afterDiscount + taxAmount;

    return MoneyBreakdown(
      subtotalCents: subtotal,
      discountCents: discountCents,
      taxPercent: taxPercent,
      taxAmountCents: taxAmount,
      totalCents: total,
    );
  }

  static String formatZar(int cents) {
    final negative = cents < 0;
    final abs = cents.abs();
    final whole = abs ~/ 100;
    final frac = (abs % 100).toString().padLeft(2, '0');
    final wholeFormatted = _thousands(whole);
    final value = 'R $wholeFormatted.$frac';
    return negative ? '-$value' : value;
  }

  static int? tryParseRandToCents(String input) {
    final cleaned = input.trim().replaceAll('R', '').replaceAll(',', '').trim();
    if (cleaned.isEmpty) return null;
    final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(cleaned);
    if (match == null) return null;
    final whole = int.parse(match.group(1)!);
    final fracRaw = match.group(2) ?? '0';
    final frac = int.parse(fracRaw.padRight(2, '0'));
    return whole * 100 + frac;
  }

  static String _thousands(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;
      buffer.write(text[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }
}

class MoneyBreakdown {
  const MoneyBreakdown({
    required this.subtotalCents,
    required this.discountCents,
    required this.taxPercent,
    required this.taxAmountCents,
    required this.totalCents,
  });

  final int subtotalCents;
  final int discountCents;
  final int taxPercent;
  final int taxAmountCents;
  final int totalCents;
}
