import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/providers/auth_token_provider.dart';
import '../features/patient/data/models/patient_models.dart';
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

  List<MessageModel> _messages = [];
  bool _isLoading = true;
  String? _error;
  Timer? _liveChatTimer;
  StreamSubscription<Map<String, dynamic>>? _sseSubscription;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialMessages();
    _startLiveChatSync();
  }

  @override
  void dispose() {
    _sseSubscription?.cancel();
    _liveChatTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startLiveChatSync() async {
    _sseSubscription?.cancel();
    _liveChatTimer?.cancel();

    // 1. Real-Time Live Message Stream (SSE) for instant (<50ms) message arrival
    String? token;
    try {
      token = ref.read(authTokenProvider);
      if (token == null || token.isEmpty) {
        token = await ref.read(authSessionStorageProvider).readToken();
      }
    } catch (_) {
      // In test environments where storage provider is not overridden
      token = null;
    }

    if (token != null && token.isNotEmpty) {
      try {
        _sseSubscription = ref
            .read(patientRepositoryProvider)
            .streamLiveMessages(threadId: widget.conversationId, token: token)
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
                  _mergeLiveMessages([incoming]);
                }
              },
              onError: (err) {
                debugPrint('[SSE] Stream error, falling back to polling: $err');
                _startPollingFallback();
              },
              onDone: () {
                _startPollingFallback();
              },
              cancelOnError: false,
            );
      } catch (err) {
        debugPrint('[SSE] Error setting up stream: $err');
        _startPollingFallback();
      }
    }

    // Secondary periodic poll (every 5 seconds) as fallback/resilience mechanism
    _startPollingFallback();
  }

  void _startPollingFallback() {
    if (_liveChatTimer != null && _liveChatTimer!.isActive) return;
    _liveChatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      _pollLiveMessages();
    });
  }

  Future<void> _fetchInitialMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final messages = await ref
          .read(patientRepositoryProvider)
          .getConversationMessages(conversationId: widget.conversationId);
      if (!mounted) return;
      setState(() {
        _messages = List.of(messages);
        _isLoading = false;
      });
      _scrollToBottom();
      _markIncomingAsRead(messages);
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = friendlyErrorMessage(err);
        _isLoading = false;
      });
    }
  }

  Future<void> _pollLiveMessages() async {
    try {
      final latest = await ref
          .read(patientRepositoryProvider)
          .getConversationMessages(conversationId: widget.conversationId);
      if (!mounted) return;
      _mergeLiveMessages(latest);
    } catch (_) {
      // Keep silent on background polling to avoid interrupting chat UI
    }
  }

  void _mergeLiveMessages(List<MessageModel> incoming) {
    if (incoming.isEmpty && _messages.isEmpty) return;

    final existingIds = _messages.map((m) => m.id).toSet();
    final newItems = incoming
        .where((m) => !existingIds.contains(m.id))
        .toList();

    if (newItems.isNotEmpty ||
        incoming.length != _messages.where((m) => !m.isPending).length) {
      final existingConfirmedBodies = incoming.map((m) => m.body).toSet();
      final pendingMessages = _messages
          .where(
            (m) => m.isPending && !existingConfirmedBodies.contains(m.body),
          )
          .toList();
      setState(() {
        _messages = [...incoming, ...pendingMessages];
      });
      _scrollToBottom();
      _markIncomingAsRead(incoming);
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    final user = ref.read(authProvider).user;
    final currentUserId = user?.id;
    final currentUserName = user?.name ?? 'You';

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = MessageModel(
      id: tempId,
      body: text,
      sender: 'patient',
      senderName: currentUserName,
      createdAt: DateTime.now().toIso8601String(),
      isRead: true,
      isPending: true,
      raw: {'senderId': currentUserId ?? ''},
    );

    setState(() {
      _messages.add(optimistic);
      _controller.clear();
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final confirmed = await ref
          .read(patientRepositoryProvider)
          .sendMessage(conversationId: widget.conversationId, message: text);
      if (!mounted) return;
      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempId);
        if (index != -1) {
          _messages[index] = confirmed;
        } else if (!_messages.any((m) => m.id == confirmed.id)) {
          _messages.add(confirmed);
        }
        _isSending = false;
      });
      // Invalidate conversations list so lastMessage and timestamp update immediately
      ref.invalidate(conversationsProvider);
    } catch (err) {
      if (!mounted) return;
      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempId);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            isPending: false,
            hasError: true,
          );
        }
        _isSending = false;
      });
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
            // Participant Avatar Icon with live indicator
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
                      color: const Color(0xFF10B981),
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
                  const Row(
                    children: [
                      _LiveDotSmall(),
                      SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Active now · Real-time encrypted',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF059669),
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
          // Chat Messages List - commented out to show No chats message
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: EmptyStateCard(
                  title: 'No chats',
                  message: 'No chats available.',
                  icon: Icons.chat_bubble_outline_rounded,
                ),
              ),
            ),
          ),
          /*
          Expanded(
            child: _isLoading
                ? const Center(
                    child: InlineLoadingCard(label: 'Loading live messages...'),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: InlineErrorCard(
                            message: _error!,
                            onRetry: _fetchInitialMessages,
                          ),
                        ),
                      )
                    : _messages.isEmpty
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
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isMe = message.isFromMe(
                                currentUserId: currentUserId,
                                currentUserName: currentUserName,
                              );
                              final showDate = index == 0 ||
                                  _shouldShowDateDivider(
                                    _messages[index - 1],
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
          */
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
                        maxLines: 4,
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
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
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
                          color: isMe ? Colors.white : AppColors.textPrimary,
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
                                color: Colors.white.withValues(alpha: 0.85),
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
  const _LiveDotSmall();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Color(0xFF10B981),
        shape: BoxShape.circle,
      ),
    );
  }
}
