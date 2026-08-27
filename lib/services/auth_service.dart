import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/app_exception.dart';
import '../models/user_profile.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';

class AuthService {
  AuthService({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  })  : _authRepository = authRepository,
        _userRepository = userRepository;

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  Stream<User?> authStateChanges() => _authRepository.authStateChanges();

  User? get currentUser => _authRepository.currentUser;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _authRepository.signIn(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw const AppException('Unable to sign in right now.');
    }
    await _ensureUserProfile(user);
    await _userRepository.touchLastLogin(user.uid);
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _authRepository.register(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw const AppException('Unable to create your account.');
    }
    if (displayName.trim().isNotEmpty) {
      await user.updateDisplayName(displayName.trim());
    }
    await _ensureUserProfile(user, displayName: displayName.trim());
  }

  Future<void> sendPasswordReset(String email) {
    return _authRepository.sendPasswordReset(email);
  }

  Future<void> resendVerificationEmail() {
    return _authRepository.sendEmailVerification();
  }

  Future<bool> refreshEmailVerification() async {
    await _authRepository.reloadUser();
    final user = _authRepository.currentUser;
    if (user == null) return false;
    final profile = await _userRepository.getById(user.uid);
    if (profile != null && profile.emailVerified != user.emailVerified) {
      await _userRepository.update(
        profile.copyWith(emailVerified: user.emailVerified),
      );
    }
    return user.emailVerified;
  }

  Future<void> signOut() => _authRepository.signOut();

  Future<UserProfile?> loadProfile(String uid) {
    return _userRepository.getById(uid);
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _userRepository.watchById(uid);
  }

  Future<void> _ensureUserProfile(User user, {String? displayName}) async {
    final existing = await _userRepository.getById(user.uid);
    if (existing != null) return;

    final profile = UserProfile(
      uid: user.uid,
      email: user.email ?? '',
      businessId: '',
      displayName: displayName?.isNotEmpty == true
          ? displayName!
          : (user.displayName ?? ''),
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
      role: AppConstants.defaultRole,
      status: 'active',
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );
    await _userRepository.create(profile);
  }
}
