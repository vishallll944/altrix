import 'package:firebase_messaging/firebase_messaging.dart';

abstract class PushNotifications {
  Future<void> initialize();
  Future<void> syncTokenForCurrentUser();
  Future<void> clearDeviceTokens();
  Future<void> saveDeviceToken(String token);

  /// Stream of foreground FCM messages for in-app banner display.
  Stream<RemoteMessage> get onForegroundMessage;
}
