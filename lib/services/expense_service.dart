import '../core/utils/app_exception.dart';
import '../core/utils/money.dart';
import '../models/expense.dart';
import '../models/invoice.dart';
import '../models/timeline_entry.dart';
import '../repositories/expense_repository.dart';
import '../repositories/timeline_repository.dart';

class ExpenseInput {
  const ExpenseInput({
    required this.category,
    required this.description,
    required this.amountCents,
    required this.expenseDate,
    this.notes = '',
  });

  final ExpenseCategory category;
  final String description;
  final int amountCents;
  final DateTime expenseDate;
  final String notes;
}

class ExpenseService {
  ExpenseService({
    required ExpenseRepository expenseRepository,
    required TimelineRepository timelineRepository,
  })  : _expenseRepository = expenseRepository,
        _timelineRepository = timelineRepository;

  final ExpenseRepository _expenseRepository;
  final TimelineRepository _timelineRepository;

  Stream<List<Expense>> watchExpenses(String businessId) {
    return _expenseRepository.watchByBusiness(businessId);
  }

  Stream<Expense?> watchExpense(String expenseId) {
    return _expenseRepository.watchById(expenseId);
  }

  Future<Expense> createExpense({
    required String businessId,
    required String userId,
    required ExpenseInput input,
  }) async {
    final prepared = _prepare(input);
    final now = DateTime.now();

    final expense = await _expenseRepository.create(
      Expense(
        expenseId: '',
        businessId: businessId,
        category: prepared.category,
        description: prepared.description,
        amountCents: prepared.amountCents,
        expenseDate: prepared.expenseDate,
        notes: prepared.notes,
        status: ExpenseStatus.active,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await _timeline(
      businessId: businessId,
      userId: userId,
      expenseId: expense.expenseId,
      action: 'expense_created',
      detail:
          '${expense.category.label} — ${Money.formatZar(expense.amountCents)}',
    );

    return expense;
  }

  Future<Expense> updateExpense({
    required String userId,
    required Expense existing,
    required ExpenseInput input,
  }) async {
    if (existing.isArchived) {
      throw const AppException(
        'Archived expenses cannot be edited. Restore them first.',
      );
    }

    final prepared = _prepare(input);
    final updated = existing.copyWith(
      category: prepared.category,
      description: prepared.description,
      amountCents: prepared.amountCents,
      expenseDate: prepared.expenseDate,
      notes: prepared.notes,
      updatedAt: DateTime.now(),
    );

    await _expenseRepository.update(updated);

    await _timeline(
      businessId: existing.businessId,
      userId: userId,
      expenseId: existing.expenseId,
      action: 'expense_updated',
      detail:
          '${updated.category.label} — ${Money.formatZar(updated.amountCents)}',
    );

    return (await _expenseRepository.getById(existing.expenseId)) ?? updated;
  }

  Future<Expense> archiveExpense({
    required String userId,
    required Expense expense,
  }) async {
    if (expense.isArchived) {
      throw const AppException('Expense is already archived.');
    }

    await _expenseRepository.updateFields(
      expenseId: expense.expenseId,
      data: {'status': ExpenseStatus.archived.firestoreValue},
    );

    await _timeline(
      businessId: expense.businessId,
      userId: userId,
      expenseId: expense.expenseId,
      action: 'expense_archived',
      detail: Money.formatZar(expense.amountCents),
    );

    return (await _expenseRepository.getById(expense.expenseId)) ??
        expense.copyWith(status: ExpenseStatus.archived);
  }

  Future<Expense> restoreExpense({
    required String userId,
    required Expense expense,
  }) async {
    if (expense.isActive) {
      throw const AppException('Expense is already active.');
    }

    await _expenseRepository.updateFields(
      expenseId: expense.expenseId,
      data: {'status': ExpenseStatus.active.firestoreValue},
    );

    await _timeline(
      businessId: expense.businessId,
      userId: userId,
      expenseId: expense.expenseId,
      action: 'expense_restored',
      detail: Money.formatZar(expense.amountCents),
    );

    return (await _expenseRepository.getById(expense.expenseId)) ??
        expense.copyWith(status: ExpenseStatus.active);
  }

  List<Expense> filterExpenses({
    required List<Expense> expenses,
    required String query,
    required ExpenseListFilter filter,
  }) {
    return ExpenseQuery.filter(
      expenses: expenses,
      query: query,
      filter: filter,
    );
  }

  _PreparedExpense _prepare(ExpenseInput input) {
    final description = input.description.trim();
    if (description.isEmpty) {
      throw const AppException('Description is required.');
    }
    if (input.amountCents <= 0) {
      throw const AppException('Expense amount must be greater than zero.');
    }

    return _PreparedExpense(
      category: input.category,
      description: description,
      amountCents: input.amountCents,
      expenseDate: input.expenseDate,
      notes: input.notes.trim(),
    );
  }

  Future<void> _timeline({
    required String businessId,
    required String userId,
    required String expenseId,
    required String action,
    required String detail,
  }) {
    return _timelineRepository.add(
      TimelineEntry(
        logId: '',
        businessId: businessId,
        userId: userId,
        entityType: 'expense',
        entityId: expenseId,
        action: action,
        newValue: detail,
        timestamp: DateTime.now(),
      ),
    );
  }
}

class _PreparedExpense {
  const _PreparedExpense({
    required this.category,
    required this.description,
    required this.amountCents,
    required this.expenseDate,
    required this.notes,
  });

  final ExpenseCategory category;
  final String description;
  final int amountCents;
  final DateTime expenseDate;
  final String notes;
}

enum ExpenseListFilter {
  active,
  archived,
  all,
}

class ExpenseQuery {
  ExpenseQuery._();

  static List<Expense> filter({
    required List<Expense> expenses,
    required String query,
    required ExpenseListFilter filter,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    return expenses.where((expense) {
      switch (filter) {
        case ExpenseListFilter.active:
          if (!expense.isActive) return false;
        case ExpenseListFilter.archived:
          if (!expense.isArchived) return false;
        case ExpenseListFilter.all:
          break;
      }

      if (normalizedQuery.isEmpty) return true;
      final haystack = [
        expense.description,
        expense.category.label,
        expense.notes,
        Money.formatZar(expense.amountCents),
      ].join(' ').toLowerCase();
      return haystack.contains(normalizedQuery);
    }).toList();
  }
}

/// Profit helpers. Expenses never alter invoices or payments.
class ProfitTotals {
  ProfitTotals._();

  /// Revenue = sum of finalized invoice grand totals (excludes draft/cancelled).
  static int revenueCents(List<Invoice> invoices) {
    return invoices
        .where((invoice) => invoice.status.isFinalized)
        .fold<int>(0, (sum, invoice) => sum + invoice.grandTotalCents);
  }

  /// Active expenses only (archived excluded from profit).
  static int expensesCents(List<Expense> expenses) {
    return expenses
        .where((expense) => expense.isActive)
        .fold<int>(0, (sum, expense) => sum + expense.amountCents);
  }

  /// Estimated Profit = Revenue − Expenses
  static int estimatedProfitCents({
    required List<Invoice> invoices,
    required List<Expense> expenses,
  }) {
    return revenueCents(invoices) - expensesCents(expenses);
  }
}
