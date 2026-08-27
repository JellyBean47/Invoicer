import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_exception.dart';
import '../../../models/customer.dart';
import '../../../models/timeline_entry.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/customer_providers.dart';
import '../../../providers/invoice_providers.dart';
import '../../../providers/job_providers.dart';
import '../../../providers/quote_providers.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../invoices/widgets/invoice_card.dart';
import '../../jobs/widgets/job_card.dart';
import '../../quotes/widgets/quote_card.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerProvider(customerId));
    final timelineAsync = ref.watch(customerTimelineProvider(customerId));

    return customerAsync.when(
      loading: () => const Scaffold(
        body: AppLoading(message: 'Loading customer...'),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Customer')),
        body: Center(child: Text(error.toString())),
      ),
      data: (customer) {
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Customer')),
            body: const Center(child: Text('Customer not found.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(customer.name),
            actions: [
              IconButton(
                tooltip: 'Edit',
                onPressed: () =>
                    context.push('/customers/${customer.customerId}/edit'),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          floatingActionButton: customer.isActive
              ? FloatingActionButton.extended(
                  onPressed: () => context.push(
                    '/jobs/new?customerId=${customer.customerId}',
                  ),
                  icon: const Icon(Icons.handyman_outlined),
                  label: const Text('New Job'),
                )
              : null,
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              _Header(customer: customer),
              const SizedBox(height: AppSpacing.md),
              _ActionRow(
                customer: customer,
                onArchive: () => _confirmArchive(context, ref, customer),
                onRestore: () => _restore(context, ref, customer),
                onAddNote: () => _addNote(context, ref, customer),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _InfoCard(customer: customer),
              const SizedBox(height: AppSpacing.lg),
              _CustomerJobsSection(customerId: customer.customerId),
              const SizedBox(height: AppSpacing.lg),
              _CustomerQuotesSection(customerId: customer.customerId),
              const SizedBox(height: AppSpacing.lg),
              _CustomerInvoicesSection(customerId: customer.customerId),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Timeline',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              timelineAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Text(error.toString()),
                data: (entries) {
                  if (entries.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Text('No timeline events yet.'),
                      ),
                    );
                  }
                  return Column(
                    children: entries
                        .map((entry) => _TimelineTile(entry: entry))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 88),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmArchive(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Archive customer?'),
          content: Text(
            '${customer.name} will be hidden from active lists. '
            'Existing history stays available. New jobs, quotes, and invoices '
            'will be blocked until restored.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Archive'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    try {
      await ref.read(customerServiceProvider).archiveCustomer(
            userId: user.uid,
            customer: customer,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer archived')),
      );
    } on AppException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    try {
      await ref.read(customerServiceProvider).restoreCustomer(
            userId: user.uid,
            customer: customer,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer restored')),
      );
    } on AppException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _addNote(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add note'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Customer called. Needs leak repaired.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (note == null || !context.mounted) return;

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    try {
      await ref.read(customerServiceProvider).addNote(
            businessId: customer.businessId,
            userId: user.uid,
            customerId: customer.customerId,
            note: note,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note added')),
      );
    } on AppException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

}

class _CustomerQuotesSection extends ConsumerWidget {
  const _CustomerQuotesSection({required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotesAsync = ref.watch(customerQuotesProvider(customerId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Quotes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  context.push('/quotes/new?customerId=$customerId'),
              child: const Text('New quote'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        quotesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text(error.toString()),
          data: (quotes) {
            if (quotes.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Text('No quotes for this customer yet.'),
                ),
              );
            }
            return Column(
              children: quotes
                  .take(5)
                  .map(
                    (quote) => QuoteCard(
                      quote: quote,
                      onTap: () => context.push('/quotes/${quote.quoteId}'),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _CustomerInvoicesSection extends ConsumerWidget {
  const _CustomerInvoicesSection({required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(customerInvoicesProvider(customerId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Invoices',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  context.push('/invoices/new?customerId=$customerId'),
              child: const Text('New invoice'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        invoicesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text(error.toString()),
          data: (invoices) {
            if (invoices.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Text('No invoices for this customer yet.'),
                ),
              );
            }
            return Column(
              children: invoices
                  .take(5)
                  .map(
                    (invoice) => InvoiceCard(
                      invoice: invoice,
                      onTap: () =>
                          context.push('/invoices/${invoice.invoiceId}'),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _CustomerJobsSection extends ConsumerWidget {
  const _CustomerJobsSection({required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(customerJobsProvider(customerId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jobs',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        jobsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text(error.toString()),
          data: (jobs) {
            if (jobs.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Text('No jobs for this customer yet.'),
                ),
              );
            }
            return Column(
              children: jobs
                  .take(5)
                  .map(
                    (job) => JobCard(
                      job: job,
                      onTap: () => context.push('/jobs/${job.jobId}'),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    customer.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                customer.isArchived
                    ? StatusBadge.archived()
                    : StatusBadge.active(),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(customer.phone),
            if (customer.company.isNotEmpty) Text(customer.company),
            if (customer.isArchived) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Archived customers cannot receive new jobs, quotes, or invoices.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.warning,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.customer,
    required this.onArchive,
    required this.onRestore,
    required this.onAddNote,
  });

  final Customer customer;
  final VoidCallback onArchive;
  final VoidCallback onRestore;
  final VoidCallback onAddNote;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        OutlinedButton.icon(
          onPressed: onAddNote,
          icon: const Icon(Icons.note_add_outlined),
          label: const Text('Add note'),
        ),
        if (customer.isActive)
          OutlinedButton.icon(
            onPressed: onArchive,
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Archive'),
          )
        else
          FilledButton.icon(
            onPressed: onRestore,
            icon: const Icon(Icons.unarchive_outlined),
            label: const Text('Restore'),
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _InfoRow(label: 'Email', value: customer.email),
            _InfoRow(label: 'Address', value: customer.address),
            _InfoRow(label: 'Notes', value: customer.notes),
            _InfoRow(
              label: 'Created',
              value: DateFormat.yMMMd().format(customer.createdAt),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final display = value.trim().isEmpty ? '—' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Expanded(child: Text(display)),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.entry});

  final TimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM yyyy • HH:mm').format(entry.timestamp);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(_iconFor(entry.action), color: AppColors.primary),
        title: Text(entry.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.detail.isNotEmpty) Text(entry.detail),
            Text(
              date,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String action) {
    switch (action) {
      case 'customer_created':
        return Icons.person_add_alt_1_outlined;
      case 'customer_updated':
        return Icons.edit_outlined;
      case 'customer_archived':
        return Icons.archive_outlined;
      case 'customer_restored':
        return Icons.unarchive_outlined;
      case 'job_created':
        return Icons.handyman_outlined;
      case 'job_scheduled':
        return Icons.event_outlined;
      case 'job_started':
        return Icons.play_circle_outline;
      case 'job_completed':
        return Icons.check_circle_outline;
      case 'job_cancelled':
        return Icons.cancel_outlined;
      case 'job_updated':
        return Icons.edit_outlined;
      case 'quote_created':
      case 'quote_updated':
      case 'quote_sent':
      case 'quote_accepted':
      case 'quote_rejected':
      case 'quote_expired':
      case 'quote_converted':
        return Icons.request_quote_outlined;
      case 'invoice_created':
      case 'invoice_updated':
      case 'invoice_finalized':
      case 'invoice_cancelled':
      case 'invoice_duplicated':
        return Icons.receipt_long_outlined;
      case 'payment_recorded':
        return Icons.payments_outlined;
      case 'note':
        return Icons.sticky_note_2_outlined;
      default:
        return Icons.timeline;
    }
  }
}
