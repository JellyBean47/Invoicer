import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_exception.dart';
import '../../../core/utils/money.dart';
import '../../../models/customer.dart';
import '../../../models/invoice.dart';
import '../../../models/invoice_item.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/customer_providers.dart';
import '../../../providers/invoice_providers.dart';
import '../../../providers/job_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../services/invoice_service.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/primary_button.dart';

class _LineDraft {
  _LineDraft({
    String description = '',
    int quantity = 1,
    int unitPriceCents = 0,
  })  : descriptionController = TextEditingController(text: description),
        quantityController = TextEditingController(text: '$quantity'),
        priceController = TextEditingController(
          text: unitPriceCents == 0
              ? ''
              : (unitPriceCents / 100).toStringAsFixed(2),
        );

  final TextEditingController descriptionController;
  final TextEditingController quantityController;
  final TextEditingController priceController;

  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    priceController.dispose();
  }
}

class InvoiceFormScreen extends ConsumerStatefulWidget {
  const InvoiceFormScreen({
    super.key,
    this.invoiceId,
    this.initialCustomerId,
    this.initialJobId,
  });

  final String? invoiceId;
  final String? initialCustomerId;
  final String? initialJobId;

  bool get isEditing => invoiceId != null;

  @override
  ConsumerState<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _taxController = TextEditingController();
  final _lines = <_LineDraft>[_LineDraft()];

  String? _customerId;
  String? _jobId;
  DateTime _issueDate = DateTime.now();
  DateTime? _dueDate;
  bool _isLoading = false;
  bool _hydrated = false;
  bool _jobPrefillApplied = false;
  Invoice? _existing;

