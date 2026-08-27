import '../core/utils/money.dart';
import '../models/customer.dart';
import '../models/expense.dart';
import '../models/invoice.dart';
import '../models/job.dart';
import '../models/payment.dart';

enum ReportPeriod {
  today,
  thisWeek,
  thisMonth,
  thisYear,
  custom;

  String get label {
    switch (this) {
      case ReportPeriod.today:
        return 'Today';
      case ReportPeriod.thisWeek:
        return 'This Week';
      case ReportPeriod.thisMonth:
        return 'This Month';
      case ReportPeriod.thisYear:
        return 'This Year';
      case ReportPeriod.custom:
        return 'Custom';
    }
  }
}

class DateRange {
  const DateRange({required this.start, required this.endExclusive});

  final DateTime start;
  final DateTime endExclusive;

  bool contains(DateTime date) {
    return !date.isBefore(start) && date.isBefore(endExclusive);
  }

  static DateRange forPeriod(
    ReportPeriod period, {
    DateTime? now,
    DateTime? customStart,
    DateTime? customEndInclusive,
  }) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);

    switch (period) {
      case ReportPeriod.today:
        return DateRange(
          start: today,
          endExclusive: today.add(const Duration(days: 1)),
        );
      case ReportPeriod.thisWeek:
        final weekday = today.weekday; // Mon=1 ... Sun=7
        final weekStart = today.subtract(Duration(days: weekday - 1));
        return DateRange(
          start: weekStart,
          endExclusive: weekStart.add(const Duration(days: 7)),
        );
      case ReportPeriod.thisMonth:
        final monthStart = DateTime(today.year, today.month, 1);
        final nextMonth = DateTime(today.year, today.month + 1, 1);
        return DateRange(start: monthStart, endExclusive: nextMonth);
      case ReportPeriod.thisYear:
        final yearStart = DateTime(today.year, 1, 1);
        final nextYear = DateTime(today.year + 1, 1, 1);
        return DateRange(start: yearStart, endExclusive: nextYear);
      case ReportPeriod.custom:
        final start = customStart == null
            ? today
            : DateTime(customStart.year, customStart.month, customStart.day);
        final endDay = customEndInclusive == null
            ? today
            : DateTime(
                customEndInclusive.year,
                customEndInclusive.month,
                customEndInclusive.day,
              );
        final endExclusive = endDay.add(const Duration(days: 1));
        if (endExclusive.isBefore(start) || endExclusive.isAtSameMomentAs(start)) {
          return DateRange(
            start: start,
            endExclusive: start.add(const Duration(days: 1)),
          );
        }
        return DateRange(start: start, endExclusive: endExclusive);
    }
  }
}

class MonthlyPoint {
  const MonthlyPoint({
    required this.year,
    required this.month,
    required this.revenueCents,
    required this.expenseCents,
    required this.paymentCents,
  });

  final int year;
  final int month;
  final int revenueCents;
  final int expenseCents;
  final int paymentCents;

  int get profitCents => revenueCents - expenseCents;

  String get label {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }
}

class CategoryTotal {
  const CategoryTotal({required this.category, required this.amountCents});

  final ExpenseCategory category;
  final int amountCents;
}

class MethodTotal {
  const MethodTotal({required this.method, required this.amountCents});

  final PaymentMethod method;
  final int amountCents;
}

class CustomerRevenueRow {
  const CustomerRevenueRow({
    required this.customerId,
    required this.customerName,
    required this.invoiceCount,
    required this.revenueCents,
    required this.outstandingCents,
  });

  final String customerId;
  final String customerName;
  final int invoiceCount;
  final int revenueCents;
  final int outstandingCents;
}

class OutstandingInvoiceRow {
  const OutstandingInvoiceRow({
    required this.invoice,
    required this.daysOutstanding,
  });

  final Invoice invoice;
  final int daysOutstanding;
}

