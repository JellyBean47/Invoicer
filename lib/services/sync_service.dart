import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sync_queue_entry.dart';
import '../repositories/sync_queue_repository.dart';
import 'notification_service.dart';

/// Offline polish: track pending queue + flush Firestore writes when online.
class SyncService {
  SyncService({
    required SyncQueueRepository syncQueueRepository,
    required NotificationService notificationService,
    FirebaseFirestore? firestore,
  })  : _syncQueueRepository = syncQueueRepository,
        _notificationService = notificationService,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final SyncQueueRepository _syncQueueRepository;
  final NotificationService _notificationService;
  final FirebaseFirestore _firestore;

  Stream<List<SyncQueueEntry>> watchPending(String businessId) {
    return _syncQueueRepository.watchPending(businessId);
  }

  Future<SyncQueueEntry> enqueue({
    required String businessId,
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    Map<String, dynamic> payload = const {},
  }) {
    return _syncQueueRepository.enqueue(
      SyncQueueEntry(
        operationId: '',
        businessId: businessId,
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payload: payload,
        createdAt: DateTime.now(),
        retryCount: 0,
        status: SyncStatus.pending,
      ),
    );
  }

  /// Waits for Firestore pending writes, then marks retryable queue items done.
  Future<bool> flush({
    required String businessId,
    required bool notify,
  }) async {
    try {
      await _firestore.waitForPendingWrites();
      final pending = await _syncQueueRepository.listRetryable(businessId);
      for (final entry in pending) {
        await _syncQueueRepository.updateStatus(
          operationId: entry.operationId,
          status: SyncStatus.completed,
        );
      }
      if (notify) {
        await _notificationService.notifySync(
          businessId: businessId,
          success: true,
        );
      }
      return true;
    } catch (_) {
      if (notify) {
        await _notificationService.notifySync(
          businessId: businessId,
          success: false,
        );
      }
      return false;
    }
  }
}
