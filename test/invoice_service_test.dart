import 'package:business_buddy/core/utils/money.dart';
import 'package:business_buddy/models/invoice.dart';
import 'package:business_buddy/services/invoice_service.dart';
import 'package:flutter_test/flutter_test.dart';

Invoice _invoice(InvoiceStatus status, {String number = 'INV-2026-000001'}) {
  return Invoice(
    invoiceId: 'i1',
    businessId: 'b1',
    customerId: 'c1',
    invoiceNumber: number,
    status: status,
    subtotalCents: 10000,
    discountCents: 0,
    taxPercent: 15,
    taxAmountCents: 1500,
    grandTotalCents: 11500,
    amountPaidCents: 0,
    balanceRemainingCents: 11500,
    notes: '',
    issueDate: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    customerName: 'John',
  );
}

void main() {
  group('InvoiceStatus', () {
    test('draft is editable; final is locked', () {
      expect(InvoiceStatus.draft.isEditable, isTrue);
      expect(InvoiceStatus.final_.isEditable, isFalse);
      expect(InvoiceStatus.final_.isFinalized, isTrue);
      expect(InvoiceStatus.draft.canFinalize, isTrue);
      expect(InvoiceStatus.final_.canCancel, isFalse);
      expect(InvoiceStatus.draft.canCancel, isTrue);
      expect(InvoiceStatus.final_.canDuplicate, isTrue);
      expect(InvoiceStatus.draft.canDuplicate, isFalse);
    });

    test('firestore value maps final_ to final', () {
      expect(InvoiceStatus.final_.firestoreValue, 'final');
      expect(InvoiceStatus.fromString('final'), InvoiceStatus.final_);
      expect(InvoiceStatus.fromString('partial'), InvoiceStatus.partial);
    });
  });

  group('InvoiceQuery', () {
    final list = [
      _invoice(InvoiceStatus.draft),
      _invoice(InvoiceStatus.final_, number: 'INV-2026-000002').copyWith(
        customerName: 'Sarah',
      ),
      Invoice(
        invoiceId: 'i3',
        businessId: 'b1',
        customerId: 'c2',
        invoiceNumber: 'INV-2026-000003',
        status: InvoiceStatus.paid,
        subtotalCents: 20000,
        discountCents: 0,
        taxPercent: 15,
        taxAmountCents: 3000,
        grandTotalCents: 23000,
        amountPaidCents: 23000,
        balanceRemainingCents: 0,
        notes: '',
        issueDate: DateTime(2026, 1, 3),
        createdAt: DateTime(2026, 1, 3),
        updatedAt: DateTime(2026, 1, 3),
        customerName: 'Alex',
      ),
      _invoice(InvoiceStatus.overdue, number: 'INV-2026-000004'),
    ];

    test('filters unpaid invoices', () {
      final result = InvoiceQuery.filter(
        invoices: list,
        query: '',
        filter: InvoiceListFilter.unpaid,
      );
      expect(result.length, 2);
      expect(
        result.every(
          (invoice) =>
              invoice.status == InvoiceStatus.final_ ||
              invoice.status == InvoiceStatus.overdue,
        ),
        isTrue,
      );
    });

    test('filters paid invoices', () {
      final result = InvoiceQuery.filter(
        invoices: list,
        query: '',
        filter: InvoiceListFilter.paid,
      );
      expect(result.length, 1);
      expect(result.first.customerName, 'Alex');
    });

    test('searches by invoice number', () {
      final result = InvoiceQuery.filter(
        invoices: list,
        query: '000002',
        filter: InvoiceListFilter.all,
      );
      expect(result.length, 1);
      expect(result.first.invoiceNumber, 'INV-2026-000002');
    });
  });

  group('Invoice money totals', () {
    test('grand total follows subtotal → discount → tax', () {
      final breakdown = Money.calculate(
        lineTotalsCents: [10000, 5000],
        discountCents: 1000,
        taxPercent: 15,
      );
      expect(breakdown.subtotalCents, 15000);
      expect(breakdown.discountCents, 1000);
      expect(breakdown.taxAmountCents, 2100);
      expect(breakdown.totalCents, 16100);
    });
  });
}
