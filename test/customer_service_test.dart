import 'package:business_buddy/core/utils/app_exception.dart';
import 'package:business_buddy/core/utils/phone_utils.dart';
import 'package:business_buddy/models/customer.dart';
import 'package:business_buddy/services/customer_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhoneUtils', () {
    test('normalizes spaces and punctuation', () {
      expect(PhoneUtils.normalize('082 123 4567'), '0821234567');
      expect(PhoneUtils.normalize('+27 82 123 4567'), '+27821234567');
    });
  });

  group('CustomerQuery', () {
    final customers = [
      Customer(
        customerId: '1',
        businessId: 'b1',
        name: 'John Smith',
        phone: '0821234567',
        company: 'Smith Plumbing',
        status: CustomerStatus.active,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      Customer(
        customerId: '2',
        businessId: 'b1',
        name: 'Sarah Jones',
        phone: '0839998888',
        status: CustomerStatus.archived,
        createdAt: DateTime(2026, 1, 2),
        updatedAt: DateTime(2026, 1, 2),
        archivedAt: DateTime(2026, 1, 3),
      ),
    ];

    test('filters active customers', () {
      final result = CustomerQuery.filter(
        customers: customers,
        query: '',
        filter: CustomerListFilter.active,
      );
      expect(result.length, 1);
      expect(result.first.name, 'John Smith');
    });

    test('searches by phone digits', () {
      final result = CustomerQuery.filter(
        customers: customers,
        query: '082 123',
        filter: CustomerListFilter.all,
      );
      expect(result.length, 1);
      expect(result.first.customerId, '1');
    });

    test('searches by name case-insensitively', () {
      final result = CustomerQuery.filter(
        customers: customers,
        query: 'sarah',
        filter: CustomerListFilter.all,
      );
      expect(result.length, 1);
      expect(result.first.name, 'Sarah Jones');
    });

    test('blocks work for archived customers', () {
      expect(
        () => CustomerQuery.ensureCanReceiveWork(customers[1]),
        throwsA(isA<AppException>()),
      );
    });
  });
}
