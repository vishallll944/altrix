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
}
