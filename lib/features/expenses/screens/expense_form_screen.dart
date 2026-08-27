import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_exception.dart';
import '../../../core/utils/money.dart';
import '../../../models/expense.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/expense_providers.dart';
import '../../../services/expense_service.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/primary_button.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({super.key, this.expenseId});

  final String? expenseId;

  bool get isEditing => expenseId != null;

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  ExpenseCategory _category = ExpenseCategory.other;
  DateTime _expenseDate = DateTime.now();
  bool _isLoading = false;
  bool _hydrated = false;
  Expense? _existing;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _expenseDate = DateTime(today.year, today.month, today.day);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _hydrate(Expense expense) {
    if (_hydrated) return;
    _existing = expense;
    _category = expense.category;
    _descriptionController.text = expense.description;
    _amountController.text = (expense.amountCents / 100).toStringAsFixed(2);
    _notesController.text = expense.notes;
    _expenseDate = expense.expenseDate;
    _hydrated = true;
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    setState(() => _expenseDate = date);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = Money.tryParseRandToCents(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount greater than zero.')),
      );
      return;
    }

    final profile = ref.read(userProfileProvider).valueOrNull;
    final user = ref.read(authStateProvider).valueOrNull;
    if (profile == null || user == null) return;

    setState(() => _isLoading = true);
    try {
      final input = ExpenseInput(
        category: _category,
        description: _descriptionController.text,
        amountCents: amount,
        expenseDate: _expenseDate,
        notes: _notesController.text,
      );

      if (widget.isEditing) {
        final existing = _existing;
        if (existing == null) return;
        await ref.read(expenseServiceProvider).updateExpense(
              userId: user.uid,
              existing: existing,
              input: input,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense saved')),
        );
        context.pop();
      } else {
        final created = await ref.read(expenseServiceProvider).createExpense(
              businessId: profile.businessId,
              userId: user.uid,
              input: input,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Expense ${Money.formatZar(created.amountCents)} recorded',
            ),
          ),
        );
        context.go('/expenses/${created.expenseId}');
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
      final expenseAsync = ref.watch(expenseProvider(widget.expenseId!));
      return expenseAsync.when(
        loading: () => const Scaffold(
          body: AppLoading(message: 'Loading expense...'),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit Expense')),
          body: Center(child: Text(error.toString())),
        ),
        data: (expense) {
          if (expense == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit Expense')),
              body: const Center(child: Text('Expense not found.')),
            );
          }
          if (expense.isArchived) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit Expense')),
              body: const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.screen),
                  child: Text(
                    'Archived expenses cannot be edited. Restore them first.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }
          _hydrate(expense);
          return _buildForm(context);
        },
      );
    }
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Expense' : 'New Expense'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              Text(
                'Category',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: ExpenseCategory.values.map((category) {
                  return ChoiceChip(
                    avatar: Icon(category.icon, size: 18),
                    label: Text(category.label),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (R)',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (value) {
                  final cents = Money.tryParseRandToCents(value ?? '');
                  if (cents == null || cents <= 0) {
                    return 'Enter an amount greater than zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: Text(
                  'Date: ${DateFormat('d MMM yyyy').format(_expenseDate)}',
                ),
                trailing: IconButton(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.edit_calendar_outlined),
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
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: widget.isEditing ? 'Save Expense' : 'Add Expense',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Expenses never change invoices or payments. '
                'Estimated profit uses active expense totals only.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
