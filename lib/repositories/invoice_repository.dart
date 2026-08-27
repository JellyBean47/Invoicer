import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../core/utils/app_exception.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';

class InvoiceRepository {
  InvoiceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection(FirestoreCollections.invoices);
  }

  DocumentReference<Map<String, dynamic>> _doc(String invoiceId) {
    return _collection.doc(invoiceId);
  }

  CollectionReference<Map<String, dynamic>> _items(String invoiceId) {
    return _doc(invoiceId).collection('items');
  }

  Stream<List<Invoice>> watchByBusiness(String businessId) {
    return _collection
        .where('businessId', isEqualTo: businessId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Invoice.fromMap(doc.data())).toList(),
        );
  }

  Stream<List<Invoice>> watchByCustomer({
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
              snapshot.docs.map((doc) => Invoice.fromMap(doc.data())).toList(),
        );
  }

  Stream<Invoice?> watchById(String invoiceId) {
    return _doc(invoiceId).snapshots().asyncMap((snapshot) async {
      if (!snapshot.exists || snapshot.data() == null) return null;
      final items = await _loadItems(invoiceId);
      return Invoice.fromMap(snapshot.data()!, items: items);
    });
  }

  Future<Invoice?> getById(String invoiceId) async {
    try {
      final snapshot = await _doc(invoiceId).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      final items = await _loadItems(invoiceId);
      return Invoice.fromMap(snapshot.data()!, items: items);
    } on FirebaseException catch (_) {
      throw const AppException('Unable to load invoice.');
    }
  }

  Future<List<InvoiceItem>> _loadItems(String invoiceId) async {
    final snapshot = await _items(invoiceId).orderBy('displayOrder').get();
    return snapshot.docs
        .map((doc) => InvoiceItem.fromMap(doc.data(), itemId: doc.id))
        .toList();
  }

  /// Sequential invoice numbers via local business counter (MVP).
  /// Spec prefers Cloud Functions later; same pattern as jobs/quotes today.
  Future<String> nextInvoiceNumber(String businessId) async {
    try {
      final businessRef =
          _firestore.collection(FirestoreCollections.businesses).doc(businessId);
      return _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(businessRef);
        if (!snapshot.exists) {
          throw const AppException('Business not found.');
        }
        final data = snapshot.data()!;
        final current = (data['invoiceCounter'] as int?) ?? 0;
        final next = current + 1;
        final prefix = (data['invoicePrefix'] as String?)?.trim().isNotEmpty ==
                true
            ? (data['invoicePrefix'] as String).trim().toUpperCase()
            : 'INV';
        transaction.update(businessRef, {
          'invoiceCounter': next,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        final year = DateTime.now().year;
        return '$prefix-$year-${next.toString().padLeft(6, '0')}';
      });
    } on AppException {
      rethrow;
    } on FirebaseException catch (_) {
      throw const AppException('Unable to generate invoice number.');
    }
  }

  Future<Invoice> create({
    required Invoice invoice,
    required List<InvoiceItem> items,
  }) async {
    try {
      final ref = _collection.doc();
      final now = DateTime.now();
      final withId = Invoice(
        invoiceId: ref.id,
        businessId: invoice.businessId,
        customerId: invoice.customerId,
        jobId: invoice.jobId,
        invoiceNumber: invoice.invoiceNumber,
        status: invoice.status,
        subtotalCents: invoice.subtotalCents,
        discountCents: invoice.discountCents,
        taxPercent: invoice.taxPercent,
        taxAmountCents: invoice.taxAmountCents,
        grandTotalCents: invoice.grandTotalCents,
        amountPaidCents: invoice.amountPaidCents,
        balanceRemainingCents: invoice.balanceRemainingCents,
        notes: invoice.notes,
        issueDate: invoice.issueDate,
        dueDate: invoice.dueDate,
        finalizedAt: invoice.finalizedAt,
        createdAt: now,
        updatedAt: now,
        customerName: invoice.customerName,
        duplicatedFromInvoiceId: invoice.duplicatedFromInvoiceId,
        items: items,
      );

      // Write parent first so item security rules can read the draft invoice.
      // A single batch of parent+items fails rules that get() the parent.
      await ref.set(withId.toMap());

      if (items.isNotEmpty) {
        final batch = _firestore.batch();
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
      }
      return withId.copyWith(items: items);
    } on FirebaseException catch (error) {
      throw AppException(
        error.message?.isNotEmpty == true
            ? 'Unable to create invoice: ${error.message}'
            : 'Unable to create invoice.',
      );
    }
  }

  Future<void> replace({
    required Invoice invoice,
    required List<InvoiceItem> items,
  }) async {
    try {
      final batch = _firestore.batch();
      batch.set(_doc(invoice.invoiceId), {
        ...invoice.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final existing = await _items(invoice.invoiceId).get();
      for (final doc in existing.docs) {
        batch.delete(doc.reference);
      }
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final itemRef = _items(invoice.invoiceId).doc();
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
      throw const AppException('Unable to update invoice.');
    }
  }

  Future<void> updateFields({
    required String invoiceId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _doc(invoiceId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (_) {
      throw const AppException('Unable to update invoice.');
    }
  }
}
