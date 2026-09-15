import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/patient_models.dart';

/// Holds the live message list for a conversation in memory so messages
/// survive screen pop/push (WhatsApp-like persistence).
class ChatMessagesNotifier extends StateNotifier<List<MessageModel>> {
  ChatMessagesNotifier() : super([]);

  bool get isEmpty => state.isEmpty;

  /// Merge an incoming batch (from poll or SSE) into the current list.
  /// - Adds only genuinely new messages (by id).
  /// - Promotes pending messages whose body matches a confirmed server message.
  /// - Never removes messages the user already sees.
  /// Returns true if the state changed.
  bool merge(List<MessageModel> incoming) {
    if (incoming.isEmpty) return false;

    // Build a map: body → confirmed server id for promotion of pending msgs
    final confirmedBodies = <String, String>{};
    for (final m in incoming) {
      if (!m.isPending) confirmedBodies[m.body] = m.id;
    }

    // Promote or keep existing messages
    final updated = state.map((m) {
      if (m.isPending && confirmedBodies.containsKey(m.body)) {
        final confirmedId = confirmedBodies[m.body]!;
        final confirmed = incoming.firstWhere(
          (inc) => inc.id == confirmedId,
          orElse: () => m.copyWith(isPending: false),
        );
        return confirmed;
      }
      return m;
    }).toList();

    // Append genuinely new messages not already in list
    final updatedIds = {for (final m in updated) m.id};
    for (final m in incoming) {
      if (!updatedIds.contains(m.id)) {
        updated.add(m);
      }
    }

    // Sort by createdAt to keep chronological order
    updated.sort((a, b) {
      final ta = DateTime.tryParse(a.createdAt);
      final tb = DateTime.tryParse(b.createdAt);
      if (ta == null && tb == null) return 0;
      if (ta == null) return -1;
      if (tb == null) return 1;
      return ta.compareTo(tb);
    });

    final changed = updated.length != state.length ||
        updated.asMap().entries.any((e) {
          if (e.key >= state.length) return true;
          final old = state[e.key];
          return e.value.id != old.id ||
              e.value.isPending != old.isPending ||
              e.value.hasError != old.hasError;
        });

    if (changed) {
      state = updated;
      return true;
    }
    return false;
  }

  /// Add an optimistic (pending) message immediately on send.
  void addOptimistic(MessageModel message) {
    state = [...state, message];
  }

  /// Replace a pending message (by tempId) with the confirmed server version.
  void confirmMessage(String tempId, MessageModel confirmed) {
    final idx = state.indexWhere((m) => m.id == tempId);
    if (idx != -1) {
      final updated = List<MessageModel>.from(state);
      updated[idx] = confirmed;
      state = updated;
    } else if (!state.any((m) => m.id == confirmed.id)) {
      state = [...state, confirmed];
    }
  }

  /// Mark a pending message as failed (by tempId).
  void failMessage(String tempId) {
    final idx = state.indexWhere((m) => m.id == tempId);
    if (idx != -1) {
      final updated = List<MessageModel>.from(state);
      updated[idx] = state[idx].copyWith(isPending: false, hasError: true);
      state = updated;
    }
  }

  /// Seed with initial messages (only when list is empty to avoid overwrite).
  void seedIfEmpty(List<MessageModel> messages) {
    if (state.isEmpty && messages.isNotEmpty) {
      state = List.of(messages);
    } else if (messages.isNotEmpty) {
      merge(messages);
    }
  }

  /// Reset the message list (e.g. on logout or conversation switch).
  void reset() => state = [];
}

/// Family provider — one notifier per conversation ID.
/// autoDispose is intentionally NOT used so messages persist across navigation.
final chatMessagesProvider =
    StateNotifierProvider.family<ChatMessagesNotifier, List<MessageModel>, String>(
  (ref, conversationId) => ChatMessagesNotifier(),
);
