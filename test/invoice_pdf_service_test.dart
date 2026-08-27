import 'package:business_buddy/core/utils/app_exception.dart';
import 'package:business_buddy/models/business.dart';
import 'package:business_buddy/models/customer.dart';
import 'package:business_buddy/models/invoice.dart';
import 'package:business_buddy/models/invoice_item.dart';
import 'package:business_buddy/pdf/invoice_pdf_template.dart';
import 'package:business_buddy/services/invoice_pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';

Business _business() {
  return Business(
    businessId: 'b1',
    businessName: 'Acme Plumbing',
    ownerName: 'Ada Owner',
    phone: '0821234567',
    email: 'ada@acme.test',
    address: '1 Main Road, Cape Town',
    currency: 'ZAR',
    defaultTaxPercent: 15,
    invoicePrefix: 'INV',
    invoiceCounter: 1,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    vatNumber: '4123456789',
  );
}

Customer _customer() {
  return Customer(
    customerId: 'c1',
    businessId: 'b1',
    name: 'John Client',
    phone: '0831112233',
    status: CustomerStatus.active,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    email: 'john@client.test',
    company: 'Client Co',
    address: '2 Side Street',
  );
}

Invoice _invoice({
  InvoiceStatus status = InvoiceStatus.final_,
  String number = 'INV-2026-000001',
  List<InvoiceItem>? items,
  int discountCents = 1000,
  int amountPaidCents = 0,
}) {
  final lineItems = items ??
      [
        const InvoiceItem(
          itemId: '1',
          description: 'PVC Pipe',
          quantity: 2,
          unitPriceCents: 12000,
          lineTotalCents: 24000,
          displayOrder: 0,
        ),
        const InvoiceItem(
          itemId: '2',
          description: 'Labour',
          quantity: 3,
          unitPriceCents: 35000,
          lineTotalCents: 105000,
          displayOrder: 1,
        ),
      ];
  // subtotal 129000 - discount 1000 = 128000; tax 15% = 19200; total 147200
  return Invoice(
    invoiceId: 'i1',
    businessId: 'b1',
    customerId: 'c1',
    invoiceNumber: number,
    status: status,
    subtotalCents: 129000,
    discountCents: discountCents,
    taxPercent: 15,
    taxAmountCents: 19200,
    grandTotalCents: 147200,
    amountPaidCents: amountPaidCents,
    balanceRemainingCents: 147200 - amountPaidCents,
    notes: 'Thank you for your business.',
    issueDate: DateTime(2026, 1, 1),
    dueDate: DateTime(2026, 1, 15),
    finalizedAt: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    customerName: 'John Client',
    items: lineItems,
  );
}

void main() {
  group('InvoicePdfTemplate helpers', () {
    test('file name follows Invoice_[Number].pdf', () {
      expect(
        InvoicePdfTemplate.fileName('INV-2026-000145'),
        'Invoice_INV-2026-000145.pdf',
      );
      expect(
        InvoicePdfTemplate.fileName('INV 2026 0001'),
        'Invoice_INV_2026_0001.pdf',
      );
    });

    test('payment status labels match PDF spec', () {
      expect(
        InvoicePdfTemplate.paymentStatusLabel(InvoiceStatus.final_),
        'Outstanding',
      );
      expect(
        InvoicePdfTemplate.paymentStatusLabel(InvoiceStatus.partial),
        'Partially Paid',
      );
      expect(
        InvoicePdfTemplate.paymentStatusLabel(InvoiceStatus.paid),
        'Paid',
      );
      expect(
        InvoicePdfTemplate.paymentStatusLabel(InvoiceStatus.overdue),
        'Overdue',
      );
    });

    test('payment terms derived from due date', () {
      final invoice = _invoice();
      expect(
        InvoicePdfTemplate.paymentTerms(invoice),
        'Payment due within 14 days',
      );
      expect(
        InvoicePdfTemplate.paymentTerms(
          invoice.copyWith(clearDueDate: true),
        ),
        'Payment due on receipt',
      );
    });
  });

  group('InvoicePdfService.validate', () {
    test('rejects draft invoices', () {
      expect(
        () => InvoicePdfService.validate(
          business: _business(),
          customer: _customer(),
          invoice: _invoice(status: InvoiceStatus.draft),
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('finalized'),
          ),
        ),
      );
    });

    test('rejects missing business', () {
      expect(
        () => InvoicePdfService.validate(
          business: null,
          customer: _customer(),
          invoice: _invoice(),
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('rejects missing customer', () {
      expect(
        () => InvoicePdfService.validate(
          business: _business(),
          customer: null,
          invoice: _invoice(),
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('rejects missing invoice number', () {
      expect(
        () => InvoicePdfService.validate(
          business: _business(),
          customer: _customer(),
          invoice: _invoice(number: '  '),
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('number'),
          ),
        ),
      );
    });

    test('rejects invalid totals', () {
      final bad = _invoice().copyWith(grandTotalCents: 1);
      expect(
        () => InvoicePdfService.validate(
          business: _business(),
          customer: _customer(),
          invoice: bad,
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('totals'),
          ),
        ),
      );
    });

    test('accepts valid finalized invoice', () {
      expect(
        () => InvoicePdfService.validate(
          business: _business(),
          customer: _customer(),
          invoice: _invoice(),
        ),
        returnsNormally,
      );
    });
  });

  group('InvoicePdfService.generateBytes', () {
    test('produces a non-empty PDF document', () async {
      final bytes = await InvoicePdfService().generateBytes(
        business: _business(),
        customer: _customer(),
        invoice: _invoice(),
        generatedAt: DateTime(2026, 2, 1),
      );
      expect(bytes.length, greaterThan(100));
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });
  });
}
