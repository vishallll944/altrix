import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether this patient's app is in the foreground (active).
/// Used to show/hide the "Online" green dot on the conversation list —
/// the patient is "online" when the app is in the foreground.
class AppPresenceNotifier extends StateNotifier<bool>
    with WidgetsBindingObserver {
  AppPresenceNotifier() : super(true) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        this.state = true;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        this.state = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// True when the app is in the foreground (patient is "online").
final appPresenceProvider = StateNotifierProvider<AppPresenceNotifier, bool>(
  (ref) => AppPresenceNotifier(),
);

/// Per-conversation online presence for the other participant (clinician).
/// We use a simple heartbeat approach: the clinician is considered "online"
/// when we have received at least one SSE/socket event in the last 5 minutes
/// OR when the SSE stream is active.
class ClinicianPresenceNotifier extends StateNotifier<bool> {
  ClinicianPresenceNotifier() : super(false);

  Timer? _offlineTimer;

  /// Call this whenever we receive any live activity (SSE/socket event)
  /// from the clinician side. Marks them online for 5 minutes.
  void markOnline() {
    state = true;
    _offlineTimer?.cancel();
    _offlineTimer = Timer(const Duration(minutes: 5), () {
      state = false;
    });
  }

  void markOffline() {
    _offlineTimer?.cancel();
    state = false;
  }

  @override
  void dispose() {
    _offlineTimer?.cancel();
    super.dispose();
  }
}

/// Family provider — one per conversation ID.
final clinicianPresenceProvider =
    StateNotifierProvider.family<ClinicianPresenceNotifier, bool, String>(
  (ref, conversationId) => ClinicianPresenceNotifier(),
);
