import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Thin FCM wrapper. Safe when permission is denied or messaging unavailable.
class FcmService {
  FcmService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;
  String? _token;

  String? get token => _token;

  Future<void> initialize({
    void Function(RemoteMessage message)? onForegroundMessage,
  }) async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      _token = await _messaging.getToken();
      FirebaseMessaging.onMessage.listen((message) {
        onForegroundMessage?.call(message);
      });
    } catch (error, stack) {
      debugPrint('FCM initialize skipped: $error\n$stack');
    }
  }
}
