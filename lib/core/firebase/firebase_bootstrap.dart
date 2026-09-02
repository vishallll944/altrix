import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../../features/notifications/data/services/no_op_push_notification_service.dart';
import '../../features/notifications/data/services/push_notification_service.dart';
import '../../features/notifications/domain/push_notifications.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static bool get isConfigured {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      return options.apiKey.isNotEmpty &&
          !options.apiKey.startsWith('REPLACE_WITH');
    } catch (_) {
      return false;
    }
  }

  static Future<PushNotifications> initialize() async {
    if (_initialized) {
      return PushNotificationService();
    }

    if (!isConfigured) {
      debugPrint(
        'Firebase is not configured for this platform yet. '
        'Run: flutterfire configure --project=altrixs-3d917',
      );
      return const NoOpPushNotificationService();
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;

      final pushNotificationService = PushNotificationService();
      await pushNotificationService.initialize();
      return pushNotificationService;
    } catch (error, stackTrace) {
      debugPrint('Firebase initialization failed: $error');
      debugPrint('$stackTrace');
      return const NoOpPushNotificationService();
    }
  }
}
