import 'package:business_buddy/models/invoice.dart';
import 'package:business_buddy/models/job.dart';
import 'package:business_buddy/models/payment.dart';
import 'package:business_buddy/services/daily_briefing_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 2, 8);

  group('DailyBriefingService', () {
    test('counts today jobs, dues, overdue and outstanding customers', () {
      final briefing = DailyBriefingService.build(
        now: now,
        jobs: [
          Job(
            jobId: 'j1',
            businessId: 'b1',
            customerId: 'c1',
            jobNumber: 'JOB-2026-000001',
            title: 'Leak',
            description: '',
            address: '',
            status: JobStatus.scheduled,
            priority: JobPriority.normal,
            createdAt: now,
            updatedAt: now,
            scheduledDate: DateTime(2026, 8, 2, 10),
          ),
          Job(
            jobId: 'j2',
            businessId: 'b1',
            customerId: 'c2',
            jobNumber: 'JOB-2026-000002',
            title: 'Done',
            description: '',
            address: '',
            status: JobStatus.completed,
            priority: JobPriority.normal,
            createdAt: now,
            updatedAt: now,
            scheduledDate: DateTime(2026, 8, 2, 11),
            completedAt: now,
          ),
        ],
        invoices: [
          Invoice(
            invoiceId: 'i1',
            businessId: 'b1',
            customerId: 'c1',
            invoiceNumber: 'INV-2026-000001',
            status: InvoiceStatus.final_,
            subtotalCents: 10000,
            discountCents: 0,
            taxPercent: 15,
            taxAmountCents: 1500,
            grandTotalCents: 11500,
            amountPaidCents: 0,
            balanceRemainingCents: 11500,
            notes: '',
            issueDate: DateTime(2026, 7, 20),
            dueDate: DateTime(2026, 8, 2),
            createdAt: now,
            updatedAt: now,
          ),
          Invoice(
            invoiceId: 'i2',
            businessId: 'b1',
            customerId: 'c2',
            invoiceNumber: 'INV-2026-000002',
            status: InvoiceStatus.final_,
            subtotalCents: 20000,
            discountCents: 0,
            taxPercent: 15,
            taxAmountCents: 3000,
            grandTotalCents: 23000,
            amountPaidCents: 0,
            balanceRemainingCents: 23000,
            notes: '',
            issueDate: DateTime(2026, 7, 1),
            dueDate: DateTime(2026, 7, 15),
            createdAt: now,
            updatedAt: now,
          ),
        ],
        payments: [
          Payment(
            paymentId: 'p1',
            businessId: 'b1',
            invoiceId: 'i3',
            customerId: 'c3',
            amountCents: 5000,
            paymentMethod: PaymentMethod.cash,
            receivedAt: DateTime(2026, 8, 2, 9),
            createdAt: now,
            reference: '',
            notes: '',
          ),
        ],
      );

      expect(briefing.jobsScheduledToday, 1);
      expect(briefing.jobsCompletedToday, 1);
      expect(briefing.invoicesDueToday, 1);
      expect(briefing.overdueInvoices, 1);
      expect(briefing.outstandingCustomerCount, 2);
      expect(briefing.paymentsReceivedTodayCents, 5000);
      expect(briefing.hasAnything, isTrue);
      expect(briefing.morningBody(), contains('1 job scheduled'));
      expect(briefing.morningBody(), contains('1 invoice due'));
      expect(briefing.morningBody(), contains('1 overdue payment'));
    });

    test('clear day produces calm message', () {
      final briefing = DailyBriefingService.build(
        now: now,
        jobs: const [],
        invoices: const [],
        payments: const [],
      );
      expect(briefing.hasAnything, isFalse);
      expect(briefing.morningBody(), contains('looks clear'));
    });
  });
}
