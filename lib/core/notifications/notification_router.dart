import 'package:flutter/material.dart';

import '../navigation/app_navigator.dart';
import '../../features/patient/presentation/screens/medications_screen.dart';
import '../../features/telehealth/presentation/screens/telehealth_room_screen.dart';
import '../../screens/conversation_detail_screen.dart';

/// Central router that translates FCM [data] payloads into screen navigations.
///
/// Called from two places:
///  1. [PushNotificationService._handleOpenedMessage] — user tapped the system
///     notification while the app was backgrounded / terminated.
///  2. [InAppNotificationOverlay._onMessage] — user tapped the in-app banner
///     while the app was in the foreground.
///
/// Navigation types are determined by data['type']:
///
/// | type                   | destination                           |
/// |------------------------|---------------------------------------|
/// | medication_reminder    | MedicationsScreen (push route)        |
/// | appointment_reminder   | Schedule tab (index 1)                |
/// | chat_message           | Messages tab (index 2) or conv detail |
/// | telehealth_call        | TelehealthRoomScreen (push route)     |
class NotificationRouter {
  NotificationRouter._();

  /// Optional callback registered by [MainShell] to switch bottom-nav tabs.
  static ValueSetter<int>? _switchTabCallback;

  static void registerTabSwitcher(ValueSetter<int> callback) {
    _switchTabCallback = callback;
  }

  static void unregisterTabSwitcher() {
    _switchTabCallback = null;
  }

  /// Main entry point — handles a push notification [data] map.
  static void handleTap(Map<String, dynamic> data) {
    final type = (data['type'] as String? ?? '').trim();
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;

    debugPrint('[NotificationRouter] handling type="$type" data=$data');

    switch (type) {
      case 'medication_reminder':
        nav.push(
          MaterialPageRoute<void>(
            builder: (_) => const MedicationsScreen(),
            settings: const RouteSettings(name: '/medications'),
          ),
        );

      case 'appointment_reminder':
        // Bring Schedule tab to front (no extra route pushed).
        _switchTabCallback?.call(1);

      case 'chat_message':
        final threadId = (data['threadId'] as String? ?? '').trim();
        if (threadId.isNotEmpty) {
          // Switch to messages tab and push the conversation detail.
          _switchTabCallback?.call(2);
          nav.push(
            MaterialPageRoute<void>(
              builder: (_) => ConversationDetailScreen(
                conversationId: threadId,
                title: 'Messages',
              ),
              settings: RouteSettings(name: '/chat/$threadId'),
            ),
          );
        } else {
          _switchTabCallback?.call(2);
        }

      case 'telehealth_call':
        final sessionId = (data['sessionId'] as String? ?? '').trim();
        final joinToken =
            (data['joinToken'] as String? ?? sessionId).trim();
        if (joinToken.isNotEmpty) {
          nav.push(
            MaterialPageRoute<void>(
              builder: (_) => TelehealthRoomScreen(joinToken: joinToken),
              settings: RouteSettings(name: '/telehealth/$joinToken'),
            ),
          );
        }

      default:
        debugPrint(
          '[NotificationRouter] Unknown notification type: "$type" — ignoring.',
        );
    }
  }
}
