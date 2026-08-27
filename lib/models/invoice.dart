import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'invoice_item.dart';

enum InvoiceStatus {
  draft,
  final_,
  paid,
  partial,
  overdue,
  cancelled;

  static InvoiceStatus fromString(String? value) {
    switch (value) {
      case 'final':
        return InvoiceStatus.final_;
      case 'paid':
        return InvoiceStatus.paid;
      case 'partial':
        return InvoiceStatus.partial;
      case 'overdue':
        return InvoiceStatus.overdue;
      case 'cancelled':
        return InvoiceStatus.cancelled;
      default:
        return InvoiceStatus.draft;
    }
  }

  String get firestoreValue {
    switch (this) {
      case InvoiceStatus.final_:
        return 'final';
      default:
        return name;
    }
  }

  String get label {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.final_:
        return 'Final';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.partial:
        return 'Partially Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case InvoiceStatus.draft:
        return AppColors.statusDraft;
      case InvoiceStatus.final_:
        return AppColors.information;
      case InvoiceStatus.paid:
        return AppColors.statusPaid;
      case InvoiceStatus.partial:
        return AppColors.statusPartial;
      case InvoiceStatus.overdue:
        return AppColors.statusOverdue;
      case InvoiceStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }

  bool get isEditable => this == InvoiceStatus.draft;

  bool get isFinalized =>
      this == InvoiceStatus.final_ ||
      this == InvoiceStatus.paid ||
      this == InvoiceStatus.partial ||
      this == InvoiceStatus.overdue;

  bool get canCancel => this == InvoiceStatus.draft;

  bool get canFinalize => this == InvoiceStatus.draft;

  bool get canDuplicate => this != InvoiceStatus.draft;

  bool get canRecordPayment =>
      this == InvoiceStatus.final_ ||
      this == InvoiceStatus.partial ||
      this == InvoiceStatus.overdue;
}

class Invoice {
  const Invoice({
    required this.invoiceId,
    required this.businessId,
    required this.customerId,
    required this.invoiceNumber,
    required this.status,
    required this.subtotalCents,
    required this.discountCents,
    required this.taxPercent,
    required this.taxAmountCents,
    required this.grandTotalCents,
    required this.amountPaidCents,
    required this.balanceRemainingCents,
    required this.notes,
    required this.issueDate,
    required this.createdAt,
    required this.updatedAt,
    this.jobId = '',
    this.dueDate,
    this.finalizedAt,
    this.customerName = '',
    this.duplicatedFromInvoiceId = '',
    this.items = const [],
  });

  final String invoiceId;
  final String businessId;
  final String customerId;
  final String jobId;
  final String invoiceNumber;
  final InvoiceStatus status;
  final int subtotalCents;
  final int discountCents;
  final int taxPercent;
  final int taxAmountCents;
  final int grandTotalCents;
  final int amountPaidCents;
  final int balanceRemainingCents;
  final String notes;
  final DateTime issueDate;
  final DateTime? dueDate;
  final DateTime? finalizedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String customerName;
  final String duplicatedFromInvoiceId;
  final List<InvoiceItem> items;

  bool get isLocked => !status.isEditable;

  bool get hasOutstanding =>
      status.canRecordPayment && balanceRemainingCents > 0;

  bool get canRecordPayment =>
      status.canRecordPayment && balanceRemainingCents > 0;

  /// Status after applying a payment (or checking overdue with zero paid).
  InvoiceStatus statusAfterPayment({
    required int newAmountPaidCents,
    required int newBalanceRemainingCents,
  }) {
    if (newBalanceRemainingCents <= 0) {
      return InvoiceStatus.paid;
    }
    if (newAmountPaidCents > 0) {
      return InvoiceStatus.partial;
    }
    if (_isPastDue(dueDate)) {
      return InvoiceStatus.overdue;
    }
    return InvoiceStatus.final_;
  }

  static bool _isPastDue(DateTime? dueDate) {
    if (dueDate == null) return false;
    final today = DateTime.now();
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    return dueDay.isBefore(todayDay);
  }

