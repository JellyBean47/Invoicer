import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../core/utils/app_exception.dart';
import '../models/user_profile.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) {
    return _firestore.collection(FirestoreCollections.users).doc(uid);
  }

  Future<UserProfile?> getById(String uid) async {
    try {
      final snapshot = await _doc(uid).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      return UserProfile.fromMap(snapshot.data()!);
    } on FirebaseException catch (_) {
      throw const AppException('Unable to load your profile right now.');
    }
  }

  Stream<UserProfile?> watchById(String uid) {
    return _doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return UserProfile.fromMap(snapshot.data()!);
    });
  }

  Future<void> create(UserProfile profile) async {
    try {
      await _doc(profile.uid).set(profile.toMap());
    } on FirebaseException catch (_) {
      throw const AppException('Unable to create your profile.');
    }
  }

  Future<void> update(UserProfile profile) async {
    try {
      await _doc(profile.uid).update(profile.toMap());
    } on FirebaseException catch (_) {
      throw const AppException('Unable to update your profile.');
    }
  }

  Future<void> setBusinessId({
    required String uid,
    required String businessId,
  }) async {
    try {
      await _doc(uid).update({'businessId': businessId});
    } on FirebaseException catch (_) {
      throw const AppException('Unable to link your business profile.');
    }
  }

  Future<void> touchLastLogin(String uid) async {
    try {
      await _doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (_) {
      // Non-critical — ignore silently.
    }
  }
}
