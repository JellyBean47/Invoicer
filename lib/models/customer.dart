import 'package:cloud_firestore/cloud_firestore.dart';

enum CustomerStatus {
  active,
  archived;

  static CustomerStatus fromString(String? value) {
    switch (value) {
      case 'archived':
        return CustomerStatus.archived;
      default:
        return CustomerStatus.active;
    }
  }

  String get firestoreValue => name;
}

class Customer {
  const Customer({
    required this.customerId,
    required this.businessId,
    required this.name,
    required this.phone,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.email = '',
    this.company = '',
    this.address = '',
    this.notes = '',
    this.tags = const [],
    this.archivedAt,
  });

  final String customerId;
  final String businessId;
  final String name;
  final String phone;
  final String email;
  final String company;
  final String address;
  final String notes;
  final List<String> tags;
  final CustomerStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;

  bool get isArchived => status == CustomerStatus.archived;
  bool get isActive => status == CustomerStatus.active;

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      customerId: map['customerId'] as String? ?? '',
      businessId: map['businessId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      company: map['company'] as String? ?? '',
      address: map['address'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      tags: (map['tags'] as List<dynamic>?)
              ?.map((tag) => tag.toString())
              .toList() ??
          const [],
      status: CustomerStatus.fromString(map['status'] as String?),
      createdAt: _readDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _readDate(map['updatedAt']) ?? DateTime.now(),
      archivedAt: _readDate(map['archivedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'businessId': businessId,
      'name': name,
      'phone': phone,
      'email': email,
      'company': company,
      'address': address,
      'notes': notes,
      'tags': tags,
      'status': status.firestoreValue,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'archivedAt':
          archivedAt == null ? null : Timestamp.fromDate(archivedAt!),
    };
  }

  Customer copyWith({
    String? name,
    String? phone,
    String? email,
    String? company,
    String? address,
    String? notes,
    List<String>? tags,
    CustomerStatus? status,
    DateTime? updatedAt,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
  }) {
    return Customer(
      customerId: customerId,
      businessId: businessId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      company: company ?? this.company,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