class BusinessInsight {
  const BusinessInsight({
    required this.title,
    required this.detail,
    required this.iconName,
  });

  final String title;
  final String detail;

  /// Simple key used by UI to pick an icon.
  final String iconName;
}

class ReportSnapshot {
  const ReportSnapshot({
    required this.period,
    required this.range,
    required this.revenueCents,
    required this.paidOnInvoicesCents,
    required this.paymentsReceivedCents,
    required this.outstandingCents,
    required this.taxCollectedCents,
    required this.expenseCents,
    required this.estimatedProfitCents,
    required this.invoiceCount,
    required this.paymentCount,
    required this.averageInvoiceCents,
    required this.largestInvoiceCents,
    required this.smallestInvoiceCents,
    required this.jobsCreated,
    required this.jobsCompleted,
    required this.jobsCancelled,
    required this.upcomingJobs,
    required this.newCustomers,
    required this.expensesByCategory,
    required this.paymentsByMethod,
    required this.topCustomers,
    required this.outstandingInvoices,
    required this.monthlyTrend,
    required this.previousRevenueCents,
    required this.insights,
  });

  final ReportPeriod period;
  final DateRange range;
  final int revenueCents;
  final int paidOnInvoicesCents;
  final int paymentsReceivedCents;
  final int outstandingCents;
  final int taxCollectedCents;
  final int expenseCents;
  final int estimatedProfitCents;
  final int invoiceCount;
  final int paymentCount;
  final int averageInvoiceCents;
  final int largestInvoiceCents;
  final int smallestInvoiceCents;
  final int jobsCreated;
  final int jobsCompleted;
  final int jobsCancelled;
  final int upcomingJobs;
  final int newCustomers;
  final List<CategoryTotal> expensesByCategory;
  final List<MethodTotal> paymentsByMethod;
  final List<CustomerRevenueRow> topCustomers;
  final List<OutstandingInvoiceRow> outstandingInvoices;
  final List<MonthlyPoint> monthlyTrend;
  final int previousRevenueCents;
  final List<BusinessInsight> insights;

  int get revenueChangeCents => revenueCents - previousRevenueCents;

  double? get revenueChangePercent {
    if (previousRevenueCents == 0) {
      return revenueCents == 0 ? 0 : 100;
    }
    return (revenueChangeCents / previousRevenueCents) * 100;
  }
}

class ReportingService {
  const ReportingService();

