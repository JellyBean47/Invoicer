import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_exception.dart';
import '../../../core/utils/money.dart';
import '../../../models/invoice.dart';
import '../../../models/payment.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/invoice_providers.dart';
import '../../../providers/payment_providers.dart';
import '../../../services/payment_service.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/primary_button.dart';

class RecordPaymentScreen extends ConsumerStatefulWidget {
  const RecordPaymentScreen({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  ConsumerState<RecordPaymentScreen> createState() =>
      _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends ConsumerState<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  PaymentMethod _method = PaymentMethod.cash;
  DateTime _receivedAt = DateTime.now();
  bool _isLoading = false;
  bool _amountPrefillDone = false;

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _receivedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    setState(() {
      _receivedAt = DateTime(
        date.year,
        date.month,
        date.day,
        _receivedAt.hour,
        _receivedAt.minute,
      );
    });
  }

  Future<void> _submit(int outstandingCents) async {
    if (!_formKey.currentState!.validate()) return;

    final amount = Money.tryParseRandToCents(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid payment amount.')),
      );
      return;
    }
    if (amount > outstandingCents) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Amount cannot exceed ${Money.formatZar(outstandingCents)}.',
          ),
        ),
      );
      return;
    }

    final user = ref.read(authStateProvider).valueOrNull;
    final invoice = ref.read(invoiceProvider(widget.invoiceId)).valueOrNull;
    if (user == null || invoice == null) return;

    setState(() => _isLoading = true);
    try {
      final payment = await ref.read(paymentServiceProvider).recordPayment(
            userId: user.uid,
            invoice: invoice,
            input: PaymentInput(
              amountCents: amount,
              paymentMethod: _method,
              receivedAt: _receivedAt,
              reference: _referenceController.text,
              notes: _notesController.text,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Recorded ${Money.formatZar(payment.amountCents)} '
            '(${payment.paymentMethod.label})',
          ),
        ),
      );
      context.pop();
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoiceAsync = ref.watch(invoiceProvider(widget.invoiceId));

    return invoiceAsync.when(
      loading: () => const Scaffold(
        body: AppLoading(message: 'Loading invoice...'),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Record Payment')),
        body: Center(child: Text(error.toString())),
      ),
      data: (invoice) {
        if (invoice == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Record Payment')),
            body: const Center(child: Text('Invoice not found.')),
          );
        }
        if (!invoice.canRecordPayment) {
          final message = invoice.status == InvoiceStatus.paid
              ? 'This invoice is already fully paid.'
              : 'Payments can only be recorded on unpaid finalized invoices.';
          return Scaffold(
            appBar: AppBar(title: const Text('Record Payment')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: Text(message, textAlign: TextAlign.center),
              ),
            ),
          );
        }

        if (!_amountPrefillDone) {
          _amountPrefillDone = true;
          _amountController.text =
              (invoice.balanceRemainingCents / 100).toStringAsFixed(2);
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Record Payment')),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: [
                  Text(
                    invoice.invoiceNumber,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(invoice.customerName),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Outstanding: ${Money.formatZar(invoice.balanceRemainingCents)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (R)',
                      prefixIcon: Icon(Icons.payments_outlined),
                      helperText: 'Cannot exceed outstanding balance.',
                    ),
                    validator: (value) {
                      final cents = Money.tryParseRandToCents(value ?? '');
                      if (cents == null || cents <= 0) {
                        return 'Enter an amount greater than zero';
                      }
                      if (cents > invoice.balanceRemainingCents) {
                        return 'Exceeds outstanding balance';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Payment method',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: PaymentMethod.values.map((method) {
                      return ChoiceChip(
                        avatar: Icon(method.icon, size: 18),
                        label: Text(method.label),
                        selected: _method == method,
                        onSelected: (_) => setState(() => _method = method),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: Text(
                      'Received: ${DateFormat('d MMM yyyy').format(_receivedAt)}',
                    ),
                    trailing: IconButton(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.edit_calendar_outlined),
                    ),
                  ),
                  TextFormField(
                    controller: _referenceController,
                    decoration: const InputDecoration(
                      labelText: 'Reference (optional)',
                      prefixIcon: Icon(Icons.tag_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: 'Save Payment',
                    isLoading: _isLoading,
                    onPressed: () => _submit(invoice.balanceRemainingCents),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Payments cannot be edited or deleted after saving.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
