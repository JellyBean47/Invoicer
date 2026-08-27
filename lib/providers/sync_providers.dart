import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sync_queue_entry.dart';
import '../repositories/sync_queue_repository.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import 'app_providers.dart';
import 'notification_providers.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final syncQueueRepositoryProvider = Provider<SyncQueueRepository>((ref) {
  return SyncQueueRepository();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    syncQueueRepository: ref.watch(syncQueueRepositoryProvider),
    notificationService: ref.watch(notificationServiceProvider),
  );
});

final isOnlineProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).watchIsOnline();
});

final pendingSyncProvider = StreamProvider<List<SyncQueueEntry>>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final businessId = profile?.businessId;
  if (businessId == null || businessId.isEmpty) {
    return Stream.value(const []);
  }
  return ref.watch(syncServiceProvider).watchPending(businessId);
});
