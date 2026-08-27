import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../core/utils/app_exception.dart';
import '../models/app_settings.dart';
import '../models/business.dart';

class BusinessRepository {
  BusinessRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String businessId) {
    return _firestore.collection(FirestoreCollections.businesses).doc(businessId);
  }

  Future<Business?> getById(String businessId) async {
    if (businessId.isEmpty) return null;
    try {
      final snapshot = await _doc(businessId).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      return Business.fromMap(snapshot.data()!);
    } on FirebaseException catch (_) {
      throw const AppException('Unable to load business details.');
    }
  }

  Future<Business> create(Business business) async {
    try {
      final ref = _firestore.collection(FirestoreCollections.businesses).doc();
      final created = Business(
        businessId: ref.id,
        businessName: business.businessName,
        ownerName: business.ownerName,
        phone: business.phone,
        email: business.email,
        address: business.address,
        registrationNumber: business.registrationNumber,
        vatNumber: business.vatNumber,
        currency: business.currency,
        defaultTaxPercent: business.defaultTaxPercent,
        invoicePrefix: business.invoicePrefix,
        invoiceCounter: business.invoiceCounter,
        logoUrl: business.logoUrl,
        createdAt: business.createdAt,
        updatedAt: business.updatedAt,
      );
      await ref.set(created.toMap());
      return created;
    } on FirebaseException catch (_) {
      throw const AppException('Unable to create your business profile.');
    }
  }

  Future<void> createDefaultSettings(Business business) async {
    try {
      final defaults = AppSettings.defaults(business.businessId).copyWith(
        currency: business.currency,
        defaultTaxPercent: business.defaultTaxPercent,
        invoicePrefix: business.invoicePrefix,
        invoiceCounter: business.invoiceCounter,
      );
      await _firestore
          .collection(FirestoreCollections.settings)
          .doc(business.businessId)
          .set({
        ...defaults.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (_) {
      throw const AppException('Unable to create business settings.');
    }
  }

  Future<void> updateFields({
    required String businessId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _doc(businessId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (_) {
      throw const AppException('Unable to update business details.');
    }
  }
}
