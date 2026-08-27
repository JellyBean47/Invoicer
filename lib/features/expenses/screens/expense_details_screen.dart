import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_exception.dart';
import '../../../core/utils/money.dart';
import '../../../models/expense.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/expense_providers.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/status_badge.dart';

class ExpenseDetailsScreen extends ConsumerWidget {
  const ExpenseDetailsScreen({super.key, required this.expenseId});

  final String expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseAsync = ref.watch(expenseProvider(expenseId));

    return expenseAsync.when(
      loading: () => const Scaffold(
        body: AppLoading(message: 'Loading expense...'),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Expense')),
        body: Center(child: Text(error.toString())),
      ),
      data: (expense) {
        if (expense == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Expense')),
            body: const Center(child: Text('Expense not found.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Expense'),
            actions: [
              if (expense.isActive)
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () =>
                      context.push('/expenses/${expense.expenseId}/edit'),
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
                          Icon(expense.category.icon, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              expense.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          StatusBadge(
                            label: expense.status.label,
                            color: expense.status.color,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        Money.formatZar(expense.amountCents),
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Category: ${expense.category.label}'),
                      Text(
                        'Date: ${DateFormat.yMMMd().format(expense.expenseDate)}',
                      ),
                      if (expense.notes.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(expense.notes),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (expense.isActive)
                OutlinedButton.icon(
                  onPressed: () => _archive(context, ref, expense),
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Archive Expense'),
                )
              else
                FilledButton.icon(
                  onPressed: () => _restore(context, ref, expense),
                  icon: const Icon(Icons.unarchive_outlined),
                  label: const Text('Restore Expense'),
                ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Archived expenses stay in history but are excluded from estimated profit.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive expense?'),
        content: Text(
          'Archive ${Money.formatZar(expense.amountCents)}? '
          'It will be excluded from estimated profit until restored.',
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
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    try {
      await ref.read(expenseServiceProvider).archiveExpense(
            userId: user.uid,
            expense: expense,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense archived')),
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
    Expense expense,
  ) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    try {
      await ref.read(expenseServiceProvider).restoreExpense(
            userId: user.uid,
            expense: expense,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense restored')),
      );
    } on AppException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }
}