  @override
  void initState() {
    super.initState();
    _customerId = widget.initialCustomerId;
    _jobId = widget.initialJobId;
    final today = DateTime.now();
    _issueDate = DateTime(today.year, today.month, today.day);
    _dueDate = _issueDate.add(const Duration(days: 14));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final business = ref.read(businessProvider).valueOrNull;
      final settings = ref.read(appSettingsProvider).valueOrNull;
      if (_taxController.text.isEmpty) {
        _taxController.text =
            '${settings?.defaultTaxPercent ?? business?.defaultTaxPercent ?? 15}';
      }
      if (!widget.isEditing) {
        final terms = settings?.paymentTermsDays ?? 14;
        setState(() {
          _dueDate = _issueDate.add(Duration(days: terms));
        });
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  void _hydrate(Invoice invoice) {
    if (_hydrated) return;
    _existing = invoice;
    _customerId = invoice.customerId;
    _jobId = invoice.jobId.isEmpty ? null : invoice.jobId;
    _notesController.text = invoice.notes;
    _discountController.text = (invoice.discountCents / 100).toStringAsFixed(2);
    _taxController.text = '${invoice.taxPercent}';
    _issueDate = invoice.issueDate;
    _dueDate = invoice.dueDate;
    for (final line in _lines) {
      line.dispose();
    }
    _lines
      ..clear()
      ..addAll(
        invoice.items.isEmpty
            ? [_LineDraft()]
            : invoice.items.map(
                (item) => _LineDraft(
                  description: item.description,
                  quantity: item.quantity,
                  unitPriceCents: item.unitPriceCents,
                ),
              ),
      );
    _hydrated = true;
  }

  MoneyBreakdown? _previewTotals() {
    try {
      final lines = <int>[];
      for (final line in _lines) {
        final qty = int.tryParse(line.quantityController.text.trim()) ?? 0;
        final price =
            Money.tryParseRandToCents(line.priceController.text) ?? -1;
        if (qty <= 0 || price < 0) return null;
        lines.add(Money.lineTotal(quantity: qty, unitPriceCents: price));
      }
      final discount =
          Money.tryParseRandToCents(_discountController.text) ?? 0;
      final tax = int.tryParse(_taxController.text.trim()) ?? 0;
      return Money.calculate(
        lineTotalsCents: lines,
        discountCents: discount,
        taxPercent: tax,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickIssueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _issueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    setState(() => _issueDate = date);
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? _issueDate.add(const Duration(days: 14)),
      firstDate: _issueDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;
    setState(() => _dueDate = date);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_customerId == null || _customerId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a customer.')),
      );
      return;
    }

    final profile = ref.read(userProfileProvider).valueOrNull;
    final user = ref.read(authStateProvider).valueOrNull;
    if (profile == null || user == null) return;

    final lineInputs = <InvoiceLineInput>[];
    for (final line in _lines) {
      final qty = int.tryParse(line.quantityController.text.trim());
      final price = Money.tryParseRandToCents(line.priceController.text);
      if (qty == null || qty <= 0 || price == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check quantity and price on every line.'),
          ),
        );
        return;
      }
      lineInputs.add(
        InvoiceLineInput(
          description: line.descriptionController.text,
          quantity: qty,
          unitPriceCents: price,
        ),
      );
    }

    final discount = Money.tryParseRandToCents(_discountController.text) ?? 0;
    final tax = int.tryParse(_taxController.text.trim());
    if (tax == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid tax percentage.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final input = InvoiceInput(
        customerId: _customerId!,
        jobId: _jobId ?? '',
        lines: lineInputs,
        taxPercent: tax,
        discountCents: discount,
        notes: _notesController.text,
        issueDate: _issueDate,
        dueDate: _dueDate,
      );

      if (widget.isEditing) {
        final existing = _existing;
        if (existing == null) return;
        await ref.read(invoiceServiceProvider).updateInvoice(
              userId: user.uid,
              existing: existing,
              input: input,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice saved')),
        );
        context.pop();
      } else {
        final created = await ref.read(invoiceServiceProvider).createInvoice(
              businessId: profile.businessId,
              userId: user.uid,
              input: input,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice ${created.invoiceNumber} created')),
        );
        context.go('/invoices/${created.invoiceId}');
      }
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
    if (widget.isEditing) {
      final invoiceAsync = ref.watch(invoiceProvider(widget.invoiceId!));
      return invoiceAsync.when(
        loading: () => const Scaffold(
          body: AppLoading(message: 'Loading invoice...'),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit Invoice')),
          body: Center(child: Text(error.toString())),
        ),
        data: (invoice) {
          if (invoice == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit Invoice')),
              body: const Center(child: Text('Invoice not found.')),
            );
          }
          if (!invoice.status.isEditable) {
            return Scaffold(
              appBar: AppBar(title: Text(invoice.invoiceNumber)),
              body: const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.screen),
                  child: Text(
                    'Final invoices cannot be edited. Duplicate the invoice to create a correction draft.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }
          _hydrate(invoice);
          return _buildForm(context);
        },
      );
    }

    final jobId = widget.initialJobId;
    if (jobId != null && jobId.isNotEmpty) {
      ref.listen(jobProvider(jobId), (previous, next) {
        final job = next.valueOrNull;
        if (job == null || _jobPrefillApplied) return;
        setState(() {
          _jobPrefillApplied = true;
          _customerId = job.customerId;
          _jobId = job.jobId;
          if (_lines.length == 1 &&
              _lines.first.descriptionController.text.trim().isEmpty) {
            _lines.first.descriptionController.text = job.title;
          }
        });
      });
    }
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final activeCustomers = customersAsync.maybeWhen(
      data: (customers) => customers
          .where((customer) => customer.status == CustomerStatus.active)
          .toList(),
      orElse: () => <Customer>[],
    );
    final totals = _previewTotals();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Invoice' : 'New Invoice'),
      ),
      body: SafeArea(
        child: customersAsync.isLoading
            ? const AppLoading(message: 'Loading customers...')
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  children: [
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _customerId != null &&
                              (activeCustomers.any(
                                    (c) => c.customerId == _customerId,
                                  ) ||
                                  _existing?.customerId == _customerId)
                          ? _customerId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Customer',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: [
                        if (widget.isEditing && _existing != null)
                          DropdownMenuItem(
                            value: _existing!.customerId,
                            child: Text(_existing!.customerName),
                          ),
                        ...activeCustomers.map(
                          (customer) => DropdownMenuItem(
                            value: customer.customerId,
                            child: Text(customer.name),
                          ),
                        ),
                      ],
                      onChanged: widget.isEditing
                          ? null
                          : (value) => setState(() => _customerId = value),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Customer is required'
                          : null,
                    ),
                    if (_jobId != null && _jobId!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.handyman_outlined),
                        title: const Text('Linked job'),
                        subtitle: Text(_jobId!),
                        trailing: widget.isEditing
                            ? null
                            : IconButton(
                                onPressed: () =>
                                    setState(() => _jobId = null),
                                icon: const Icon(Icons.link_off),
                              ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Items & labour',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ..._lines.asMap().entries.map((entry) {
                      final index = entry.key;
                      final line = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: line.descriptionController,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  labelText: 'Description',
                                  suffixIcon: _lines.length > 1
                                      ? IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _lines.removeAt(index).dispose();
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                        )
                                      : null,
                                ),
                                onChanged: (_) => setState(() {}),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: line.quantityController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Qty',
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: line.priceController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: 'Unit price (R)',
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _lines.add(_LineDraft()));
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add line'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _discountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Discount (R)',
                        prefixIcon: Icon(Icons.sell_outlined),
                        helperText: 'Optional. Applied before tax.',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _taxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tax %',
                        prefixIcon: Icon(Icons.percent),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        final parsed = int.tryParse(value?.trim() ?? '');
                        if (parsed == null || parsed < 0 || parsed > 100) {
                          return 'Enter 0–100';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_outlined),
                      title: Text(
                        'Issue date: ${DateFormat('d MMM yyyy').format(_issueDate)}',
                      ),
                      trailing: IconButton(
                        onPressed: _pickIssueDate,
                        icon: const Icon(Icons.edit_calendar_outlined),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_available_outlined),
                      title: Text(
                        _dueDate == null
                            ? 'Due date (optional)'
                            : 'Due: ${DateFormat('d MMM yyyy').format(_dueDate!)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_dueDate != null)
                            IconButton(
                              onPressed: () => setState(() => _dueDate = null),
                              icon: const Icon(Icons.clear),
                            ),
                          IconButton(
                            onPressed: _pickDueDate,
                            icon: const Icon(Icons.edit_calendar_outlined),
                          ),
                        ],
                      ),
                    ),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          children: [
                            _totalRow(
                              context,
                              'Subtotal',
                              totals == null
                                  ? '—'
                                  : Money.formatZar(totals.subtotalCents),
                            ),
                            _totalRow(
                              context,
                              'Discount',
                              totals == null
                                  ? '—'
                                  : Money.formatZar(totals.discountCents),
                            ),
                            _totalRow(
                              context,
                              'Tax',
                              totals == null
                                  ? '—'
                                  : Money.formatZar(totals.taxAmountCents),
                            ),
                            const Divider(),
                            _totalRow(
                              context,
                              'Grand total',
                              totals == null
                                  ? '—'
                                  : Money.formatZar(totals.totalCents),
                              emphasize: true,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Totals are calculated automatically and cannot be typed.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label:
                          widget.isEditing ? 'Save Invoice' : 'Create Invoice',
                      isLoading: _isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _totalRow(
    BuildContext context,
    String label,
    String value, {
    bool emphasize = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
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
}