  factory Invoice.fromMap(Map<String, dynamic> map, {List<InvoiceItem>? items}) {
    return Invoice(
      invoiceId: map['invoiceId'] as String? ?? '',
      businessId: map['businessId'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      jobId: map['jobId'] as String? ?? '',
      invoiceNumber: map['invoiceNumber'] as String? ?? '',
      status: InvoiceStatus.fromString(map['status'] as String?),
      subtotalCents: map['subtotal'] as int? ?? 0,
      discountCents: map['discount'] as int? ?? 0,
      taxPercent: map['taxPercent'] as int? ?? 0,
      taxAmountCents: map['taxAmount'] as int? ?? 0,
      grandTotalCents: map['grandTotal'] as int? ?? 0,
      amountPaidCents: map['amountPaid'] as int? ?? 0,
      balanceRemainingCents: map['balanceRemaining'] as int? ?? 0,
      notes: map['notes'] as String? ?? '',
      issueDate: _readDate(map['issueDate']) ?? DateTime.now(),
      dueDate: _readDate(map['dueDate']),
      finalizedAt: _readDate(map['finalizedAt']),
      createdAt: _readDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _readDate(map['updatedAt']) ?? DateTime.now(),
      customerName: map['customerName'] as String? ?? '',
      duplicatedFromInvoiceId:
          map['duplicatedFromInvoiceId'] as String? ?? '',
      items: items ?? const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoiceId': invoiceId,
      'businessId': businessId,
      'customerId': customerId,
      'jobId': jobId,
      'invoiceNumber': invoiceNumber,
      'status': status.firestoreValue,
      'subtotal': subtotalCents,
      'discount': discountCents,
      'taxPercent': taxPercent,
      'taxAmount': taxAmountCents,
      'grandTotal': grandTotalCents,
      'amountPaid': amountPaidCents,
      'balanceRemaining': balanceRemainingCents,
      'notes': notes,
      'issueDate': Timestamp.fromDate(issueDate),
      'dueDate': dueDate == null ? null : Timestamp.fromDate(dueDate!),
      'finalizedAt':
          finalizedAt == null ? null : Timestamp.fromDate(finalizedAt!),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'customerName': customerName,
      'duplicatedFromInvoiceId': duplicatedFromInvoiceId,
    };
  }

  Invoice copyWith({
    InvoiceStatus? status,
    int? subtotalCents,
    int? discountCents,
    int? taxPercent,
    int? taxAmountCents,
    int? grandTotalCents,
    int? amountPaidCents,
    int? balanceRemainingCents,
    String? notes,
    DateTime? issueDate,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? finalizedAt,
    bool clearFinalizedAt = false,
    DateTime? updatedAt,
    String? customerName,
    String? jobId,
    String? duplicatedFromInvoiceId,
    List<InvoiceItem>? items,
  }) {
    return Invoice(
      invoiceId: invoiceId,
      businessId: businessId,
      customerId: customerId,
      jobId: jobId ?? this.jobId,
      invoiceNumber: invoiceNumber,
      status: status ?? this.status,
      subtotalCents: subtotalCents ?? this.subtotalCents,
      discountCents: discountCents ?? this.discountCents,
      taxPercent: taxPercent ?? this.taxPercent,
      taxAmountCents: taxAmountCents ?? this.taxAmountCents,
      grandTotalCents: grandTotalCents ?? this.grandTotalCents,
      amountPaidCents: amountPaidCents ?? this.amountPaidCents,
      balanceRemainingCents:
          balanceRemainingCents ?? this.balanceRemainingCents,
      notes: notes ?? this.notes,
      issueDate: issueDate ?? this.issueDate,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      finalizedAt:
          clearFinalizedAt ? null : (finalizedAt ?? this.finalizedAt),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerName: customerName ?? this.customerName,
      duplicatedFromInvoiceId:
          duplicatedFromInvoiceId ?? this.duplicatedFromInvoiceId,
      items: items ?? this.items,
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
