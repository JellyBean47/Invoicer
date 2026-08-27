import 'package:flutter_test/flutter_test.dart';

import 'package:business_buddy/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('email rejects empty and invalid values', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('owner@example.com'), isNull);
    });

    test('password enforces minimum length', () {
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('longenough'), isNull);
    });

    test('tax percent accepts 0-100 integers', () {
      expect(Validators.taxPercent('15'), isNull);
      expect(Validators.taxPercent('101'), isNotNull);
      expect(Validators.taxPercent('abc'), isNotNull);
    });
  });
}
