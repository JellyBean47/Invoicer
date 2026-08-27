import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../core/utils/app_exception.dart';
import '../models/customer.dart';

class CustomerRepository {
  CustomerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection(FirestoreCollections.customers);
  }

  DocumentReference<Map<String, dynamic>> _doc(String customerId) {
    return _collection.doc(customerId);
  }

  Stream<List<Customer>> watchByBusiness(String businessId) {
    return _collection
        .where('businessId', isEqualTo: businessId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Customer.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<Customer?> getById(String customerId) async {
    try {
      final snapshot = await _doc(customerId).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      return Customer.fromMap(snapshot.data()!);
    } on FirebaseException catch (_) {
      throw const AppException('Unable to load customer.');
    }
  }

  Stream<Customer?> watchById(String customerId) {
    return _doc(customerId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return Customer.fromMap(snapshot.data()!);
    });
  }

  Future<Customer?> findByPhone({
    required String businessId,
    required String phone,
  }) async {
    try {
      final snapshot = await _collection
          .where('businessId', isEqualTo: businessId)
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return Customer.fromMap(snapshot.docs.first.data());
    } on FirebaseException catch (_) {
      throw const AppException('Unable to check phone number uniqueness.');
    }
  }

  Future<Customer> create({
    required String businessId,
    required String name,
    required String phone,
    String email = '',
    String company = '',
    String address = '',
    String notes = '',
    List<String> tags = const [],
  }) async {
    try {
      final ref = _collection.doc();
      final now = DateTime.now();
      final customer = Customer(
        customerId: ref.id,
        businessId: businessId,
        name: name,
        phone: phone,
        email: email,
        company: company,
        address: address,
        notes: notes,
        tags: tags,
        status: CustomerStatus.active,
        createdAt: now,
        updatedAt: now,
      );
      await ref.set(customer.toMap());
      return customer;
    } on FirebaseException catch (_) {
      throw const AppException('Unable to create customer.');
    }
  }

  Future<void> update(Customer customer) async {
    try {
      await _doc(customer.customerId).set({
        ...customer.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (_) {
      throw const AppException('Unable to update customer.');
    }
  }

  Future<void> archive(String customerId) async {
    try {
      await _doc(customerId).update({
        'status': CustomerStatus.archived.firestoreValue,
        'archivedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (_) {
      throw const AppException('Unable to archive customer.');
    }
  }

  Future<void> restore(String customerId) async {
    try {
      await _doc(customerId).update({
        'status': CustomerStatus.active.firestoreValue,
        'archivedAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (_) {
      throw const AppException('Unable to restore customer.');
    }
  }
}
