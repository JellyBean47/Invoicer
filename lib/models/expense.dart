import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum ExpenseCategory {
  fuel,
  materials,
  equipment,
  officeSupplies,
  rent,
  other;

  static ExpenseCategory fromString(String? value) {
    switch (value) {
      case 'fuel':
        return ExpenseCategory.fuel;
      case 'materials':
        return ExpenseCategory.materials;
      case 'equipment':
        return ExpenseCategory.equipment;
      case 'office_supplies':
        return ExpenseCategory.officeSupplies;
      case 'rent':
        return ExpenseCategory.rent;
      default:
        return ExpenseCategory.other;
    }
  }

  String get firestoreValue {
    switch (this) {
      case ExpenseCategory.officeSupplies:
        return 'office_supplies';
      default:
        return name;
    }
  }

  String get label {
    switch (this) {
      case ExpenseCategory.fuel:
        return 'Fuel';
      case ExpenseCategory.materials:
        return 'Materials';
      case ExpenseCategory.equipment:
        return 'Equipment';
      case ExpenseCategory.officeSupplies:
        return 'Office Supplies';
      case ExpenseCategory.rent:
        return 'Rent';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.fuel:
        return Icons.local_gas_station_outlined;
      case ExpenseCategory.materials:
        return Icons.inventory_2_outlined;
      case ExpenseCategory.equipment:
        return Icons.build_outlined;
      case ExpenseCategory.officeSupplies:
        return Icons.desktop_windows_outlined;
      case ExpenseCategory.rent:
        return Icons.storefront_outlined;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }
}

enum ExpenseStatus {
  active,
  archived;

  static ExpenseStatus fromString(String? value) {
    switch (value) {
      case 'archived':
        return ExpenseStatus.archived;
      default:
        return ExpenseStatus.active;
    }
  }

  String get firestoreValue => name;

  String get label {
    switch (this) {
      case ExpenseStatus.active:
        return 'Active';
      case ExpenseStatus.archived:
        return 'Archived';
    }
  }

  Color get color {
    switch (this) {
      case ExpenseStatus.active:
        return AppColors.success;
      case ExpenseStatus.archived:
        return AppColors.inactive;
    }
  }
}

class Expense {
  const Expense({
    required this.expenseId,
    required this.businessId,
    required this.category,
    required this.description,
    required this.amountCents,
    required this.expenseDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.notes = '',
  });

  final String expenseId;
  final String businessId;
  final ExpenseCategory category;
  final String description;
  final int amountCents;
  final DateTime expenseDate;
  final String notes;
  final ExpenseStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status == ExpenseStatus.active;
  bool get isArchived => status == ExpenseStatus.archived;

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      expenseId: map['expenseId'] as String? ?? '',
      businessId: map['businessId'] as String? ?? '',
      category: ExpenseCategory.fromString(map['category'] as String?),
      description: map['description'] as String? ?? '',
      amountCents: map['amount'] as int? ?? 0,
      expenseDate: _readDate(map['expenseDate']) ?? DateTime.now(),
      notes: map['notes'] as String? ?? '',
      status: ExpenseStatus.fromString(map['status'] as String?),
      createdAt: _readDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _readDate(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'expenseId': expenseId,
      'businessId': businessId,
      'category': category.firestoreValue,
      'description': description,
      'amount': amountCents,
      'expenseDate': Timestamp.fromDate(expenseDate),
      'notes': notes,
      'status': status.firestoreValue,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Expense copyWith({
    ExpenseCategory? category,
    String? description,
    int? amountCents,
    DateTime? expenseDate,
    String? notes,
    ExpenseStatus? status,
    DateTime? updatedAt,
  }) {
    return Expense(
      expenseId: expenseId,
      businessId: businessId,
      category: category ?? this.category,
      description: description ?? this.description,
      amountCents: amountCents ?? this.amountCents,
      expenseDate: expenseDate ?? this.expenseDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
