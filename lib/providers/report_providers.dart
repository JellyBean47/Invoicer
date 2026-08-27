import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/reporting_service.dart';
import 'customer_providers.dart';
import 'expense_providers.dart';
import 'invoice_providers.dart';
import 'job_providers.dart';
import 'payment_providers.dart';

final reportingServiceProvider = Provider<ReportingService>((ref) {
  return const ReportingService();
});

final reportPeriodProvider =
    StateProvider<ReportPeriod>((ref) => ReportPeriod.thisMonth);

final reportCustomStartProvider = StateProvider<DateTime?>((ref) => null);
final reportCustomEndProvider = StateProvider<DateTime?>((ref) => null);

final reportSnapshotProvider = Provider<AsyncValue<ReportSnapshot>>((ref) {
  final period = ref.watch(reportPeriodProvider);
  final customStart = ref.watch(reportCustomStartProvider);
  final customEnd = ref.watch(reportCustomEndProvider);
  final service = ref.watch(reportingServiceProvider);

  final invoicesAsync = ref.watch(invoicesProvider);
  final paymentsAsync = ref.watch(paymentsProvider);
  final expensesAsync = ref.watch(expensesProvider);
  final jobsAsync = ref.watch(jobsProvider);
  final customersAsync = ref.watch(customersProvider);

  final asyncs = [
    invoicesAsync,
    paymentsAsync,
    expensesAsync,
    jobsAsync,
    customersAsync,
  ];
  if (asyncs.any((value) => value.isLoading)) {
    return const AsyncValue.loading();
  }
  for (final value in asyncs) {
    if (value.hasError) {
      return AsyncValue.error(value.error!, value.stackTrace!);
    }
  }

  final snapshot = service.build(
    period: period,
    invoices: invoicesAsync.valueOrNull ?? const [],
    payments: paymentsAsync.valueOrNull ?? const [],
    expenses: expensesAsync.valueOrNull ?? const [],
    jobs: jobsAsync.valueOrNull ?? const [],
    customers: customersAsync.valueOrNull ?? const [],
    customStart: customStart,
    customEndInclusive: customEnd,
  );
  return AsyncValue.data(snapshot);
});

AsyncValue<ReportSnapshot> _buildDashboardReport(
  Ref ref,
  ReportPeriod period,
) {
  final service = ref.watch(reportingServiceProvider);
  final invoicesAsync = ref.watch(invoicesProvider);
  final paymentsAsync = ref.watch(paymentsProvider);
  final expensesAsync = ref.watch(expensesProvider);
  final jobsAsync = ref.watch(jobsProvider);
  final customersAsync = ref.watch(customersProvider);

  final asyncs = [
    invoicesAsync,
    paymentsAsync,
    expensesAsync,
    jobsAsync,
    customersAsync,
  ];
  if (asyncs.any((value) => value.isLoading)) {
    return const AsyncValue.loading();
  }
  for (final value in asyncs) {
    if (value.hasError) {
      return AsyncValue.error(value.error!, value.stackTrace!);
    }
  }

  return AsyncValue.data(
    service.build(
      period: period,
      invoices: invoicesAsync.valueOrNull ?? const [],
      payments: paymentsAsync.valueOrNull ?? const [],
      expenses: expensesAsync.valueOrNull ?? const [],
      jobs: jobsAsync.valueOrNull ?? const [],
      customers: customersAsync.valueOrNull ?? const [],
    ),
  );
}

final dashboardReportProvider = Provider<AsyncValue<ReportSnapshot>>((ref) {
  return _buildDashboardReport(ref, ReportPeriod.thisMonth);
});

final dashboardTodayReportProvider =
    Provider<AsyncValue<ReportSnapshot>>((ref) {
  return _buildDashboardReport(ref, ReportPeriod.today);
});
