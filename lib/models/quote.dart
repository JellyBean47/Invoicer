import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'quote_item.dart';

enum QuoteStatus {
  draft,
  sent,
  accepted,
  rejected,
  expired;

  static QuoteStatus fromString(String? value) {
    switch (value) {
      case 'sent':
        return QuoteStatus.sent;
      case 'accepted':
        return QuoteStatus.accepted;
      case 'rejected':
        return QuoteStatus.rejected;
      case 'expired':
        return QuoteStatus.expired;
      default:
        return QuoteStatus.draft;
    }
  }

  String get firestoreValue => name;

  String get label {
    switch (this) {
      case QuoteStatus.draft:
        return 'Draft';
      case QuoteStatus.sent:
        return 'Sent';
      case QuoteStatus.accepted:
        return 'Accepted';
      case QuoteStatus.rejected:
        return 'Rejected';
      case QuoteStatus.expired:
        return 'Expired';
    }
  }

  Color get color {
    switch (this) {
      case QuoteStatus.draft:
        return AppColors.statusDraft;
      case QuoteStatus.sent:
        return AppColors.information;
      case QuoteStatus.accepted:
        return AppColors.success;
      case QuoteStatus.rejected:
        return AppColors.error;
      case QuoteStatus.expired:
        return AppColors.warning;
    }
  }

  bool get isEditable => this == QuoteStatus.draft || this == QuoteStatus.sent;

  bool get canConvertToJob => this == QuoteStatus.accepted;
}

class Quote {
  const Quote({
    required this.quoteId,
    required this.businessId,
    required this.customerId,
    required this.quoteNumber,
    required this.status,
    required this.subtotalCents,
    required this.discountCents,
    required this.taxPercent,
    required this.taxAmountCents,
    required this.totalCents,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.expiryDate,
    this.customerName = '',
    this.convertedJobId = '',
    this.items = const [],
  });

  final String quoteId;
  final String businessId;
  final String customerId;
  final String quoteNumber;
  final QuoteStatus status;
  final int subtotalCents;
  final int discountCents;
  final int taxPercent;
  final int taxAmountCents;
  final int totalCents;
  final String notes;
  final DateTime? expiryDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String customerName;
  final String convertedJobId;
  final List<QuoteItem> items;

  bool get hasConvertedJob => convertedJobId.isNotEmpty;

  factory Quote.fromMap(Map<String, dynamic> map, {List<QuoteItem>? items}) {
    return Quote(
      quoteId: map['quoteId'] as String? ?? '',
      businessId: map['businessId'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      quoteNumber: map['quoteNumber'] as String? ?? '',
      status: QuoteStatus.fromString(map['status'] as String?),
      subtotalCents: map['subtotal'] as int? ?? 0,
      discountCents: map['discount'] as int? ?? 0,
      taxPercent: map['taxPercent'] as int? ?? 0,
      taxAmountCents: map['taxAmount'] as int? ?? 0,
      totalCents: map['total'] as int? ?? 0,
      notes: map['notes'] as String? ?? '',
      expiryDate: _readDate(map['expiryDate']),
      createdAt: _readDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _readDate(map['updatedAt']) ?? DateTime.now(),
      customerName: map['customerName'] as String? ?? '',
      convertedJobId: map['convertedJobId'] as String? ?? '',
      items: items ?? const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'quoteId': quoteId,
      'businessId': businessId,
      'customerId': customerId,
      'quoteNumber': quoteNumber,
      'status': status.firestoreValue,
      'subtotal': subtotalCents,
      'discount': discountCents,
      'taxPercent': taxPercent,
      'taxAmount': taxAmountCents,
      'total': totalCents,
      'notes': notes,
      'expiryDate':
          expiryDate == null ? null : Timestamp.fromDate(expiryDate!),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'customerName': customerName,
      'convertedJobId': convertedJobId,
    };
  }

  Quote copyWith({
    QuoteStatus? status,
    int? subtotalCents,
    int? discountCents,
    int? taxPercent,
    int? taxAmountCents,
    int? totalCents,
    String? notes,
    DateTime? expiryDate,
    bool clearExpiryDate = false,
    DateTime? updatedAt,
    String? customerName,
    String? convertedJobId,
    List<QuoteItem>? items,
  }) {
    return Quote(
      quoteId: quoteId,
      businessId: businessId,
      customerId: customerId,
      quoteNumber: quoteNumber,
      status: status ?? this.status,
      subtotalCents: subtotalCents ?? this.subtotalCents,
      discountCents: discountCents ?? this.discountCents,
      taxPercent: taxPercent ?? this.taxPercent,
      taxAmountCents: taxAmountCents ?? this.taxAmountCents,
      totalCents: totalCents ?? this.totalCents,
      notes: notes ?? this.notes,
      expiryDate: clearExpiryDate ? null : (expiryDate ?? this.expiryDate),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerName: customerName ?? this.customerName,
      convertedJobId: convertedJobId ?? this.convertedJobId,
      items: items ?? this.items,
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