  ReportSnapshot build({
    required ReportPeriod period,
    required List<Invoice> invoices,
    required List<Payment> payments,
    required List<Expense> expenses,
    required List<Job> jobs,
    required List<Customer> customers,
    DateTime? now,
    DateTime? customStart,
    DateTime? customEndInclusive,
  }) {
    final current = now ?? DateTime.now();
    final range = DateRange.forPeriod(
      period,
      now: current,
      customStart: customStart,
      customEndInclusive: customEndInclusive,
    );
    final previousRange = _previousRange(range);

    final periodInvoices = invoices
        .where(
          (invoice) =>
              invoice.status.isFinalized &&
              range.contains(_invoiceDate(invoice)),
        )
        .toList();
    final previousInvoices = invoices
        .where(
          (invoice) =>
              invoice.status.isFinalized &&
              previousRange.contains(_invoiceDate(invoice)),
        )
        .toList();

    final periodPayments = payments
        .where((payment) => range.contains(payment.receivedAt))
        .toList();
    final periodExpenses = expenses
        .where(
          (expense) =>
              expense.isActive && range.contains(expense.expenseDate),
        )
        .toList();

    final revenue = periodInvoices.fold<int>(
      0,
      (sum, invoice) => sum + invoice.grandTotalCents,
    );
    final previousRevenue = previousInvoices.fold<int>(
      0,
      (sum, invoice) => sum + invoice.grandTotalCents,
    );
    final paidOnInvoices = periodInvoices.fold<int>(
      0,
      (sum, invoice) => sum + invoice.amountPaidCents,
    );
    final paymentsReceived = periodPayments.fold<int>(
      0,
      (sum, payment) => sum + payment.amountCents,
    );
    final tax = periodInvoices.fold<int>(
      0,
      (sum, invoice) => sum + invoice.taxAmountCents,
    );
    final expenseTotal = periodExpenses.fold<int>(
      0,
      (sum, expense) => sum + expense.amountCents,
    );

    final outstandingInvoices = invoices
        .where((invoice) => invoice.hasOutstanding)
        .map(
          (invoice) => OutstandingInvoiceRow(
            invoice: invoice,
            daysOutstanding: _daysOutstanding(invoice, current),
          ),
        )
        .toList()
      ..sort((a, b) => b.daysOutstanding.compareTo(a.daysOutstanding));

    final outstanding = outstandingInvoices.fold<int>(
      0,
      (sum, row) => sum + row.invoice.balanceRemainingCents,
    );

    final invoiceTotals =
        periodInvoices.map((invoice) => invoice.grandTotalCents).toList();
    final averageInvoice = invoiceTotals.isEmpty
        ? 0
        : invoiceTotals.fold<int>(0, (sum, value) => sum + value) ~/
            invoiceTotals.length;
    final largest = invoiceTotals.isEmpty
        ? 0
        : invoiceTotals.reduce((a, b) => a > b ? a : b);
    final smallest = invoiceTotals.isEmpty
        ? 0
        : invoiceTotals.reduce((a, b) => a < b ? a : b);

    final snapshot = ReportSnapshot(
      period: period,
      range: range,
      revenueCents: revenue,
      paidOnInvoicesCents: paidOnInvoices,
      paymentsReceivedCents: paymentsReceived,
      outstandingCents: outstanding,
      taxCollectedCents: tax,
      expenseCents: expenseTotal,
      estimatedProfitCents: revenue - expenseTotal,
      invoiceCount: periodInvoices.length,
      paymentCount: periodPayments.length,
      averageInvoiceCents: averageInvoice,
      largestInvoiceCents: largest,
      smallestInvoiceCents: smallest,
      jobsCreated: jobs.where((job) => range.contains(job.createdAt)).length,
      jobsCompleted: jobs
          .where(
            (job) =>
                job.isCompleted &&
                job.completedAt != null &&
                range.contains(job.completedAt!),
          )
          .length,
      jobsCancelled: jobs
          .where(
            (job) => job.isCancelled && range.contains(job.updatedAt),
          )
          .length,
      upcomingJobs: jobs.where((job) {
        if (job.scheduledDate == null || job.isTerminal) return false;
        final startOfToday =
            DateTime(current.year, current.month, current.day);
        return !job.scheduledDate!.isBefore(startOfToday);
      }).length,
      newCustomers:
          customers.where((customer) => range.contains(customer.createdAt)).length,
      expensesByCategory: _expensesByCategory(periodExpenses),
      paymentsByMethod: _paymentsByMethod(periodPayments),
      topCustomers: _topCustomers(periodInvoices, invoices),
      outstandingInvoices: outstandingInvoices,
      monthlyTrend: _monthlyTrend(
        invoices: invoices,
        expenses: expenses,
        payments: payments,
        now: current,
      ),
      previousRevenueCents: previousRevenue,
      insights: const [],
    );

    return ReportSnapshot(
      period: snapshot.period,
      range: snapshot.range,
      revenueCents: snapshot.revenueCents,
      paidOnInvoicesCents: snapshot.paidOnInvoicesCents,
      paymentsReceivedCents: snapshot.paymentsReceivedCents,
      outstandingCents: snapshot.outstandingCents,
      taxCollectedCents: snapshot.taxCollectedCents,
      expenseCents: snapshot.expenseCents,
      estimatedProfitCents: snapshot.estimatedProfitCents,
      invoiceCount: snapshot.invoiceCount,
      paymentCount: snapshot.paymentCount,
      averageInvoiceCents: snapshot.averageInvoiceCents,
      largestInvoiceCents: snapshot.largestInvoiceCents,
      smallestInvoiceCents: snapshot.smallestInvoiceCents,
      jobsCreated: snapshot.jobsCreated,
      jobsCompleted: snapshot.jobsCompleted,
      jobsCancelled: snapshot.jobsCancelled,
      upcomingJobs: snapshot.upcomingJobs,
      newCustomers: snapshot.newCustomers,
      expensesByCategory: snapshot.expensesByCategory,
      paymentsByMethod: snapshot.paymentsByMethod,
      topCustomers: snapshot.topCustomers,
      outstandingInvoices: snapshot.outstandingInvoices,
      monthlyTrend: snapshot.monthlyTrend,
      previousRevenueCents: snapshot.previousRevenueCents,
      insights: buildInsights(snapshot),
    );
  }

