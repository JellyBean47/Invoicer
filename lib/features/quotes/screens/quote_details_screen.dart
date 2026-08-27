import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_exception.dart';
import '../../../core/utils/money.dart';
import '../../../models/quote.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/quote_providers.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/status_badge.dart';

class QuoteDetailsScreen extends ConsumerWidget {
  const QuoteDetailsScreen({super.key, required this.quoteId});

  final String quoteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsync = ref.watch(quoteProvider(quoteId));

    return quoteAsync.when(
      loading: () => const Scaffold(
        body: AppLoading(message: 'Loading quote...'),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Quote')),
        body: Center(child: Text(error.toString())),
      ),
      data: (quote) {
        if (quote == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Quote')),
            body: const Center(child: Text('Quote not found.')),
          );
        }

        final transitions =
            ref.watch(quoteServiceProvider).availableTransitions(quote.status);

        return Scaffold(
          appBar: AppBar(
            title: Text(quote.quoteNumber),
            actions: [
              if (quote.status.isEditable)
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () =>
                      context.push('/quotes/${quote.quoteId}/edit'),
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              quote.customerName,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          StatusBadge(
                            label: quote.status.label,
                            color: quote.status.color,
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () =>
                            context.push('/customers/${quote.customerId}'),
                        child: const Text('View customer'),
                      ),
                      Text(
                        'Quotes do not affect revenue or reports.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Line items',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...quote.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.description),
                                    Text(
                                      '${item.quantity} × ${Money.formatZar(item.unitPriceCents)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(Money.formatZar(item.lineTotalCents)),
                            ],
                          ),
                        ),
                      ),
                      const Divider(),
                      _totalRow(context, 'Subtotal', quote.subtotalCents),
                      _totalRow(context, 'Discount', quote.discountCents),
                      _totalRow(
                        context,
                        'Tax (${quote.taxPercent}%)',
                        quote.taxAmountCents,
                      ),
                      _totalRow(
                        context,
                        'Total',
                        quote.totalCents,
                        emphasize: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expiry: ${quote.expiryDate == null ? '—' : DateFormat.yMMMd().format(quote.expiryDate!)}',
                      ),
                      if (quote.notes.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(quote.notes),
                      ],
                      if (quote.hasConvertedJob) ...[
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                          onPressed: () =>
                              context.push('/jobs/${quote.convertedJobId}'),
                          child: const Text('Open converted job'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Update status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (transitions.isEmpty)
                const Text('No further status changes are available.')
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: transitions
                      .map(
                        (status) => FilledButton.tonal(
                          onPressed: () =>
                              _transition(context, ref, quote, status),
                          child: Text(status.label),
                        ),
                      )
                      .toList(),
                ),
              if (quote.status == QuoteStatus.accepted ||
                  quote.status == QuoteStatus.draft ||
                  quote.status == QuoteStatus.sent) ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: quote.hasConvertedJob
                      ? () => context.push('/jobs/${quote.convertedJobId}')
                      : () => _convert(context, ref, quote),
                  icon: const Icon(Icons.handyman_outlined),
                  label: Text(
                    quote.hasConvertedJob
                        ? 'Open converted job'
                        : 'Convert to Job',
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _totalRow(
    BuildContext context,
    String label,
    int cents, {
    bool emphasize = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            Money.formatZar(cents),
            style: emphasize
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    )
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _transition(
    BuildContext context,
    WidgetRef ref,
    Quote quote,
    QuoteStatus nextStatus,
  ) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    try {
      await ref.read(quoteServiceProvider).transitionStatus(
            userId: user.uid,
            quote: quote,
            nextStatus: nextStatus,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quote marked ${nextStatus.label}')),
      );
    } on AppException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _convert(
    BuildContext context,
    WidgetRef ref,
    Quote quote,
  ) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convert to job?'),
        content: Text(
          'Create a job from ${quote.quoteNumber} for ${quote.customerName}? '
          'Customer and quote details will be carried over.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Convert'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final job = await ref.read(quoteServiceProvider).convertToJob(
            userId: user.uid,
            quote: quote,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created ${job.jobNumber}')),
      );
      context.go('/jobs/${job.jobId}');
    } on AppException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }
}
