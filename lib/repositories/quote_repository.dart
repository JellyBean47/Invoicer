import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../core/utils/app_exception.dart';
import '../models/quote.dart';
import '../models/quote_item.dart';

class QuoteRepository {
  QuoteRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection(FirestoreCollections.quotes);
  }

  DocumentReference<Map<String, dynamic>> _doc(String quoteId) {
    return _collection.doc(quoteId);
  }

  CollectionReference<Map<String, dynamic>> _items(String quoteId) {
    return _doc(quoteId).collection('items');
  }

  Stream<List<Quote>> watchByBusiness(String businessId) {
    return _collection
        .where('businessId', isEqualTo: businessId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Quote.fromMap(doc.data())).toList(),
        );
  }

  Stream<List<Quote>> watchByCustomer({
    required String businessId,
    required String customerId,
  }) {
    return _collection
        .where('businessId', isEqualTo: businessId)
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Quote.fromMap(doc.data())).toList(),
        );
  }

  Stream<Quote?> watchById(String quoteId) {
    return _doc(quoteId).snapshots().asyncMap((snapshot) async {
      if (!snapshot.exists || snapshot.data() == null) return null;
      final items = await _loadItems(quoteId);
      return Quote.fromMap(snapshot.data()!, items: items);
    });
  }

  Future<Quote?> getById(String quoteId) async {
    try {
      final snapshot = await _doc(quoteId).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      final items = await _loadItems(quoteId);
      return Quote.fromMap(snapshot.data()!, items: items);
    } on FirebaseException catch (_) {
      throw const AppException('Unable to load quote.');
    }
  }

  Future<List<QuoteItem>> _loadItems(String quoteId) async {
    final snapshot = await _items(quoteId).orderBy('displayOrder').get();
    return snapshot.docs
        .map((doc) => QuoteItem.fromMap(doc.data(), itemId: doc.id))
        .toList();
  }

  Future<String> nextQuoteNumber(String businessId) async {
    try {
      final businessRef =
          _firestore.collection(FirestoreCollections.businesses).doc(businessId);
      return _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(businessRef);
        if (!snapshot.exists) {
          throw const AppException('Business not found.');
        }
        final current = (snapshot.data()?['quoteCounter'] as int?) ?? 0;
        final next = current + 1;
        transaction.update(businessRef, {
          'quoteCounter': next,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        final year = DateTime.now().year;
        return 'QUO-$year-${next.toString().padLeft(6, '0')}';
      });
    } on AppException {
      rethrow;
    } on FirebaseException catch (_) {
      throw const AppException('Unable to generate quote number.');
    }
  }

  Future<Quote> create({
    required Quote quote,
    required List<QuoteItem> items,
  }) async {
    try {
      final ref = _collection.doc();
      final now = DateTime.now();
      final withId = Quote(
        quoteId: ref.id,
        businessId: quote.businessId,
        customerId: quote.customerId,
        quoteNumber: quote.quoteNumber,
        status: quote.status,
        subtotalCents: quote.subtotalCents,
        discountCents: quote.discountCents,
        taxPercent: quote.taxPercent,
        taxAmountCents: quote.taxAmountCents,
        totalCents: quote.totalCents,
        notes: quote.notes,
        expiryDate: quote.expiryDate,
        createdAt: now,
        updatedAt: now,
        customerName: quote.customerName,
        convertedJobId: '',
        items: items,
      );

      final batch = _firestore.batch();
      batch.set(ref, withId.toMap());
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final itemRef = _items(ref.id).doc();
        batch.set(itemRef, {
          'itemId': itemRef.id,
          'description': item.description,
          'quantity': item.quantity,
          'unitPrice': item.unitPriceCents,
          'lineTotal': item.lineTotalCents,
          'displayOrder': i,
        });
      }
      await batch.commit();
      return withId.copyWith(items: items);
    } on FirebaseException catch (_) {
      throw const AppException('Unable to create quote.');
    }
  }

  Future<void> replace({
    required Quote quote,
    required List<QuoteItem> items,
  }) async {
    try {
      final batch = _firestore.batch();
      batch.set(_doc(quote.quoteId), {
        ...quote.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final existing = await _items(quote.quoteId).get();
      for (final doc in existing.docs) {
        batch.delete(doc.reference);
      }
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final itemRef = _items(quote.quoteId).doc();
        batch.set(itemRef, {
          'itemId': itemRef.id,
          'description': item.description,
          'quantity': item.quantity,
          'unitPrice': item.unitPriceCents,
          'lineTotal': item.lineTotalCents,
          'displayOrder': i,
        });
      }
      await batch.commit();
    } on FirebaseException catch (_) {
      throw const AppException('Unable to update quote.');
    }
  }

  Future<void> updateFields({
    required String quoteId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _doc(quoteId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (_) {
      throw const AppException('Unable to update quote.');
    }
  }
}
