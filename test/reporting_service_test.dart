import 'package:business_buddy/models/customer.dart';
import 'package:business_buddy/models/expense.dart';
import 'package:business_buddy/models/invoice.dart';
import 'package:business_buddy/models/job.dart';
import 'package:business_buddy/models/payment.dart';
import 'package:business_buddy/services/reporting_service.dart';
import 'package:flutter_test/flutter_test.dart';

Invoice _invoice({
  required String id,
  required InvoiceStatus status,
  required int grandTotal,
  required DateTime issueDate,
  DateTime? finalizedAt,
  int tax = 0,
  int amountPaid = 0,
  String customerId = 'c1',
  String customerName = 'John',
  DateTime? dueDate,
}) {
  return Invoice(
    invoiceId: id,
    businessId: 'b1',
    customerId: customerId,
    invoiceNumber: 'INV-$id',
    status: status,
    subtotalCents: grandTotal,
    discountCents: 0,
    taxPercent: 15,
    taxAmountCents: tax,
    grandTotalCents: grandTotal,
    amountPaidCents: amountPaid,
    balanceRemainingCents: grandTotal - amountPaid,
    notes: '',
    issueDate: issueDate,
    dueDate: dueDate,
    finalizedAt: finalizedAt ?? issueDate,
    createdAt: issueDate,
    updatedAt: issueDate,
    customerName: customerName,
  );
}

