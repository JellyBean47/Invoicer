import 'package:business_buddy/models/invoice.dart';
import 'package:business_buddy/models/payment.dart';
import 'package:business_buddy/services/payment_service.dart';
import 'package:flutter_test/flutter_test.dart';

Invoice _invoice({
  InvoiceStatus status = InvoiceStatus.final_,
  int grandTotal = 11500,
  int amountPaid = 0,
  DateTime? dueDate,
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
    amountPaidCents: amountPaid,
    balanceRemainingCents: grandTotal - amountPaid,
    notes: '',
    issueDate: DateTime(2026, 1, 1),
    dueDate: dueDate,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    customerName: 'John',
  );
}

Payment _payment({
  required int amount,
  required DateTime receivedAt,
}) {
  return Payment(
    paymentId: 'p1',
    businessId: 'b1',
    invoiceId: 'i1',
    customerId: 'c1',
    amountCents: amount,
    paymentMethod: PaymentMethod.cash,
    receivedAt: receivedAt,
    createdAt: receivedAt,
    invoiceNumber: 'INV-2026-000001',
    customerName: 'John',
  );
}

void main() {
  group('Invoice.canRecordPayment', () {
    test('allows unpaid finalized invoices', () {
      expect(_invoice().canRecordPayment, isTrue);
      expect(
        _invoice(status: InvoiceStatus.partial, amountPaid: 5000)
            .canRecordPayment,
        isTrue,
      );
      expect(
        _invoice(status: InvoiceStatus.overdue).canRecordPayment,
        isTrue,
      );
    });

    test('blocks draft, paid, and cancelled', () {
      expect(_invoice(status: InvoiceStatus.draft).canRecordPayment, isFalse);
      expect(
        _invoice(status: InvoiceStatus.paid, amountPaid: 11500)
            .canRecordPayment,
        isFalse,
      );
      expect(
        _invoice(status: InvoiceStatus.cancelled).canRecordPayment,
        isFalse,
      );
    });
  });

  group('Invoice.statusAfterPayment', () {
    test('marks paid when balance reaches zero', () {
      final invoice = _invoice();
      expect(
        invoice.statusAfterPayment(
          newAmountPaidCents: 11500,
          newBalanceRemainingCents: 0,
        ),
        InvoiceStatus.paid,
      );
    });

    test('marks partial when some amount remains', () {
      final invoice = _invoice();
      expect(
        invoice.statusAfterPayment(
          newAmountPaidCents: 5000,
          newBalanceRemainingCents: 6500,
        ),
        InvoiceStatus.partial,
      );
    });

    test('keeps overdue when unpaid and past due', () {
      final invoice = _invoice(
        dueDate: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(
        invoice.statusAfterPayment(
          newAmountPaidCents: 0,
          newBalanceRemainingCents: 11500,
        ),
        InvoiceStatus.overdue,
      );
    });
  });

  group('PaymentTotals', () {
    test('sums money received today only', () {
      final today = DateTime(2026, 8, 2, 10);
      final payments = [
        _payment(amount: 1000, receivedAt: today),
        _payment(amount: 2500, receivedAt: today.add(const Duration(hours: 2))),
        _payment(
          amount: 9999,
          receivedAt: today.subtract(const Duration(days: 1)),
        ),
      ];
      expect(
        PaymentTotals.moneyReceivedTodayCents(payments, now: today),
        3500,
      );
    });

    test('sums outstanding across unpaid invoices', () {
      final invoices = [
        _invoice(grandTotal: 10000),
        _invoice(
          status: InvoiceStatus.partial,
          grandTotal: 20000,
          amountPaid: 5000,
        ),
        _invoice(
          status: InvoiceStatus.paid,
          grandTotal: 5000,
          amountPaid: 5000,
        ),
        _invoice(status: InvoiceStatus.draft, grandTotal: 8000),
      ];
      expect(PaymentTotals.outstandingCents(invoices), 25000);
    });
  });

  group('PaymentQuery', () {
    test('searches by invoice number and method', () {
      final payments = [
        _payment(amount: 1000, receivedAt: DateTime(2026, 1, 1)),
        Payment(
          paymentId: 'p2',
          businessId: 'b1',
          invoiceId: 'i2',
          customerId: 'c1',
          amountCents: 2000,
          paymentMethod: PaymentMethod.eft,
          receivedAt: DateTime(2026, 1, 2),
          createdAt: DateTime(2026, 1, 2),
          invoiceNumber: 'INV-2026-000099',
          customerName: 'Sarah',
        ),
      ];
      final result = PaymentQuery.filter(payments: payments, query: '000099');
      expect(result.length, 1);
      expect(result.first.paymentMethod, PaymentMethod.eft);
    });
  });
}