  List<BusinessInsight> buildInsights(ReportSnapshot report) {
    final insights = <BusinessInsight>[];

    final change = report.revenueChangePercent;
    if (change != null && report.previousRevenueCents > 0) {
      final direction = change >= 0 ? 'increased' : 'decreased';
      insights.add(
        BusinessInsight(
          title: 'Revenue $direction',
          detail:
              '${change.abs().toStringAsFixed(0)}% compared to the previous period '
              '(${Money.formatZar(report.previousRevenueCents)} → ${Money.formatZar(report.revenueCents)}).',
          iconName: change >= 0 ? 'trending_up' : 'trending_down',
        ),
      );
    } else if (report.revenueCents > 0 && report.previousRevenueCents == 0) {
      insights.add(
        BusinessInsight(
          title: 'First revenue in this period',
          detail:
              'You recorded ${Money.formatZar(report.revenueCents)} in finalized invoices.',
          iconName: 'trending_up',
        ),
      );
    }

    if (report.outstandingCents > 0) {
      insights.add(
        BusinessInsight(
          title: 'Outstanding invoices',
          detail:
              '${Money.formatZar(report.outstandingCents)} still unpaid across '
              '${report.outstandingInvoices.length} invoice(s).',
          iconName: 'outstanding',
        ),
      );
    }

    if (report.averageInvoiceCents > 0) {
      insights.add(
        BusinessInsight(
          title: 'Average invoice',
          detail: Money.formatZar(report.averageInvoiceCents),
          iconName: 'average',
        ),
      );
    }

    if (report.topCustomers.isNotEmpty) {
      final top = report.topCustomers.first;
      insights.add(
        BusinessInsight(
          title: 'Highest paying customer',
          detail:
              '${top.customerName} — ${Money.formatZar(top.revenueCents)} this period.',
          iconName: 'customer',
        ),
      );
    }

    if (report.newCustomers > 0) {
      insights.add(
        BusinessInsight(
          title: 'New customers',
          detail: 'You gained ${report.newCustomers} new customer(s) this period.',
          iconName: 'customers',
        ),
      );
    }

    if (report.jobsCompleted > 0) {
      insights.add(
        BusinessInsight(
          title: 'Jobs completed',
          detail: '${report.jobsCompleted} job(s) completed this period.',
          iconName: 'jobs',
        ),
      );
    }

    if (insights.isEmpty) {
      insights.add(
        const BusinessInsight(
          title: 'No insights yet',
          detail:
              'Finalize invoices and record payments to unlock business insights.',
          iconName: 'empty',
        ),
      );
    }

    return insights;
  }

  DateTime _invoiceDate(Invoice invoice) {
    return invoice.finalizedAt ?? invoice.issueDate;
  }

  DateRange _previousRange(DateRange range) {
    final duration = range.endExclusive.difference(range.start);
    return DateRange(
      start: range.start.subtract(duration),
      endExclusive: range.start,
    );
  }

