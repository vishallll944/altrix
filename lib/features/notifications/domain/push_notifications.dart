abstract class PushNotifications {
  Future<void> initialize();
  Future<void> syncTokenForCurrentUser();
  Future<void> clearDeviceTokens();
  Future<void> saveDeviceToken(String token);
}
