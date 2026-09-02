import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../data/services/no_op_push_notification_service.dart';
import '../../data/services/push_notification_service.dart';
import '../../domain/push_notifications.dart';

final pushNotificationServiceProvider = Provider<PushNotifications>((ref) {
  if (!FirebaseBootstrap.isInitialized) {
    return const NoOpPushNotificationService();
  }
  return PushNotificationService();
});
