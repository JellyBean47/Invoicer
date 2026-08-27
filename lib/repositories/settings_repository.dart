import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../core/utils/app_exception.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String businessId) {
    return _firestore.collection(FirestoreCollections.settings).doc(businessId);
  }

  Stream<AppSettings?> watch(String businessId) {
    if (businessId.isEmpty) return Stream.value(null);
    return _doc(businessId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return AppSettings.fromMap(snapshot.data()!);
    });
  }

  Future<AppSettings?> getByBusinessId(String businessId) async {
    if (businessId.isEmpty) return null;
    try {
      final snapshot = await _doc(businessId).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      return AppSettings.fromMap(snapshot.data()!);
    } on FirebaseException catch (_) {
      throw const AppException('Unable to load settings.');
    }
  }

  Future<AppSettings> ensureDefaults(String businessId) async {
    final existing = await getByBusinessId(businessId);
    if (existing != null) return existing;
    final defaults = AppSettings.defaults(businessId);
    try {
      await _doc(businessId).set(defaults.toMap());
      return defaults;
    } on FirebaseException catch (_) {
      throw const AppException('Unable to create settings.');
    }
  }

  Future<void> save(AppSettings settings) async {
    try {
      await _doc(settings.businessId).set({
        ...settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (_) {
      throw const AppException('Unable to save settings.');
    }
  }
}
