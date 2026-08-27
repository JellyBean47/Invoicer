import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_exception.dart';
import '../../../core/utils/money.dart';
import '../../../models/invoice.dart';
import '../../../models/payment.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/invoice_providers.dart';
import '../../../providers/payment_providers.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/status_badge.dart';

class InvoiceDetailsScreen extends ConsumerStatefulWidget {
  const InvoiceDetailsScreen({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  ConsumerState<InvoiceDetailsScreen> createState() =>
      _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends ConsumerState<InvoiceDetailsScreen> {
  bool _sharingPdf = false;

  @override
  Widget build(BuildContext context) {
    final invoiceAsync = ref.watch(invoiceProvider(widget.invoiceId));
    final paymentsAsync = ref.watch(invoicePaymentsProvider(widget.invoiceId));

    return invoiceAsync.when(
      loading: () => const Scaffold(
        body: AppLoading(message: 'Loading invoice...'),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Invoice')),
        body: Center(child: Text(error.toString())),
      ),
      data: (invoice) {
        if (invoice == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Invoice')),
            body: const Center(child: Text('Invoice not found.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(invoice.invoiceNumber),
            actions: [
              if (invoice.status.isFinalized)
                IconButton(
                  tooltip: 'Share PDF',
                  onPressed: _sharingPdf ? null : () => _sharePdf(invoice),
                  icon: _sharingPdf
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined),
                ),
              if (invoice.status.isEditable)
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () =>
                      context.push('/invoices/${invoice.invoiceId}/edit'),
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          body: Stack(
            children: [
              ListView(
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
                                  invoice.customerName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              StatusBadge(
                                label: invoice.status.label,
                                color: invoice.status.color,
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () =>
                                context.push('/customers/${invoice.customerId}'),
                            child: const Text('View customer'),
                          ),
                          if (invoice.jobId.isNotEmpty)
                            TextButton(
                              onPressed: () =>
                                  context.push('/jobs/${invoice.jobId}'),
                              child: const Text('View linked job'),
                            ),
                          if (invoice.isLocked)
                            Text(
                              'This invoice is locked. Duplicate it to make a correction.',
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
                          ...invoice.items.map(
                            (item) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                          _totalRow(context, 'Subtotal', invoice.subtotalCents),
                          _totalRow(context, 'Discount', invoice.discountCents),
                          _totalRow(
                            context,
                            'Tax (${invoice.taxPercent}%)',
                            invoice.taxAmountCents,
                          ),
                          _totalRow(
                            context,
                            'Grand total',
                            invoice.grandTotalCents,
                            emphasize: true,
                          ),
                          if (invoice.status.isFinalized) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _totalRow(
                              context,
                              'Amount paid',
                              invoice.amountPaidCents,
                            ),
                            _totalRow(
                              context,
                              'Balance remaining',
                              invoice.balanceRemainingCents,
                              emphasize: true,
                            ),
                          ],
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
                            'Issue: ${DateFormat.yMMMd().format(invoice.issueDate)}',
                          ),
                          Text(
                            'Due: ${invoice.dueDate == null ? '—' : DateFormat.yMMMd().format(invoice.dueDate!)}',
                          ),
                          if (invoice.finalizedAt != null)
                            Text(
                              'Finalized: ${DateFormat.yMMMd().format(invoice.finalizedAt!)}',
                            ),
                          if (invoice.notes.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(invoice.notes),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (invoice.status.canFinalize)
                    FilledButton.icon(
                      onPressed: () => _finalize(invoice),
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Finalize Invoice'),
                    ),
                  if (invoice.status.canCancel) ...[
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: () => _cancel(invoice),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel Draft'),
                    ),
                  ],
                  if (invoice.status.isFinalized) ...[
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: _sharingPdf ? null : () => _sharePdf(invoice),
                      icon: const Icon(Icons.share_outlined),
                      label: Text(
                        _sharingPdf ? 'Preparing PDF...' : 'Share PDF Invoice',
                      ),
                    ),
                  ],
                  if (invoice.canRecordPayment) ...[
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: () => context.push(
                        '/invoices/${invoice.invoiceId}/pay',
                      ),
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Record Payment'),
                    ),
                  ],
                  if (invoice.status.canDuplicate) ...[
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton.tonalIcon(
                      onPressed: () => _duplicate(invoice),
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('Duplicate for Correction'),
                    ),
                  ],
                  if (invoice.status.isFinalized) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Payments',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    paymentsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => Text(error.toString()),
                      data: (payments) {
                        if (payments.isEmpty) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: Text('No payments recorded yet.'),
                            ),
                          );
                        }
                        return Column(
                          children: payments
                              .map((payment) => _PaymentTile(payment: payment))
                              .toList(),
                        );
                      },
                    ),
                  ],
                ],
              ),
              if (_sharingPdf)
                const ModalBarrier(
                  dismissible: false,
                  color: Color(0x33000000),
                ),
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

  Future<void> _sharePdf(Invoice invoice) async {
    if (_sharingPdf) return;
    setState(() => _sharingPdf = true);
    try {
      await ref
          .read(invoicePdfServiceProvider)
          .shareInvoicePdfById(invoice.invoiceId);
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to share PDF: $error')),
      );
    } finally {
      if (mounted) setState(() => _sharingPdf = false);
    }
  }

  Future<void> _finalize(Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalize invoice?'),
        content: Text(
          '${invoice.invoiceNumber} will become a permanent financial record '
          'and cannot be edited. Corrections require duplicating to a new draft.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Draft'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finalize'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    try {
      await ref.read(invoiceServiceProvider).finalizeInvoice(
            userId: user.uid,
            invoice: invoice,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice finalized')),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _cancel(Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel draft?'),
        content: Text(
          'Mark ${invoice.invoiceNumber} as cancelled? '
          'Cancelled invoices remain in history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Invoice'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    try {
      await ref.read(invoiceServiceProvider).cancelInvoice(
            userId: user.uid,
            invoice: invoice,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice cancelled')),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _duplicate(Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate for correction?'),
        content: Text(
          'Create a new draft from ${invoice.invoiceNumber}. '
          'The original invoice stays unchanged with its number preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Duplicate'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    try {
      final created = await ref.read(invoiceServiceProvider).duplicateInvoice(
            userId: user.uid,
            source: invoice,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created ${created.invoiceNumber}')),
      );
      context.go('/invoices/${created.invoiceId}/edit');
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(payment.paymentMethod.icon),
        title: Text(Money.formatZar(payment.amountCents)),
        subtitle: Text(
          [
            payment.paymentMethod.label,
            DateFormat.yMMMd().format(payment.receivedAt),
            if (payment.reference.isNotEmpty) payment.reference,
          ].join(' · '),
        ),
      ),
    );
  }
}
