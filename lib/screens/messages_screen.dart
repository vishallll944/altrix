import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/responsive/responsive.dart';
import '../core/responsive/responsive_widgets.dart';
import '../features/patient/data/models/patient_models.dart';
import '../features/patient/presentation/providers/patient_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state_card.dart';
import 'conversation_detail_screen.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = context.responsive;
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveCenter(
          child: conversationsAsync.when(
            loading: () => const Center(
              child: InlineLoadingCard(label: 'Loading messages...'),
            ),
            error: (error, _) => ListView(
              padding: responsive.pagePadding,
              children: [
                InlineErrorCard(
                  message: friendlyErrorMessage(error),
                  onRetry: () => ref.invalidate(conversationsProvider),
                ),
              ],
            ),
            data: (conversations) => RefreshIndicator(
              onRefresh: () async => ref.invalidate(conversationsProvider),
              child: ListView(
                padding: responsive.pagePadding.copyWith(
                  top: responsive.rz(12),
                  bottom: responsive.rz(32),
                ),
                children: [
                  Text(
                    'Secure messages from your clinic',
                    style: responsiveTextStyle(
                      context,
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: responsive.rz(18)),
                  if (conversations.isNotEmpty) ...[
                    _MessagesStatsRow(conversations: conversations),
                    SizedBox(height: responsive.rz(20)),
                    Text(
                      'Recent conversations',
                      style: responsiveTextStyle(
                        context,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: responsive.rz(14)),
                  ],
                  if (conversations.isEmpty)
                    const EmptyStateCard(
                      title: 'No messages yet',
                      message: 'When your clinic sends you a message, it will appear here.',
                      icon: Icons.chat_bubble_outline_rounded,
                    )
                  else
                    for (final conversation in conversations)
                      Padding(
                        padding: EdgeInsets.only(bottom: responsive.rz(10)),
                        child: _ConversationTile(
                          conversation: conversation,
                          onTap: () => _openThread(context, conversation),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openThread(BuildContext context, ConversationModel conversation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConversationDetailScreen(
          conversationId: conversation.id,
          title: conversation.title.isNotEmpty ? conversation.title : 'Messages',
        ),
      ),
    );
  }
}

class _MessagesStatsRow extends StatelessWidget {
  const _MessagesStatsRow({required this.conversations});

  final List<ConversationModel> conversations;

  @override
  Widget build(BuildContext context) {
    final unread = conversations.fold<int>(0, (sum, item) => sum + item.unreadCount);
    return Row(
      children: [
        Expanded(
          child: _Stat(label: '${conversations.length} threads', icon: Icons.forum_outlined),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Stat(label: '$unread unread', icon: Icons.mark_email_unread_outlined),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});

  final ConversationModel conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.title.isNotEmpty ? conversation.title : 'Conversation',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conversation.preview.isNotEmpty ? conversation.preview : 'No messages yet',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (conversation.unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${conversation.unreadCount}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
