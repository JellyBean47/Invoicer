import 'package:cloud_firestore/cloud_firestore.dart';

class Business {
  const Business({
    required this.businessId,
    required this.businessName,
    required this.ownerName,
    required this.phone,
    required this.email,
    required this.address,
    required this.currency,
    required this.defaultTaxPercent,
    required this.invoicePrefix,
    required this.invoiceCounter,
    required this.createdAt,
    required this.updatedAt,
    this.registrationNumber = '',
    this.vatNumber = '',
    this.logoUrl = '',
  });

  final String businessId;
  final String businessName;
  final String ownerName;
  final String phone;
  final String email;
  final String address;
  final String registrationNumber;
  final String vatNumber;
  final String currency;
  final int defaultTaxPercent;
  final String invoicePrefix;
  final int invoiceCounter;
  final String logoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Business.fromMap(Map<String, dynamic> map) {
    return Business(
      businessId: map['businessId'] as String? ?? '',
      businessName: map['businessName'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      registrationNumber: map['registrationNumber'] as String? ?? '',
      vatNumber: map['vatNumber'] as String? ?? '',
      currency: map['currency'] as String? ?? 'ZAR',
      defaultTaxPercent: map['defaultTaxPercent'] as int? ?? 15,
      invoicePrefix: map['invoicePrefix'] as String? ?? 'INV',
      invoiceCounter: map['invoiceCounter'] as int? ?? 0,
      logoUrl: map['logoUrl'] as String? ?? '',
      createdAt: _readDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _readDate(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'businessName': businessName,
      'ownerName': ownerName,
      'phone': phone,
      'email': email,
      'address': address,
      'registrationNumber': registrationNumber,
      'vatNumber': vatNumber,
      'currency': currency,
      'defaultTaxPercent': defaultTaxPercent,
      'invoicePrefix': invoicePrefix,
      'invoiceCounter': invoiceCounter,
      'logoUrl': logoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
