import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../core/utils/app_exception.dart';
import '../models/sync_queue_entry.dart';

class SyncQueueRepository {
  SyncQueueRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection(FirestoreCollections.syncQueue);
  }

  Stream<List<SyncQueueEntry>> watchPending(String businessId) {
    return _collection
        .where('businessId', isEqualTo: businessId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SyncQueueEntry.fromMap(doc.data()))
              .where(
                (entry) =>
                    entry.status == SyncStatus.pending ||
                    entry.status == SyncStatus.processing ||
                    entry.status == SyncStatus.failed,
              )
              .toList(),
        );
  }

  Future<SyncQueueEntry> enqueue(SyncQueueEntry entry) async {
    try {
      final ref = _collection.doc();
      final created = SyncQueueEntry(
        operationId: ref.id,
        businessId: entry.businessId,
        entityType: entry.entityType,
        entityId: entry.entityId,
        operation: entry.operation,
        payload: entry.payload,
        createdAt: entry.createdAt,
        retryCount: entry.retryCount,
        status: entry.status,
        lastError: entry.lastError,
      );
      await ref.set(created.toMap());
      return created;
    } on FirebaseException catch (_) {
      throw const AppException('Unable to queue offline change.');
    }
  }

  Future<void> updateStatus({
    required String operationId,
    required SyncStatus status,
    int? retryCount,
    String lastError = '',
  }) async {
    try {
      await _collection.doc(operationId).update({
        'status': status.name,
        'retryCount': ?retryCount,
        'lastError': lastError,
      });
    } on FirebaseException catch (_) {
      throw const AppException('Unable to update sync queue.');
    }
  }

  Future<List<SyncQueueEntry>> listRetryable(String businessId) async {
    try {
      final snapshot = await _collection
          .where('businessId', isEqualTo: businessId)
          .where('status', whereIn: [
            SyncStatus.pending.name,
            SyncStatus.failed.name,
          ])
          .get();
      return snapshot.docs
          .map((doc) => SyncQueueEntry.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (_) {
      throw const AppException('Unable to load sync queue.');
    }
  }
}
