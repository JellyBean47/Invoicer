import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/business.dart';
import '../models/user_profile.dart';
import '../repositories/auth_repository.dart';
import '../repositories/business_repository.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';
import '../services/business_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return BusinessRepository();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    authRepository: ref.watch(authRepositoryProvider),
    userRepository: ref.watch(userRepositoryProvider),
  );
});

final businessServiceProvider = Provider<BusinessService>((ref) {
  return BusinessService(
    businessRepository: ref.watch(businessRepositoryProvider),
    userRepository: ref.watch(userRepositoryProvider),
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    return Stream.value(null);
  }
  return ref.watch(authServiceProvider).watchProfile(user.uid);
});

final businessProvider = FutureProvider<Business?>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  if (profile == null || !profile.hasBusiness) return null;
  return ref.watch(businessServiceProvider).getById(profile.businessId);
});
