import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../providers/expense_providers.dart';
import '../../../services/expense_service.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/empty_state.dart';
import '../widgets/expense_card.dart';

class ExpensesListScreen extends ConsumerStatefulWidget {
  const ExpensesListScreen({super.key});

  @override
  ConsumerState<ExpensesListScreen> createState() => _ExpensesListScreenState();
}

class _ExpensesListScreenState extends ConsumerState<ExpensesListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(expenseSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(filteredExpensesProvider);
    final filter = ref.watch(expenseListFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/expenses/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Expense'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.sm,
              AppSpacing.screen,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                ref.read(expenseSearchQueryProvider.notifier).state = value;
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search expenses...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          ref.read(expenseSearchQueryProvider.notifier).state =
                              '';
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              children: ExpenseListFilter.values.map((value) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(_label(value)),
                    selected: filter == value,
                    onSelected: (_) {
                      ref.read(expenseListFilterProvider.notifier).state =
                          value;
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: expensesAsync.when(
              loading: () => const AppLoading(message: 'Loading expenses...'),
              error: (error, _) => Center(child: Text(error.toString())),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return EmptyState(
                    title: 'No expenses yet',
                    message:
                        'Track fuel, materials, and other costs. Estimated profit uses these totals.',
                    actionLabel: 'Add Expense',
                    onAction: () => context.push('/expenses/new'),
                    icon: Icons.account_balance_wallet_outlined,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.sm,
                    AppSpacing.screen,
                    88,
                  ),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return ExpenseCard(
                      expense: expense,
                      onTap: () =>
                          context.push('/expenses/${expense.expenseId}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _label(ExpenseListFilter filter) {
    switch (filter) {
      case ExpenseListFilter.active:
        return 'Active';
      case ExpenseListFilter.archived:
        return 'Archived';
      case ExpenseListFilter.all:
        return 'All';
    }
  }
}
