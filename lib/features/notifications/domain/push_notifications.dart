import 'package:firebase_messaging/firebase_messaging.dart';

abstract class PushNotifications {
  Future<void> initialize();
  Future<void> syncTokenForCurrentUser();
  Future<void> clearDeviceTokens();
  Future<void> saveDeviceToken(String token);

  /// Provide the JWT auth token so the service can register the device
  /// token with the backend API (used after login / session restore).
  void setAuthToken(String token);

  /// Stream of foreground FCM messages for in-app banner display.
  Stream<RemoteMessage> get onForegroundMessage;
}