  int _daysOutstanding(Invoice invoice, DateTime now) {
    final anchor = invoice.dueDate ?? invoice.issueDate;
    final start = DateTime(anchor.year, anchor.month, anchor.day);
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(start).inDays;
    return days < 0 ? 0 : days;
  }

  List<CategoryTotal> _expensesByCategory(List<Expense> expenses) {
    final map = <ExpenseCategory, int>{};
    for (final expense in expenses) {
      map[expense.category] = (map[expense.category] ?? 0) + expense.amountCents;
    }
    final rows = map.entries
        .map(
          (entry) => CategoryTotal(
            category: entry.key,
            amountCents: entry.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.amountCents.compareTo(a.amountCents));
    return rows;
  }

  List<MethodTotal> _paymentsByMethod(List<Payment> payments) {
    final map = <PaymentMethod, int>{};
    for (final payment in payments) {
      map[payment.paymentMethod] =
          (map[payment.paymentMethod] ?? 0) + payment.amountCents;
    }
    final rows = map.entries
        .map(
          (entry) => MethodTotal(
            method: entry.key,
            amountCents: entry.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.amountCents.compareTo(a.amountCents));
    return rows;
  }

  List<CustomerRevenueRow> _topCustomers(
    List<Invoice> periodInvoices,
    List<Invoice> allInvoices,
  ) {
    final revenue = <String, int>{};
    final counts = <String, int>{};
    final names = <String, String>{};
    for (final invoice in periodInvoices) {
      revenue[invoice.customerId] =
          (revenue[invoice.customerId] ?? 0) + invoice.grandTotalCents;
      counts[invoice.customerId] = (counts[invoice.customerId] ?? 0) + 1;
      names[invoice.customerId] = invoice.customerName;
    }

    final outstanding = <String, int>{};
    for (final invoice in allInvoices.where((i) => i.hasOutstanding)) {
      outstanding[invoice.customerId] =
          (outstanding[invoice.customerId] ?? 0) + invoice.balanceRemainingCents;
    }

    final rows = revenue.entries
        .map(
          (entry) => CustomerRevenueRow(
            customerId: entry.key,
            customerName: names[entry.key]?.isNotEmpty == true
                ? names[entry.key]!
                : 'Customer',
            invoiceCount: counts[entry.key] ?? 0,
            revenueCents: entry.value,
            outstandingCents: outstanding[entry.key] ?? 0,
          ),
        )
        .toList()
      ..sort((a, b) => b.revenueCents.compareTo(a.revenueCents));
    return rows.take(5).toList();
  }

  List<MonthlyPoint> _monthlyTrend({
    required List<Invoice> invoices,
    required List<Expense> expenses,
    required List<Payment> payments,
    required DateTime now,
  }) {
    final points = <MonthlyPoint>[];
    for (var i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final start = DateTime(monthDate.year, monthDate.month, 1);
      final end = DateTime(monthDate.year, monthDate.month + 1, 1);
      final range = DateRange(start: start, endExclusive: end);

      final revenue = invoices
          .where(
            (invoice) =>
                invoice.status.isFinalized &&
                range.contains(_invoiceDate(invoice)),
          )
          .fold<int>(0, (sum, invoice) => sum + invoice.grandTotalCents);
      final expenseTotal = expenses
          .where(
            (expense) =>
                expense.isActive && range.contains(expense.expenseDate),
          )
          .fold<int>(0, (sum, expense) => sum + expense.amountCents);
      final paymentTotal = payments
          .where((payment) => range.contains(payment.receivedAt))
          .fold<int>(0, (sum, payment) => sum + payment.amountCents);

      points.add(
        MonthlyPoint(
          year: start.year,
          month: start.month,
          revenueCents: revenue,
          expenseCents: expenseTotal,
          paymentCents: paymentTotal,
        ),
      );
    }
    return points;
  }
}
