import '../models/invoice.dart';
import '../models/job.dart';
import '../models/payment.dart';

class DailyBriefing {
  const DailyBriefing({
    required this.jobsScheduledToday,
    required this.invoicesDueToday,
    required this.overdueInvoices,
    required this.outstandingCustomerCount,
    required this.paymentsReceivedTodayCents,
    required this.jobsCompletedToday,
  });

  final int jobsScheduledToday;
  final int invoicesDueToday;
  final int overdueInvoices;
  final int outstandingCustomerCount;
  final int paymentsReceivedTodayCents;
  final int jobsCompletedToday;

  bool get hasAnything =>
      jobsScheduledToday > 0 ||
      invoicesDueToday > 0 ||
      overdueInvoices > 0 ||
      outstandingCustomerCount > 0;

  String morningTitle(String ownerName) {
    final name = ownerName.trim().isEmpty ? 'there' : ownerName.trim();
    return 'Good morning, $name';
  }

  String morningBody() {
    if (!hasAnything) {
      return 'Your day looks clear. Tap to open your dashboard.';
    }
    final lines = <String>[
      if (jobsScheduledToday > 0)
        '$jobsScheduledToday job${jobsScheduledToday == 1 ? '' : 's'} scheduled',
      if (invoicesDueToday > 0)
        '$invoicesDueToday invoice${invoicesDueToday == 1 ? '' : 's'} due',
      if (overdueInvoices > 0)
        '$overdueInvoices overdue payment${overdueInvoices == 1 ? '' : 's'}',
      if (outstandingCustomerCount > 0)
        '$outstandingCustomerCount customer${outstandingCustomerCount == 1 ? '' : 's'} with unpaid invoices',
    ];
    return 'Today:\n${lines.map((line) => '• $line').join('\n')}\n\nTap to open your dashboard.';
  }
}

/// Pure reporting helper for the daily briefing signature notification.
class DailyBriefingService {
  DailyBriefingService._();

  static DailyBriefing build({
    required List<Job> jobs,
    required List<Invoice> invoices,
    required List<Payment> payments,
    DateTime? now,
  }) {
    final moment = now ?? DateTime.now();
    final today = DateTime(moment.year, moment.month, moment.day);

    final jobsToday = jobs.where((job) {
      final scheduled = job.scheduledDate;
      if (scheduled == null) return false;
      if (job.status == JobStatus.cancelled) return false;
      return _isSameDay(scheduled, today);
    }).toList();

    final jobsScheduledToday = jobsToday
        .where(
          (job) =>
              job.status == JobStatus.scheduled ||
              job.status == JobStatus.inProgress ||
              job.status == JobStatus.draft,
        )
        .length;

    final jobsCompletedToday = jobsToday
        .where((job) => job.status == JobStatus.completed)
        .length;

    final dueToday = invoices.where((invoice) {
      if (!invoice.status.isFinalized) return false;
      if (invoice.balanceRemainingCents <= 0) return false;
      final due = invoice.dueDate;
      if (due == null) return false;
      return _isSameDay(due, today);
    }).length;

    final overdue = invoices.where((invoice) {
      if (invoice.status == InvoiceStatus.overdue) return true;
      if (!invoice.status.canRecordPayment) return false;
      final due = invoice.dueDate;
      if (due == null) return false;
      final dueDay = DateTime(due.year, due.month, due.day);
      return dueDay.isBefore(today) && invoice.balanceRemainingCents > 0;
    }).length;

    final outstandingCustomers = invoices
        .where(
          (invoice) =>
              invoice.hasOutstanding ||
              (invoice.status.canRecordPayment &&
                  invoice.balanceRemainingCents > 0),
        )
        .map((invoice) => invoice.customerId)
        .toSet()
        .length;

    final receivedToday = payments
        .where((payment) => _isSameDay(payment.receivedAt, today))
        .fold<int>(0, (sum, payment) => sum + payment.amountCents);

    return DailyBriefing(
      jobsScheduledToday: jobsScheduledToday,
      invoicesDueToday: dueToday,
      overdueInvoices: overdue,
      outstandingCustomerCount: outstandingCustomers,
      paymentsReceivedTodayCents: receivedToday,
      jobsCompletedToday: jobsCompletedToday,
    );
  }

  static bool _isSameDay(DateTime value, DateTime day) {
    return value.year == day.year &&
        value.month == day.month &&
        value.day == day.day;
  }
}
