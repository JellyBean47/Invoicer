import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../core/utils/app_exception.dart';
import '../models/expense.dart';

class ExpenseRepository {
  ExpenseRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection(FirestoreCollections.expenses);
  }

  DocumentReference<Map<String, dynamic>> _doc(String expenseId) {
    return _collection.doc(expenseId);
  }

  Stream<List<Expense>> watchByBusiness(String businessId) {
    return _collection
        .where('businessId', isEqualTo: businessId)
        .orderBy('expenseDate', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Expense.fromMap(doc.data())).toList(),
        );
  }

  Stream<Expense?> watchById(String expenseId) {
    return _doc(expenseId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return Expense.fromMap(snapshot.data()!);
    });
  }

  Future<Expense?> getById(String expenseId) async {
    try {
      final snapshot = await _doc(expenseId).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      return Expense.fromMap(snapshot.data()!);
    } on FirebaseException catch (_) {
      throw const AppException('Unable to load expense.');
    }
  }

  Future<Expense> create(Expense expense) async {
    try {
      final ref = _collection.doc();
      final now = DateTime.now();
      final withId = Expense(
        expenseId: ref.id,
        businessId: expense.businessId,
        category: expense.category,
        description: expense.description,
        amountCents: expense.amountCents,
        expenseDate: expense.expenseDate,
        notes: expense.notes,
        status: ExpenseStatus.active,
        createdAt: now,
        updatedAt: now,
      );
      await ref.set(withId.toMap());
      return withId;
    } on FirebaseException catch (_) {
      throw const AppException('Unable to create expense.');
    }
  }

  Future<void> update(Expense expense) async {
    try {
      await _doc(expense.expenseId).set({
        ...expense.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (_) {
      throw const AppException('Unable to update expense.');
    }
  }

  Future<void> updateFields({
    required String expenseId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _doc(expenseId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (_) {
      throw const AppException('Unable to update expense.');
    }
  }
}
