import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import '../repositories/expense_repository.dart';
import '../services/expense_service.dart';
import 'app_providers.dart';
import 'customer_providers.dart';
import 'invoice_providers.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

final expenseServiceProvider = Provider<ExpenseService>((ref) {
  return ExpenseService(
    expenseRepository: ref.watch(expenseRepositoryProvider),
    timelineRepository: ref.watch(timelineRepositoryProvider),
  );
});

final expenseSearchQueryProvider = StateProvider<String>((ref) => '');

final expenseListFilterProvider =
    StateProvider<ExpenseListFilter>((ref) => ExpenseListFilter.active);

final expensesProvider = StreamProvider<List<Expense>>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final businessId = profile?.businessId;
  if (businessId == null || businessId.isEmpty) {
    return Stream.value(const []);
  }
  return ref.watch(expenseServiceProvider).watchExpenses(businessId);
});

final filteredExpensesProvider = Provider<AsyncValue<List<Expense>>>((ref) {
  final expensesAsync = ref.watch(expensesProvider);
  final query = ref.watch(expenseSearchQueryProvider);
  final filter = ref.watch(expenseListFilterProvider);
  final service = ref.watch(expenseServiceProvider);

  return expensesAsync.whenData((expenses) {
    return service.filterExpenses(
      expenses: expenses,
      query: query,
      filter: filter,
    );
  });
});

final expenseProvider =
    StreamProvider.family<Expense?, String>((ref, expenseId) {
  return ref.watch(expenseServiceProvider).watchExpense(expenseId);
});

final dashboardProfitProvider = Provider<
    AsyncValue<
        ({
          int revenue,
          int expenses,
          int estimatedProfit,
        })>>((ref) {
  final invoicesAsync = ref.watch(invoicesProvider);
  final expensesAsync = ref.watch(expensesProvider);

  if (invoicesAsync.isLoading || expensesAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (invoicesAsync.hasError) {
    return AsyncValue.error(invoicesAsync.error!, invoicesAsync.stackTrace!);
  }
  if (expensesAsync.hasError) {
    return AsyncValue.error(expensesAsync.error!, expensesAsync.stackTrace!);
  }

  final invoices = invoicesAsync.valueOrNull ?? const [];
  final expenses = expensesAsync.valueOrNull ?? const [];
  return AsyncValue.data((
    revenue: ProfitTotals.revenueCents(invoices),
    expenses: ProfitTotals.expensesCents(expenses),
    estimatedProfit: ProfitTotals.estimatedProfitCents(
      invoices: invoices,
      expenses: expenses,
    ),
  ));
});
