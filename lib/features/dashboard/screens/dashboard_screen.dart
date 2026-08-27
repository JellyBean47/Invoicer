import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';
import '../../../models/app_settings.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/invoice_providers.dart';
import '../../../providers/job_providers.dart';
import '../../../providers/notification_providers.dart';
import '../../../providers/payment_providers.dart';
import '../../../providers/report_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/sync_providers.dart';
import '../../../shared/widgets/app_loading.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapPhase10());
  }

  Future<void> _bootstrapPhase10() async {
    final profile = ref.read(userProfileProvider).valueOrNull;
    final businessId = profile?.businessId ?? '';
    if (businessId.isEmpty) return;

    try {
      final settings = await ref
          .read(settingsServiceProvider)
          .loadOrCreate(businessId);
      await ref
          .read(localNotificationServiceProvider)
          .syncDailyBriefingSchedule(settings);
      await ref.read(fcmServiceProvider).initialize(
        onForegroundMessage: (message) async {
          final title = message.notification?.title ?? 'Business Buddy';
          final body = message.notification?.body ?? '';
          await ref.read(notificationServiceProvider).createIfAllowed(
                businessId: businessId,
                title: title,
                message: body,
                type: NotificationType.system,
                bypassQuietHours: true,
              );
        },
      );

      final invoices = ref.read(invoicesProvider).valueOrNull ?? const [];
      await ref.read(invoiceMaintenanceServiceProvider).markOverdueInvoices(
            businessId: businessId,
            invoices: invoices,
          );

      final jobs = ref.read(jobsProvider).valueOrNull ?? const [];
      final payments = ref.read(paymentsProvider).valueOrNull ?? const [];
      final existing = (ref.read(notificationsProvider).valueOrNull ?? const [])
          .where((item) => item.type == NotificationType.briefing)
          .map((item) => item.entityId)
          .toSet();
      await ref.read(notificationServiceProvider).createDailyBriefing(
            businessId: businessId,
            ownerName: profile?.displayName ?? '',
            jobs: jobs,
            invoices: invoices,
            payments: payments,
            existingBriefingKeys: existing,
          );

      final online = await ref.read(connectivityServiceProvider).isOnline();
      if (online && settings.offlineEnabled) {
        await ref.read(syncServiceProvider).flush(
              businessId: businessId,
              notify: false,
            );
      }
    } catch (_) {
      // Bootstrap is best-effort; UI remains usable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessAsync = ref.watch(businessProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final moneyAsync = ref.watch(dashboardMoneyProvider);
    final todayAsync = ref.watch(dashboardTodayReportProvider);
    final reportAsync = ref.watch(dashboardReportProvider);
    final unread = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => ref.read(authServiceProvider).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: businessAsync.when(
        loading: () => const AppLoading(message: 'Loading dashboard...'),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (business) {
          final ownerName = profileAsync.valueOrNull?.displayName ?? 'there';
          final money = moneyAsync.valueOrNull;
          final today = todayAsync.valueOrNull;
          final report = reportAsync.valueOrNull;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              Text(
                'Good day, $ownerName',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                business?.businessName ?? 'Your business',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Today',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _StatCard(
                    label: 'Jobs completed',
                    value: '${today?.jobsCompleted ?? 0}',
                  ),
                  _StatCard(
                    label: 'Money received',
                    value: Money.formatZar(money?.receivedToday ?? 0),
                  ),
                  _StatCard(
                    label: 'Outstanding',
                    value: Money.formatZar(money?.outstanding ?? 0),
                  ),
                  _StatCard(
                    label: 'Upcoming jobs',
                    value: '${report?.upcomingJobs ?? 0}',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'This month',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/reports'),
                    child: const Text('View reports'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _StatCard(
                    label: 'Revenue',
                    value: Money.formatZar(report?.revenueCents ?? 0),
                  ),
                  _StatCard(
                    label: 'Expenses',
                    value: Money.formatZar(report?.expenseCents ?? 0),
                  ),
                  _StatCard(
                    label: 'Est. profit',
                    value: Money.formatZar(report?.estimatedProfitCents ?? 0),
                  ),
                  _StatCard(
                    label: 'Tax collected',
                    value: Money.formatZar(report?.taxCollectedCents ?? 0),
                  ),
                  _StatCard(
                    label: 'Invoices',
                    value: '${report?.invoiceCount ?? 0}',
                  ),
                  _StatCard(
                    label: 'New customers',
                    value: '${report?.newCustomers ?? 0}',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Insights',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (report == null || report.insights.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'Insights appear as you finalize invoices and record payments.',
                    ),
                  ),
                )
              else
                ...report.insights.take(3).map(
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
              Text(
                'Quick actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const _QuickActions(),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What needs attention?',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        (money?.outstanding ?? 0) > 0
                            ? 'You have ${Money.formatZar(money!.outstanding)} outstanding across unpaid invoices.'
                            : 'Nothing urgent. Create a customer, job, or invoice to keep things moving.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if ((money?.outstanding ?? 0) > 0)
                        FilledButton.icon(
                          onPressed: () => context.go('/invoices'),
                          icon: const Icon(Icons.receipt_long_outlined),
                          label: const Text('View Invoices'),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () => context.push('/customers/new'),
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('Create Customer'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionTile(
          icon: Icons.person_add_alt_1_outlined,
          label: 'New Customer',
          onTap: () => context.push('/customers/new'),
        ),
        _ActionTile(
          icon: Icons.handyman_outlined,
          label: 'New Job',
          onTap: () => context.push('/jobs/new'),
        ),
        _ActionTile(
          icon: Icons.request_quote_outlined,
          label: 'New Quote',
          onTap: () => context.push('/quotes/new'),
        ),
        _ActionTile(
          icon: Icons.receipt_long_outlined,
          label: 'New Invoice',
          onTap: () => context.push('/invoices/new'),
        ),
        _ActionTile(
          icon: Icons.account_balance_wallet_outlined,
          label: 'New Expense',
          onTap: () => context.push('/expenses/new'),
        ),
        _ActionTile(
          icon: Icons.bar_chart_outlined,
          label: 'Open Reports',
          onTap: () => context.go('/reports'),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
