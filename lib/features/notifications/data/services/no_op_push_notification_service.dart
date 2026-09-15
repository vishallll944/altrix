import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../domain/push_notifications.dart';

class NoOpPushNotificationService implements PushNotifications {
  const NoOpPushNotificationService();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> syncTokenForCurrentUser() async {}

  @override
  Future<void> clearDeviceTokens() async {}

  @override
  Future<void> saveDeviceToken(String token) async {}

  @override
  Stream<RemoteMessage> get onForegroundMessage =>
      const Stream<RemoteMessage>.empty();
}
