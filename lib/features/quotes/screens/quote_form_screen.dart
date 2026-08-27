import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_exception.dart';
import '../../../core/utils/money.dart';
import '../../../models/customer.dart';
import '../../../models/quote.dart';
import '../../../models/quote_item.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/customer_providers.dart';
import '../../../providers/quote_providers.dart';
import '../../../services/quote_service.dart';
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

class QuoteFormScreen extends ConsumerStatefulWidget {
  const QuoteFormScreen({
    super.key,
    this.quoteId,
    this.initialCustomerId,
  });

  final String? quoteId;
  final String? initialCustomerId;

  bool get isEditing => quoteId != null;

  @override
  ConsumerState<QuoteFormScreen> createState() => _QuoteFormScreenState();
}

class _QuoteFormScreenState extends ConsumerState<QuoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _taxController = TextEditingController();
  final _lines = <_LineDraft>[_LineDraft()];

  String? _customerId;
  DateTime? _expiryDate;
  bool _isLoading = false;
  bool _hydrated = false;
  Quote? _existing;

  @override
  void initState() {
    super.initState();
    _customerId = widget.initialCustomerId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final business = ref.read(businessProvider).valueOrNull;
      if (_taxController.text.isEmpty) {
        _taxController.text =
            '${business?.defaultTaxPercent ?? 15}';
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

  void _hydrate(Quote quote) {
    if (_hydrated) return;
    _existing = quote;
    _customerId = quote.customerId;
    _notesController.text = quote.notes;
    _discountController.text = (quote.discountCents / 100).toStringAsFixed(2);
    _taxController.text = '${quote.taxPercent}';
    _expiryDate = quote.expiryDate;
    for (final line in _lines) {
      line.dispose();
    }
    _lines
      ..clear()
      ..addAll(
        quote.items.isEmpty
            ? [_LineDraft()]
            : quote.items.map(
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

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: DateTime(now.year + 3),
    );
    if (date == null || !mounted) return;
    setState(() => _expiryDate = date);
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

    final lineInputs = <QuoteLineInput>[];
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
        QuoteLineInput(
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
      final input = QuoteInput(
        customerId: _customerId!,
        lines: lineInputs,
        taxPercent: tax,
        discountCents: discount,
        notes: _notesController.text,
        expiryDate: _expiryDate,
      );

      if (widget.isEditing) {
        final existing = _existing;
        if (existing == null) return;
        await ref.read(quoteServiceProvider).updateQuote(
              userId: user.uid,
              existing: existing,
              input: input,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote saved')),
        );
        context.pop();
      } else {
        final created = await ref.read(quoteServiceProvider).createQuote(
              businessId: profile.businessId,
              userId: user.uid,
              input: input,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quote ${created.quoteNumber} created')),
        );
        context.go('/quotes/${created.quoteId}');
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
      final quoteAsync = ref.watch(quoteProvider(widget.quoteId!));
      return quoteAsync.when(
        loading: () => const Scaffold(
          body: AppLoading(message: 'Loading quote...'),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit Quote')),
          body: Center(child: Text(error.toString())),
        ),
        data: (quote) {
          if (quote == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit Quote')),
              body: const Center(child: Text('Quote not found.')),
            );
          }
          _hydrate(quote);
          return _buildForm(context);
        },
      );
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
        title: Text(widget.isEditing ? 'Edit Quote' : 'New Quote'),
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
                                          icon: const Icon(Icons.delete_outline),
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
                        _expiryDate == null
                            ? 'Expiry date (optional)'
                            : DateFormat('d MMM yyyy').format(_expiryDate!),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_expiryDate != null)
                            IconButton(
                              onPressed: () =>
                                  setState(() => _expiryDate = null),
                              icon: const Icon(Icons.clear),
                            ),
                          IconButton(
                            onPressed: _pickExpiry,
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
                      label: widget.isEditing ? 'Save Quote' : 'Create Quote',
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