void main() {
  const service = ReportingService();
  final now = DateTime(2026, 8, 15, 12);

  group('DateRange.forPeriod', () {
    test('builds month range', () {
      final range = DateRange.forPeriod(ReportPeriod.thisMonth, now: now);
      expect(range.start, DateTime(2026, 8, 1));
      expect(range.endExclusive, DateTime(2026, 9, 1));
      expect(range.contains(DateTime(2026, 8, 15)), isTrue);
      expect(range.contains(DateTime(2026, 9, 1)), isFalse);
    });

    test('builds custom inclusive end date', () {
      final range = DateRange.forPeriod(
        ReportPeriod.custom,
        now: now,
        customStart: DateTime(2026, 8, 1),
        customEndInclusive: DateTime(2026, 8, 10),
      );
      expect(range.contains(DateTime(2026, 8, 10, 23)), isTrue);
      expect(range.contains(DateTime(2026, 8, 11)), isFalse);
    });
  });

  group('ReportingService.build', () {
    final invoices = [
      _invoice(
        id: '1',
        status: InvoiceStatus.final_,
        grandTotal: 11500,
        tax: 1500,
        issueDate: DateTime(2026, 8, 5),
      ),
      _invoice(
        id: '2',
        status: InvoiceStatus.paid,
        grandTotal: 23000,
        tax: 3000,
        amountPaid: 23000,
        issueDate: DateTime(2026, 8, 8),
        customerId: 'c2',
        customerName: 'Sarah',
      ),
      _invoice(
        id: '3',
        status: InvoiceStatus.partial,
        grandTotal: 10000,
        tax: 0,
        amountPaid: 4000,
        issueDate: DateTime(2026, 8, 10),
        dueDate: DateTime(2026, 8, 1),
      ),
      _invoice(
        id: 'draft',
        status: InvoiceStatus.draft,
        grandTotal: 99999,
        issueDate: DateTime(2026, 8, 12),
      ),
      _invoice(
        id: 'old',
        status: InvoiceStatus.final_,
        grandTotal: 5000,
        tax: 500,
        issueDate: DateTime(2026, 7, 20),
      ),
    ];

    final payments = [
      Payment(
        paymentId: 'p1',
        businessId: 'b1',
        invoiceId: '2',
        customerId: 'c2',
        amountCents: 23000,
        paymentMethod: PaymentMethod.eft,
        receivedAt: DateTime(2026, 8, 9),
        createdAt: DateTime(2026, 8, 9),
      ),
      Payment(
        paymentId: 'p2',
        businessId: 'b1',
        invoiceId: '3',
        customerId: 'c1',
        amountCents: 4000,
        paymentMethod: PaymentMethod.cash,
        receivedAt: DateTime(2026, 8, 11),
        createdAt: DateTime(2026, 8, 11),
      ),
    ];

    final expenses = [
      Expense(
        expenseId: 'e1',
        businessId: 'b1',
        category: ExpenseCategory.fuel,
        description: 'Petrol',
        amountCents: 2000,
        expenseDate: DateTime(2026, 8, 3),
        status: ExpenseStatus.active,
        createdAt: DateTime(2026, 8, 3),
        updatedAt: DateTime(2026, 8, 3),
      ),
      Expense(
        expenseId: 'e2',
        businessId: 'b1',
        category: ExpenseCategory.rent,
        description: 'Rent',
        amountCents: 8000,
        expenseDate: DateTime(2026, 8, 1),
        status: ExpenseStatus.archived,
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      ),
    ];

    final jobs = [
      Job(
        jobId: 'j1',
        businessId: 'b1',
        customerId: 'c1',
        jobNumber: 'JOB-1',
        title: 'Fix pipe',
        description: '',
        address: '',
        status: JobStatus.completed,
        priority: JobPriority.normal,
        createdAt: DateTime(2026, 8, 2),
        updatedAt: DateTime(2026, 8, 4),
        completedAt: DateTime(2026, 8, 4),
        scheduledDate: DateTime(2026, 8, 3),
      ),
      Job(
        jobId: 'j2',
        businessId: 'b1',
        customerId: 'c1',
        jobNumber: 'JOB-2',
        title: 'Follow up',
        description: '',
        address: '',
        status: JobStatus.scheduled,
        priority: JobPriority.normal,
        createdAt: DateTime(2026, 8, 14),
        updatedAt: DateTime(2026, 8, 14),
        scheduledDate: DateTime(2026, 8, 20),
      ),
    ];

    final customers = [
      Customer(
        customerId: 'c1',
        businessId: 'b1',
        name: 'John',
        phone: '0821111111',
        status: CustomerStatus.active,
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      ),
      Customer(
        customerId: 'c2',
        businessId: 'b1',
        name: 'Sarah',
        phone: '0822222222',
        status: CustomerStatus.active,
        createdAt: DateTime(2026, 7, 1),
        updatedAt: DateTime(2026, 7, 1),
      ),
    ];

    test('computes month revenue, tax, profit from source records', () {
      final report = service.build(
        period: ReportPeriod.thisMonth,
        invoices: invoices,
        payments: payments,
        expenses: expenses,
        jobs: jobs,
        customers: customers,
        now: now,
      );

      // final + paid + partial in August = 11500 + 23000 + 10000
      expect(report.revenueCents, 44500);
      expect(report.taxCollectedCents, 4500);
      expect(report.expenseCents, 2000); // archived excluded
      expect(report.estimatedProfitCents, 42500);
      expect(report.paymentsReceivedCents, 27000);
      expect(report.invoiceCount, 3);
      expect(report.newCustomers, 1);
      expect(report.jobsCompleted, 1);
      expect(report.upcomingJobs, 1);
    });

    test('excludes draft invoices from revenue', () {
      final report = service.build(
        period: ReportPeriod.thisMonth,
        invoices: invoices,
        payments: payments,
        expenses: expenses,
        jobs: jobs,
        customers: customers,
        now: now,
      );
      expect(report.revenueCents, 44500);
      expect(report.invoiceCount, 3);
    });

    test('tracks outstanding and top customers', () {
      final report = service.build(
        period: ReportPeriod.thisMonth,
        invoices: invoices,
        payments: payments,
        expenses: expenses,
        jobs: jobs,
        customers: customers,
        now: now,
      );

      // Current outstanding (all time): Aug final 11500 + partial 6000 + July final 5000
      expect(report.outstandingCents, 22500);
      expect(report.outstandingInvoices.length, 3);
      expect(report.topCustomers.first.customerName, 'Sarah');
      expect(report.topCustomers.first.revenueCents, 23000);
    });

    test('builds payment method and expense category breakdowns', () {
      final report = service.build(
        period: ReportPeriod.thisMonth,
        invoices: invoices,
        payments: payments,
        expenses: expenses,
        jobs: jobs,
        customers: customers,
        now: now,
      );

      expect(report.paymentsByMethod.length, 2);
      expect(report.paymentsByMethod.first.method, PaymentMethod.eft);
      expect(report.expensesByCategory.single.category, ExpenseCategory.fuel);
    });

    test('generates insights from report totals', () {
      final report = service.build(
        period: ReportPeriod.thisMonth,
        invoices: invoices,
        payments: payments,
        expenses: expenses,
        jobs: jobs,
        customers: customers,
        now: now,
      );

      expect(report.insights, isNotEmpty);
      expect(
        report.insights.any((insight) => insight.title.contains('Outstanding')),
        isTrue,
      );
      expect(
        report.insights.any(
          (insight) => insight.title.contains('Highest paying'),
        ),
        isTrue,
      );
    });
  });
}
