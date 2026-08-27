import 'package:business_buddy/models/expense.dart';
import 'package:business_buddy/models/invoice.dart';
import 'package:business_buddy/services/expense_service.dart';
import 'package:flutter_test/flutter_test.dart';

Expense _expense({
  ExpenseStatus status = ExpenseStatus.active,
  int amount = 1000,
  ExpenseCategory category = ExpenseCategory.fuel,
  String description = 'Petrol',
}) {
  return Expense(
    expenseId: 'e1',
    businessId: 'b1',
    category: category,
    description: description,
    amountCents: amount,
    expenseDate: DateTime(2026, 8, 1),
    status: status,
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );
}

Invoice _invoice({
  InvoiceStatus status = InvoiceStatus.final_,
  int grandTotal = 11500,
}) {
  return Invoice(
    invoiceId: 'i1',
    businessId: 'b1',
    customerId: 'c1',
    invoiceNumber: 'INV-2026-000001',
    status: status,
    subtotalCents: 10000,
    discountCents: 0,
    taxPercent: 15,
    taxAmountCents: 1500,
    grandTotalCents: grandTotal,
    amountPaidCents: 0,
    balanceRemainingCents: grandTotal,
    notes: '',
    issueDate: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    customerName: 'John',
  );
}

void main() {
  group('ExpenseCategory', () {
    test('maps office_supplies firestore value', () {
      expect(
        ExpenseCategory.officeSupplies.firestoreValue,
        'office_supplies',
      );
      expect(
        ExpenseCategory.fromString('office_supplies'),
        ExpenseCategory.officeSupplies,
      );
    });
  });

  group('ExpenseQuery', () {
    final list = [
      _expense(),
      _expense(
        status: ExpenseStatus.archived,
        amount: 5000,
        category: ExpenseCategory.rent,
        description: 'Shop rent',
      ),
      _expense(
        amount: 2500,
        category: ExpenseCategory.materials,
        description: 'Pipes',
      ),
    ];

    test('filters active expenses', () {
      final result = ExpenseQuery.filter(
        expenses: list,
        query: '',
        filter: ExpenseListFilter.active,
      );
      expect(result.length, 2);
      expect(result.every((expense) => expense.isActive), isTrue);
    });

    test('searches by description and category', () {
      final byDesc = ExpenseQuery.filter(
        expenses: list,
        query: 'pipes',
        filter: ExpenseListFilter.all,
      );
      expect(byDesc.length, 1);
      expect(byDesc.first.category, ExpenseCategory.materials);

      final byCategory = ExpenseQuery.filter(
        expenses: list,
        query: 'rent',
        filter: ExpenseListFilter.all,
      );
      expect(byCategory.length, 1);
      expect(byCategory.first.isArchived, isTrue);
    });
  });

  group('ProfitTotals', () {
    test('revenue excludes draft and cancelled invoices', () {
      final invoices = [
        _invoice(status: InvoiceStatus.final_, grandTotal: 10000),
        _invoice(status: InvoiceStatus.paid, grandTotal: 5000),
        _invoice(status: InvoiceStatus.partial, grandTotal: 3000),
        _invoice(status: InvoiceStatus.draft, grandTotal: 9999),
        _invoice(status: InvoiceStatus.cancelled, grandTotal: 8888),
      ];
      expect(ProfitTotals.revenueCents(invoices), 18000);
    });

    test('expenses exclude archived records', () {
      final expenses = [
        _expense(amount: 1000),
        _expense(amount: 2000, status: ExpenseStatus.archived),
        _expense(amount: 500),
      ];
      expect(ProfitTotals.expensesCents(expenses), 1500);
    });

    test('estimated profit is revenue minus expenses', () {
      final invoices = [
        _invoice(status: InvoiceStatus.final_, grandTotal: 20000),
      ];
      final expenses = [
        _expense(amount: 4500),
        _expense(amount: 500, status: ExpenseStatus.archived),
      ];
      expect(
        ProfitTotals.estimatedProfitCents(
          invoices: invoices,
          expenses: expenses,
        ),
        15500,
      );
    });
  });
}
