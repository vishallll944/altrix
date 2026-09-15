import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/providers/auth_token_provider.dart';
import '../features/patient/data/models/patient_models.dart';
import '../features/patient/data/services/chat_socket_service.dart';
import '../features/patient/presentation/providers/chat_messages_provider.dart';
import '../features/patient/presentation/providers/patient_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state_card.dart';

class ConversationDetailScreen extends ConsumerStatefulWidget {
  const ConversationDetailScreen({
    super.key,
    required this.conversationId,
    required this.title,
    this.participantName = '',
    this.avatarUrl = '',
  });

  final String conversationId;
  final String title;
  final String participantName;
  final String avatarUrl;

  @override
  ConsumerState<ConversationDetailScreen> createState() =>
      ConversationDetailScreenState();
}

class ConversationDetailScreenState
    extends ConsumerState<ConversationDetailScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  late final ChatSocketService _socketService;
  StreamSubscription<MessageModel>? _messageSub;
  StreamSubscription<bool>? _typingSub;
  StreamSubscription<String>? _presenceSub;
  StreamSubscription<Map<String, dynamic>>? _sseSub;
  Timer? _livePollTimer;
  Timer? _typingDebounceTimer;

  bool _isLoading = true;
  String? _error;
  bool _isSending = false;
  bool _isDoctorTyping = false;
  String _doctorPresenceStatus = 'online';
  late String _threadId;

  // Track if user is near the bottom so we only auto-scroll when appropriate
  bool _userIsNearBottom = true;

  @override
  void initState() {
    super.initState();
    _threadId = widget.conversationId;
    _socketService = ChatSocketService();

    _scrollController.addListener(_onScroll);
    _initChat();
  }

  @override
  void dispose() {
    _sseSub?.cancel();
    _livePollTimer?.cancel();
    _messageSub?.cancel();
    _typingSub?.cancel();
    _presenceSub?.cancel();
    _typingDebounceTimer?.cancel();
    _socketService.dispose();
    _controller.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    // Consider "near bottom" if within 120px of the bottom
    _userIsNearBottom = (pos.maxScrollExtent - pos.pixels) < 120;
  }

  void _initChat() async {
    // If we already have messages cached, show them immediately (no loading
    // spinner on re-entry — WhatsApp-like instant history)
    final cached = ref.read(chatMessagesProvider(_threadId));
    if (cached.isNotEmpty) {
      setState(() => _isLoading = false);
      _scrollToBottomImmediate();
    }

    await _fetchInitialMessages();
    _startLiveSync();
    _connectSocket();
  }

  void _startLiveSync() async {
    _sseSub?.cancel();
    _livePollTimer?.cancel();

    if (_threadId.isEmpty) return;

    String? token;
    try {
      token = ref.read(authTokenProvider);
      if (token == null || token.isEmpty) {
        token = await ref.read(authSessionStorageProvider).readToken();
      }
    } catch (_) {
      token = null;
    }

    if (token != null && token.isNotEmpty) {
      try {
        _sseSub = ref
            .read(patientRepositoryProvider)
            .streamLiveMessages(threadId: _threadId, token: token)
            .listen(
              (payload) {
                if (!mounted) return;
                final messageMap = payload['message'] is Map<String, dynamic>
                    ? payload['message'] as Map<String, dynamic>
                    : (payload['data'] is Map<String, dynamic>
                          ? payload['data'] as Map<String, dynamic>
                          : payload);
                if (messageMap['id'] != null) {
                  final incoming = MessageModel.fromJson(messageMap);
                  _mergeMessages([incoming], isFromRealtime: true);
                }
              },
              onError: (_) {},
              cancelOnError: false,
            );
      } catch (_) {}
    }

    // Periodic live sync poll every 10 seconds as fallback to SSE stream
    _livePollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || _threadId.isEmpty) return;
      _pollLiveMessages();
    });
  }

  Future<void> _pollLiveMessages() async {
    try {
      final messages = await ref
          .read(patientRepositoryProvider)
          .getConversationMessages(conversationId: _threadId);
      if (!mounted) return;
      // Poll updates silently — only scroll if user is near bottom
      _mergeMessages(messages, isFromRealtime: false);
    } catch (_) {}
  }

  Future<void> _fetchInitialMessages() async {
    final cached = ref.read(chatMessagesProvider(_threadId));
    if (cached.isEmpty) {
      // Only show loading indicator when there's nothing to show
      if (mounted) setState(() { _isLoading = true; _error = null; });
    }

    try {
      final result = await ref
          .read(patientRepositoryProvider)
          .getPatientMessages(
            threadId: _threadId.isNotEmpty ? _threadId : null,
          );
      if (!mounted) return;
      if (result.threadId.isNotEmpty) {
        _threadId = result.threadId;
      }
      ref.read(chatMessagesProvider(_threadId).notifier).seedIfEmpty(result.messages);
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _scrollToBottom(force: true);
      _markIncomingAsRead(result.messages);
    } catch (err) {
      try {
        if (_threadId.isNotEmpty) {
          final messages = await ref
              .read(patientRepositoryProvider)
              .getConversationMessages(conversationId: _threadId);
          if (!mounted) return;
          ref.read(chatMessagesProvider(_threadId).notifier).seedIfEmpty(messages);
          if (mounted) setState(() => _isLoading = false);
          _scrollToBottom(force: true);
          _markIncomingAsRead(messages);
        } else {
          if (!mounted) return;
          setState(() => _isLoading = false);
        }
      } catch (innerErr) {
        if (!mounted) return;
        // Only show error if we have no cached messages
        final cached2 = ref.read(chatMessagesProvider(_threadId));
        setState(() {
          if (cached2.isEmpty) _error = friendlyErrorMessage(err);
          _isLoading = false;
        });
      }
    }
  }



  void _connectSocket() async {
    final user = ref.read(authProvider).user;
    final patientId = user?.id ?? 'patient_${DateTime.now().millisecondsSinceEpoch}';
    final patientName = user?.name ?? 'Patient';

    String? token;
    try {
      token = ref.read(authTokenProvider);
      if (token == null || token.isEmpty) {
        token = await ref.read(authSessionStorageProvider).readToken();
      }
    } catch (_) {
      token = null;
    }

    _socketService.connectSocket(
      patientId: patientId,
      patientName: patientName,
      threadId: _threadId,
      token: token,
    );

    _messageSub?.cancel();
    _messageSub = _socketService.onNewMessage.listen((incoming) {
      if (!mounted) return;
      _mergeMessages([incoming], isFromRealtime: true);
    });

    _typingSub?.cancel();
    _typingSub = _socketService.onTypingStatus.listen((isTyping) {
      if (!mounted) return;
      setState(() => _isDoctorTyping = isTyping);
      if (isTyping && _userIsNearBottom) {
        _scrollToBottom();
      }
    });

    _presenceSub?.cancel();
    _presenceSub = _socketService.onPresenceChange.listen((status) {
      if (!mounted) return;
      setState(() => _doctorPresenceStatus = status);
    });
  }

  void _onTextChanged(String text) {
    final user = ref.read(authProvider).user;
    final patientId = user?.id ?? 'patient';
    final patientName = user?.name ?? 'Patient';

    if (text.trim().isNotEmpty) {
      _socketService.sendTypingStart(_threadId, patientId, patientName);
      _typingDebounceTimer?.cancel();
      _typingDebounceTimer = Timer(const Duration(milliseconds: 2000), () {
        _socketService.sendTypingStop(_threadId, patientId, patientName);
      });
    } else {
      _socketService.sendTypingStop(_threadId, patientId, patientName);
    }
  }

  /// Smart merge — delegates to the StateNotifier.
  /// [isFromRealtime] = true means a new message arrived (SSE/socket), so we
  /// should scroll. false = background poll, only scroll if user is at bottom.
  void _mergeMessages(List<MessageModel> incoming, {required bool isFromRealtime}) {
    final changed = ref
        .read(chatMessagesProvider(_threadId).notifier)
        .merge(incoming);

    if (changed) {
      _markIncomingAsRead(incoming);
      if (isFromRealtime || _userIsNearBottom) {
        _scrollToBottom();
      }
    }
  }

  void _markIncomingAsRead(List<MessageModel> messages) {
    final user = ref.read(authProvider).user;
    final currentUserId = user?.id;
    final currentUserName = user?.name;

    for (final message in messages) {
      if (!message.isRead &&
          !message.isFromMe(
            currentUserId: currentUserId,
            currentUserName: currentUserName,
          )) {
        ref
            .read(patientRepositoryProvider)
            .markMessageRead(message.id)
            .catchError((_) {});
      }
    }
  }

  /// Scroll to bottom after the current frame renders.
  /// [force] = true scrolls even if user is not near bottom (used on initial load).
  void _scrollToBottom({bool force = false}) {
    if (!force && !_userIsNearBottom) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  /// Jump to bottom immediately without animation (used on screen open).
  void _scrollToBottomImmediate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    final user = ref.read(authProvider).user;
    final currentUserId = user?.id ?? 'patient';
    final currentUserName = user?.name ?? 'You';

    _typingDebounceTimer?.cancel();
    _socketService.sendTypingStop(_threadId, currentUserId, currentUserName);

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = MessageModel(
      id: tempId,
      threadId: _threadId,
      body: text,
      sender: 'patient',
      senderName: currentUserName,
      createdAt: DateTime.now().toIso8601String(),
      isRead: true,
      isPending: true,
      raw: {'senderId': currentUserId},
    );

    // Add optimistic message instantly to provider (survives navigation)
    ref.read(chatMessagesProvider(_threadId).notifier).addOptimistic(optimistic);
    _controller.clear();
    setState(() => _isSending = true);
    // Always scroll when user sends a message
    _userIsNearBottom = true;
    _scrollToBottom(force: true);

    try {
      MessageModel confirmed;
      try {
        confirmed = await ref
            .read(patientRepositoryProvider)
            .sendMessage(conversationId: _threadId, message: text);
      } catch (_) {
        confirmed = await ref
            .read(patientRepositoryProvider)
            .sendPatientMessage(content: text, threadId: _threadId);
      }

      if (!mounted) return;
      ref
          .read(chatMessagesProvider(_threadId).notifier)
          .confirmMessage(tempId, confirmed);
      setState(() => _isSending = false);
      // Invalidate conversations list so lastMessage updates immediately
      ref.invalidate(conversationsProvider);
    } catch (err) {
      if (!mounted) return;
      ref.read(chatMessagesProvider(_threadId).notifier).failMessage(tempId);
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyErrorMessage(err)),
          backgroundColor: AppColors.badge,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _participantInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'CT';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : 'C';
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final currentUserId = user?.id;
    final currentUserName = user?.name;
    final displayName = widget.participantName.isNotEmpty
        ? widget.participantName
        : widget.title;
    final initials = _participantInitials(displayName);

    // Watch live messages from the provider — updates trigger rebuild
    final messages = ref.watch(chatMessagesProvider(_threadId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            // Participant Avatar Icon with live presence indicator
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryWash,
                        AppColors.primary.withValues(alpha: 0.2),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: _doctorPresenceStatus == 'online'
                          ? const Color(0xFF10B981)
                          : const Color(0xFF94A3B8),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _LiveDotSmall(
                        color: _isDoctorTyping
                            ? const Color(0xFF6366F1)
                            : (_doctorPresenceStatus == 'online'
                                ? const Color(0xFF10B981)
                                : const Color(0xFF94A3B8)),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          _isDoctorTyping
                              ? 'Doctor is typing...'
                              : (_doctorPresenceStatus == 'online'
                                  ? 'Active now · Real-time encrypted'
                                  : 'Offline · Real-time encrypted'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: _isDoctorTyping
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: _isDoctorTyping
                                ? AppColors.primary
                                : (_doctorPresenceStatus == 'online'
                                    ? const Color(0xFF059669)
                                    : AppColors.textTertiary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // HIPAA Security Note Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.primaryWash.withValues(alpha: 0.6),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, size: 14, color: AppColors.primary),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Messages are end-to-end encrypted & HIPAA compliant',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Active Chat Messages List
          Expanded(
            child: _isLoading && messages.isEmpty
                ? const Center(
                    child: InlineLoadingCard(label: 'Loading live messages...'),
                  )
                : _error != null && messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: InlineErrorCard(
                            message: _error!,
                            onRetry: _fetchInitialMessages,
                          ),
                        ),
                      )
                    : messages.isEmpty && !_isDoctorTyping
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: EmptyStateCard(
                                title: 'Start a conversation',
                                message:
                                    'Send your care team a secure real-time message below.',
                                icon: Icons.chat_rounded,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                            itemCount: messages.length + (_isDoctorTyping ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == messages.length && _isDoctorTyping) {
                                return _DoctorTypingBubble(
                                  doctorName: displayName,
                                  doctorInitials: initials,
                                );
                              }
                              final message = messages[index];
                              final isMe = message.isFromMe(
                                currentUserId: currentUserId,
                                currentUserName: currentUserName,
                              );
                              final showDate = index == 0 ||
                                  _shouldShowDateDivider(
                                    messages[index - 1],
                                    message,
                                  );

                              return Column(
                                children: [
                                  if (showDate)
                                    _DateDivider(dateStr: message.createdAt),
                                  _ChatMessageBubble(
                                    message: message,
                                    isMe: isMe,
                                    participantInitials: initials,
                                    participantName: displayName,
                                  ),
                                ],
                              );
                            },
                          ),
          ),
          // Bottom Message Input Bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.9),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: 5,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(fontSize: 14.5),
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 14.5,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: _onTextChanged,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    child: Material(
                      color: AppColors.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: _sendMessage,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(10),
                          child: _isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.arrow_upward_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowDateDivider(MessageModel prev, MessageModel curr) {
    final prevDt = prev.dateTime;
    final currDt = curr.dateTime;
    if (prevDt == null || currDt == null) return false;
    return prevDt.year != currDt.year ||
        prevDt.month != currDt.month ||
        prevDt.day != currDt.day;
  }
}

class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({
    required this.message,
    required this.isMe,
    required this.participantInitials,
    required this.participantName,
  });

  final MessageModel message;
  final bool isMe;
  final String participantInitials;
  final String participantName;

  @override
  Widget build(BuildContext context) {
    final timeStr = message.displayTime;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // If message is from clinician/other user, show their profile avatar icon
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryWash,
                    AppColors.primary.withValues(alpha: 0.2),
                  ],
                ),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Center(
                child: Text(
                  participantInitials,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      message.senderName.isNotEmpty
                          ? message.senderName
                          : participantName,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isMe
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                      bottomRight: isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                    ),
                    border: isMe ? null : Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: (isMe ? AppColors.primary : AppColors.navy)
                            .withValues(alpha: isMe ? 0.2 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.body,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.35,
                          color:
                              isMe ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (timeStr.isNotEmpty)
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isMe
                                    ? Colors.white.withValues(alpha: 0.75)
                                    : AppColors.textTertiary,
                              ),
                            ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            if (message.isPending)
                              const SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Colors.white,
                                ),
                              )
                            else if (message.hasError)
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 12,
                                color: Colors.amberAccent,
                              )
                            else
                              Icon(
                                Icons.done_all_rounded,
                                size: 13,
                                color:
                                    Colors.white.withValues(alpha: 0.85),
                              ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.dateStr});

  final String dateStr;

  String _formatDate() {
    final dt = DateTime.tryParse(dateStr)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'Yesterday';
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final text = _formatDate();
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveDotSmall extends StatelessWidget {
  const _LiveDotSmall({this.color = const Color(0xFF10B981)});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _DoctorTypingBubble extends StatefulWidget {
  const _DoctorTypingBubble({
    required this.doctorName,
    required this.doctorInitials,
  });

  final String doctorName;
  final String doctorInitials;

  @override
  State<_DoctorTypingBubble> createState() => _DoctorTypingBubbleState();
}

class _DoctorTypingBubbleState extends State<_DoctorTypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryWash,
                  AppColors.primary.withValues(alpha: 0.2),
                ],
              ),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Center(
              child: Text(
                widget.doctorInitials,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(0.2),
                const SizedBox(width: 4),
                _buildDot(0.4),
                const SizedBox(width: 8),
                Text(
                  widget.doctorName.isNotEmpty
                      ? '${widget.doctorName.split(' ').first} is typing...'
                      : 'Doctor is typing...',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(double delay) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final progress = (_animController.value - delay) % 1.0;
        final opacity =
            (0.3 + 0.7 * (1.0 - (progress - 0.5).abs() * 2)).clamp(0.1, 1.0);
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
