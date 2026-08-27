import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../core/utils/app_exception.dart';
import '../models/invoice.dart';
import '../models/payment.dart';

class PaymentRepository {
  PaymentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection(FirestoreCollections.payments);
  }

  Stream<List<Payment>> watchByBusiness(String businessId) {
    return _collection
        .where('businessId', isEqualTo: businessId)
        .orderBy('receivedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Payment.fromMap(doc.data())).toList(),
        );
  }

  Stream<List<Payment>> watchByInvoice({
    required String businessId,
    required String invoiceId,
  }) {
    return _collection
        .where('businessId', isEqualTo: businessId)
        .where('invoiceId', isEqualTo: invoiceId)
        .orderBy('receivedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Payment.fromMap(doc.data())).toList(),
        );
  }

  Stream<List<Payment>> watchByCustomer({
    required String businessId,
    required String customerId,
  }) {
    return _collection
        .where('businessId', isEqualTo: businessId)
        .where('customerId', isEqualTo: customerId)
        .orderBy('receivedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Payment.fromMap(doc.data())).toList(),
        );
  }

  /// Atomically create payment and update invoice balance/status.
  Future<Payment> createAndUpdateInvoice({
    required String invoiceId,
    required int amountCents,
    required PaymentMethod paymentMethod,
    required DateTime receivedAt,
    required String reference,
    required String notes,
  }) async {
    try {
      final paymentRef = _collection.doc();
      final invoiceRef = _firestore
          .collection(FirestoreCollections.invoices)
          .doc(invoiceId);

      return _firestore.runTransaction((transaction) async {
        final invoiceSnap = await transaction.get(invoiceRef);
        if (!invoiceSnap.exists || invoiceSnap.data() == null) {
          throw const AppException('Invoice not found.');
        }

        final invoice = Invoice.fromMap(invoiceSnap.data()!);
        if (!invoice.canRecordPayment) {
          throw const AppException(
            'Payments can only be recorded on unpaid finalized invoices.',
          );
        }
        if (amountCents <= 0) {
          throw const AppException('Payment amount must be greater than zero.');
        }
        if (amountCents > invoice.balanceRemainingCents) {
          throw const AppException(
            'Payment cannot exceed the outstanding balance.',
          );
        }

        final newAmountPaid = invoice.amountPaidCents + amountCents;
        final newBalance = invoice.grandTotalCents - newAmountPaid;
        final nextStatus = invoice.statusAfterPayment(
          newAmountPaidCents: newAmountPaid,
          newBalanceRemainingCents: newBalance,
        );

        final now = DateTime.now();
        final withId = Payment(
          paymentId: paymentRef.id,
          businessId: invoice.businessId,
          invoiceId: invoice.invoiceId,
          customerId: invoice.customerId,
          amountCents: amountCents,
          paymentMethod: paymentMethod,
          reference: reference,
          notes: notes,
          receivedAt: receivedAt,
          createdAt: now,
          invoiceNumber: invoice.invoiceNumber,
          customerName: invoice.customerName,
        );

        transaction.set(paymentRef, withId.toMap());
        transaction.update(invoiceRef, {
          'amountPaid': newAmountPaid,
          'balanceRemaining': newBalance,
          'status': nextStatus.firestoreValue,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return withId;
      });
    } on AppException {
      rethrow;
    } on FirebaseException catch (_) {
      throw const AppException('Unable to record payment.');
    }
  }
}
