import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../core/utils/app_exception.dart';
import '../models/app_notification.dart';

class NotificationRepository {
  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection(FirestoreCollections.notifications);
  }

  Stream<List<AppNotification>> watchByBusiness(String businessId) {
    return _collection
        .where('businessId', isEqualTo: businessId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppNotification.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<AppNotification> create(AppNotification notification) async {
    try {
      final ref = _collection.doc();
      final created = AppNotification(
        notificationId: ref.id,
        businessId: notification.businessId,
        title: notification.title,
        message: notification.message,
        type: notification.type,
        read: notification.read,
        createdAt: notification.createdAt,
        route: notification.route,
        entityType: notification.entityType,
        entityId: notification.entityId,
      );
      await ref.set(created.toMap());
      return created;
    } on FirebaseException catch (_) {
      throw const AppException('Unable to create notification.');
    }
  }

  Future<void> markRead(String notificationId) async {
    try {
      await _collection.doc(notificationId).update({'read': true});
    } on FirebaseException catch (_) {
      throw const AppException('Unable to update notification.');
    }
  }

  Future<void> markAllRead(String businessId) async {
    try {
      final snapshot = await _collection
          .where('businessId', isEqualTo: businessId)
          .where('read', isEqualTo: false)
          .get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } on FirebaseException catch (_) {
      throw const AppException('Unable to mark notifications as read.');
    }
  }

  Future<void> clearHistory(String businessId) async {
    try {
      final snapshot = await _collection
          .where('businessId', isEqualTo: businessId)
          .get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } on FirebaseException catch (_) {
      throw const AppException('Unable to clear notification history.');
    }
  }
}
