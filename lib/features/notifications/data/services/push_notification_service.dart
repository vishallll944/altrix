import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../domain/push_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.notification?.title}');
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

  final _foregroundController = StreamController<RemoteMessage>.broadcast();

  FirebaseMessaging get _messagingInstance =>
      _messaging ??= FirebaseMessaging.instance;

  FirebaseFirestore get _firestoreInstance =>
      _firestore ??= FirebaseFirestore.instance;

  FirebaseAuth get _authInstance => _auth ??= FirebaseAuth.instance;

  @override
  Stream<RemoteMessage> get onForegroundMessage =>
      _foregroundController.stream;

  @override
  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermission();
    await _configureForegroundPresentation();

    final token = await _messagingInstance.getToken();
    if (token != null) {
      await saveDeviceToken(token);
      debugPrint('[FCM] Device token: $token');
    }

    _messagingInstance.onTokenRefresh.listen(saveDeviceToken);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    // Check if app was launched via a notification
    final initialMessage = await _messagingInstance.getInitialMessage();
    if (initialMessage != null) {
      _handleOpenedMessage(initialMessage);
    }
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

    try {
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
    } catch (e) {
      debugPrint('[FCM] clearDeviceTokens error: $e');
    }
  }

  @override
  Future<void> saveDeviceToken(String token) async {
    final uid = _authInstance.currentUser?.uid;
    if (uid == null || token.isEmpty) return;

    try {
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
    } catch (e) {
      debugPrint('[FCM] saveDeviceToken error: $e');
    }
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

  /// Emits the message to the in-app banner stream.
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground: ${message.notification?.title}');
    _foregroundController.add(message);
  }

  void _handleOpenedMessage(RemoteMessage message) {
    debugPrint('[FCM] Opened from notification: ${message.data}');
    // Navigation on tap is handled by the app-level listener.
  }
}
