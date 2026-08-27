import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../core/utils/app_exception.dart';
import '../models/timeline_entry.dart';

class TimelineRepository {
  TimelineRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection(FirestoreCollections.activityLogs);
  }

  Stream<List<TimelineEntry>> watchForEntity({
    required String businessId,
    required String entityType,
    required String entityId,
  }) {
    return _collection
        .where('businessId', isEqualTo: businessId)
        .where('entityType', isEqualTo: entityType)
        .where('entityId', isEqualTo: entityId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TimelineEntry.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<TimelineEntry> add(TimelineEntry entry) async {
    try {
      final ref = _collection.doc();
      final created = TimelineEntry(
        logId: ref.id,
        businessId: entry.businessId,
        userId: entry.userId,
        entityType: entry.entityType,
        entityId: entry.entityId,
        action: entry.action,
        oldValue: entry.oldValue,
        newValue: entry.newValue,
        timestamp: entry.timestamp,
        device: entry.device,
        isManualNote: entry.isManualNote,
      );
      await ref.set(created.toMap());
      return created;
    } on FirebaseException catch (_) {
      throw const AppException('Unable to save timeline entry.');
    }
  }

  Future<void> updateNote({
    required String logId,
    required String note,
  }) async {
    try {
      await _collection.doc(logId).update({
        'newValue': note,
        'action': 'note',
        'isManualNote': true,
      });
    } on FirebaseException catch (_) {
      throw const AppException('Unable to update note.');
    }
  }
}
