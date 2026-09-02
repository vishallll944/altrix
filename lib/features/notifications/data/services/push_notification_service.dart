import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../domain/push_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.messageId}');
}

class PushNotificationService implements PushNotifications {
  PushNotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _messaging = messaging,
        _firestore = firestore,
        _auth = auth;

  FirebaseMessaging? _messaging;
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;

  FirebaseMessaging get _messagingInstance =>
      _messaging ??= FirebaseMessaging.instance;

  FirebaseFirestore get _firestoreInstance =>
      _firestore ??= FirebaseFirestore.instance;

  FirebaseAuth get _authInstance => _auth ??= FirebaseAuth.instance;

  @override
  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermission();
    await _configureForegroundPresentation();

    final token = await _messagingInstance.getToken();
    if (token != null) {
      await saveDeviceToken(token);
    }

    _messagingInstance.onTokenRefresh.listen(saveDeviceToken);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
  }

  @override
  Future<void> syncTokenForCurrentUser() async {
    final token = await _messagingInstance.getToken();
    if (token != null) {
      await saveDeviceToken(token);
    }
  }

  @override
  Future<void> clearDeviceTokens() async {
    final uid = _authInstance.currentUser?.uid;
    if (uid == null) return;

    final tokens = await _firestoreInstance
        .collection('users')
        .doc(uid)
        .collection('deviceTokens')
        .get();

    final batch = _firestoreInstance.batch();
    for (final doc in tokens.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Future<void> saveDeviceToken(String token) async {
    final uid = _authInstance.currentUser?.uid;
    if (uid == null || token.isEmpty) return;

    await _firestoreInstance
        .collection('users')
        .doc(uid)
        .collection('deviceTokens')
        .doc(token)
        .set(
      {
        'token': token,
        'platform': defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _requestPermission() async {
    await _messagingInstance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<void> _configureForegroundPresentation() async {
    await _messagingInstance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FCM foreground message: ${message.notification?.title}');
  }

  void _handleOpenedMessage(RemoteMessage message) {
    debugPrint('FCM opened from notification: ${message.data}');
  }
}
