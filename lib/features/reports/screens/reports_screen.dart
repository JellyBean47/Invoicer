import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';
import '../../../providers/report_providers.dart';
import '../../../providers/telemetry_providers.dart';
import '../../../services/reporting_service.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/empty_state.dart';
import '../widgets/simple_bar_chart.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _loggedView = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loggedView) return;
    _loggedView = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).logReportViewed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(reportPeriodProvider);
    final reportAsync = ref.watch(reportSnapshotProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(reportSnapshotProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reports refreshed from live data')),
              );
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              children: ReportPeriod.values.map((value) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(value.label),
                    selected: period == value,
                    onSelected: (_) async {
                      ref.read(reportPeriodProvider.notifier).state = value;
                      if (value == ReportPeriod.custom) {
                        await _pickCustomRange(context, ref);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          if (period == ReportPeriod.custom)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                0,
                AppSpacing.screen,
                AppSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _pickCustomRange(context, ref),
                  icon: const Icon(Icons.date_range),
                  label: Text(_customRangeLabel(ref)),
                ),
              ),
            ),
          Expanded(
            child: reportAsync.when(
              loading: () => const AppLoading(message: 'Building reports...'),
              error: (error, _) => Center(child: Text(error.toString())),
              data: (report) {
                if (report.invoiceCount == 0 &&
                    report.paymentCount == 0 &&
                    report.expenseCents == 0 &&
                    report.jobsCompleted == 0) {
                  return EmptyState(
                    title: 'No report data yet',
                    message:
                        'Create invoices to begin tracking income, tax, and profit.',
                    actionLabel: 'New Invoice',
                    onAction: () => context.push('/invoices/new'),
                    icon: Icons.bar_chart_outlined,
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  children: [
                    Text(
                      _rangeLabel(report.range),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Totals are calculated automatically and cannot be edited.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _sectionTitle(context, 'Summary'),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _MetricCard(
                          label: 'Revenue',
                          value: Money.formatZar(report.revenueCents),
                        ),
                        _MetricCard(
                          label: 'Payments',
                          value: Money.formatZar(report.paymentsReceivedCents),
                        ),
                        _MetricCard(
                          label: 'Expenses',
                          value: Money.formatZar(report.expenseCents),
                        ),
                        _MetricCard(
                          label: 'Est. profit',
                          value: Money.formatZar(report.estimatedProfitCents),
                        ),
                        _MetricCard(
                          label: 'Tax collected',
                          value: Money.formatZar(report.taxCollectedCents),
                        ),
                        _MetricCard(
                          label: 'Outstanding',
                          value: Money.formatZar(report.outstandingCents),
                        ),
                        _MetricCard(
                          label: 'Invoices',
                          value: '${report.invoiceCount}',
                        ),
                        _MetricCard(
                          label: 'Avg invoice',
                          value: Money.formatZar(report.averageInvoiceCents),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _sectionTitle(context, '6-month trend'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: SimpleBarChart(points: report.monthlyTrend),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _sectionTitle(context, 'Insights'),
                    ...report.insights.map(
                      (insight) => Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ListTile(
                          leading: Icon(_insightIcon(insight.iconName)),
                          title: Text(insight.title),
                          subtitle: Text(insight.detail),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _sectionTitle(context, 'Outstanding'),
                    if (report.outstandingInvoices.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Text('No outstanding invoices.'),
                        ),
                      )
                    else
                      ...report.outstandingInvoices.take(8).map((row) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ListTile(
                            onTap: () => context.push(
                              '/invoices/${row.invoice.invoiceId}',
                            ),
                            title: Text(row.invoice.invoiceNumber),
                            subtitle: Text(
                              '${row.invoice.customerName} · '
                              '${row.daysOutstanding} day(s)',
                            ),
                            trailing: Text(
                              Money.formatZar(
                                row.invoice.balanceRemainingCents,
                              ),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: AppSpacing.lg),
                    _sectionTitle(context, 'Expenses by category'),
                    if (report.expensesByCategory.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Text('No expenses in this period.'),
                        ),
                      )
                    else
                      ...report.expensesByCategory.map((row) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ListTile(
                            leading: Icon(row.category.icon),
                            title: Text(row.category.label),
                            trailing: Text(
                              Money.formatZar(row.amountCents),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: AppSpacing.lg),
                    _sectionTitle(context, 'Payments by method'),
                    if (report.paymentsByMethod.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Text('No payments in this period.'),
                        ),
                      )
                    else
                      ...report.paymentsByMethod.map((row) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ListTile(
                            leading: Icon(row.method.icon),
                            title: Text(row.method.label),
                            trailing: Text(
                              Money.formatZar(row.amountCents),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: AppSpacing.lg),
                    _sectionTitle(context, 'Top customers'),
                    if (report.topCustomers.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Text('No customer revenue in this period.'),
                        ),
                      )
                    else
                      ...report.topCustomers.map((row) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ListTile(
                            onTap: () =>
                                context.push('/customers/${row.customerId}'),
                            title: Text(row.customerName),
                            subtitle: Text(
                              '${row.invoiceCount} invoice(s)'
                              '${row.outstandingCents > 0 ? ' · Outstanding ${Money.formatZar(row.outstandingCents)}' : ''}',
                            ),
                            trailing: Text(
                              Money.formatZar(row.revenueCents),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: AppSpacing.lg),
                    _sectionTitle(context, 'Jobs'),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _MetricCard(
                          label: 'Created',
                          value: '${report.jobsCreated}',
                        ),
                        _MetricCard(
                          label: 'Completed',
                          value: '${report.jobsCompleted}',
                        ),
                        _MetricCard(
                          label: 'Cancelled',
                          value: '${report.jobsCancelled}',
                        ),
                        _MetricCard(
                          label: 'Upcoming',
                          value: '${report.upcomingJobs}',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  String _rangeLabel(DateRange range) {
    final formatter = DateFormat('d MMM yyyy');
    final endInclusive = range.endExclusive.subtract(const Duration(days: 1));
    return '${formatter.format(range.start)} – ${formatter.format(endInclusive)}';
  }

  String _customRangeLabel(WidgetRef ref) {
    final start = ref.watch(reportCustomStartProvider);
    final end = ref.watch(reportCustomEndProvider);
    if (start == null || end == null) return 'Choose dates';
    final formatter = DateFormat('d MMM yyyy');
    return '${formatter.format(start)} – ${formatter.format(end)}';
  }

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final initialStart = ref.read(reportCustomStartProvider) ??
        DateTime(now.year, now.month, 1);
    final initialEnd = ref.read(reportCustomEndProvider) ?? now;

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    );
    if (range == null) return;
    ref.read(reportCustomStartProvider.notifier).state = range.start;
    ref.read(reportCustomEndProvider.notifier).state = range.end;
    ref.read(reportPeriodProvider.notifier).state = ReportPeriod.custom;
  }

  IconData _insightIcon(String name) {
    switch (name) {
      case 'trending_up':
        return Icons.trending_up;
      case 'trending_down':
        return Icons.trending_down;
      case 'outstanding':
        return Icons.warning_amber_outlined;
      case 'average':
        return Icons.calculate_outlined;
      case 'customer':
        return Icons.emoji_events_outlined;
      case 'customers':
        return Icons.person_add_alt_1_outlined;
      case 'jobs':
        return Icons.handyman_outlined;
      default:
        return Icons.lightbulb_outline;
    }
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - (AppSpacing.screen * 2) - 8) /
          2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
