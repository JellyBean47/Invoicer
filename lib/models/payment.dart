import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum PaymentMethod {
  cash,
  eft,
  card,
  other;

  static PaymentMethod fromString(String? value) {
    switch (value) {
      case 'eft':
        return PaymentMethod.eft;
      case 'card':
        return PaymentMethod.card;
      case 'other':
        return PaymentMethod.other;
      default:
        return PaymentMethod.cash;
    }
  }

  String get firestoreValue => name;

  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.eft:
        return 'EFT';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cash:
        return Icons.payments_outlined;
      case PaymentMethod.eft:
        return Icons.account_balance_outlined;
      case PaymentMethod.card:
        return Icons.credit_card_outlined;
      case PaymentMethod.other:
        return Icons.more_horiz;
    }
  }

  Color get color {
    switch (this) {
      case PaymentMethod.cash:
        return AppColors.success;
      case PaymentMethod.eft:
        return AppColors.information;
      case PaymentMethod.card:
        return AppColors.primary;
      case PaymentMethod.other:
        return AppColors.inactive;
    }
  }
}

class Payment {
  const Payment({
    required this.paymentId,
    required this.businessId,
    required this.invoiceId,
    required this.customerId,
    required this.amountCents,
    required this.paymentMethod,
    required this.receivedAt,
    required this.createdAt,
    this.reference = '',
    this.notes = '',
    this.invoiceNumber = '',
    this.customerName = '',
  });

  final String paymentId;
  final String businessId;
  final String invoiceId;
  final String customerId;
  final int amountCents;
  final PaymentMethod paymentMethod;
  final String reference;
  final String notes;
  final DateTime receivedAt;
  final DateTime createdAt;
  final String invoiceNumber;
  final String customerName;

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      paymentId: map['paymentId'] as String? ?? '',
      businessId: map['businessId'] as String? ?? '',
      invoiceId: map['invoiceId'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      amountCents: map['amount'] as int? ?? 0,
      paymentMethod: PaymentMethod.fromString(map['paymentMethod'] as String?),
      reference: map['reference'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      receivedAt: _readDate(map['receivedAt']) ?? DateTime.now(),
      createdAt: _readDate(map['createdAt']) ?? DateTime.now(),
      invoiceNumber: map['invoiceNumber'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'businessId': businessId,
      'invoiceId': invoiceId,
      'customerId': customerId,
      'amount': amountCents,
      'paymentMethod': paymentMethod.firestoreValue,
      'reference': reference,
      'notes': notes,
      'receivedAt': Timestamp.fromDate(receivedAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'invoiceNumber': invoiceNumber,
      'customerName': customerName,
    };
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
