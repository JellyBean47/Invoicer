import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../repositories/settings_repository.dart';
import '../services/local_notification_service.dart';
import '../services/settings_service.dart';
import 'app_providers.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService(
    settingsRepository: ref.watch(settingsRepositoryProvider),
    businessRepository: ref.watch(businessRepositoryProvider),
  );
});

final localNotificationServiceProvider =
    Provider<LocalNotificationService>((ref) {
  return LocalNotificationService();
});

final appSettingsProvider = StreamProvider<AppSettings?>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final businessId = profile?.businessId;
  if (businessId == null || businessId.isEmpty) {
    return Stream.value(null);
  }
  return ref.watch(settingsServiceProvider).watchSettings(businessId);
});
