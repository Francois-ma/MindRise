import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/mr_card.dart';
import '../../../core/widgets/screen_state.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/support_repository.dart';

class SupportChatScreen extends ConsumerStatefulWidget {
  const SupportChatScreen({
    required this.threadId,
    required this.title,
    super.key,
  });

  final int threadId;
  final String title;

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen> {
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _messageController.text.trim();
    if (body.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await ref
          .read(supportRepositoryProvider)
          .sendMessage(threadId: widget.threadId, body: body);
      _messageController.clear();
      ref.invalidate(supportMessagesProvider(widget.threadId));
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userMessageFromError(error))));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(supportMessagesProvider(widget.threadId));
    final currentUserId = ref.watch(authControllerProvider).user?.id ?? 0;

    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _ChatHeader(title: widget.title),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(supportMessagesProvider(widget.threadId)),
                child: messages.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return ListView(
                        padding: const EdgeInsets.all(20),
                        children: const [
                          MRCard(
                            child: Text(
                              'No messages yet. Send a message to begin this private consultation.',
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      itemBuilder: (context, index) {
                        final message = items[index];
                        return _MessageBubble(
                          message: message,
                          isMine: message.senderId == currentUserId,
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemCount: items.length,
                    );
                  },
                  loading: () => ListView(
                    padding: const EdgeInsets.all(20),
                    children: const [
                      InlineLoadingCard(message: 'Loading conversation...'),
                    ],
                  ),
                  error: (error, stackTrace) => ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      InlineErrorCard(
                        error: error,
                        onRetry: () => ref.invalidate(
                          supportMessagesProvider(widget.threadId),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _Composer(
              controller: _messageController,
              isSending: _isSending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton(
          onPressed: () => context.pop(),
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        CircleAvatar(
          backgroundColor: AppColors.emerald.withValues(alpha: .14),
          child: const Icon(Icons.psychology_rounded, color: AppColors.emerald),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.isEmpty ? 'Psychologist' : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text('Private consultation', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final SupportMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isMine
        ? AppColors.emerald
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = isMine ? Colors.white : theme.colorScheme.onSurface;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 18),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMine) ...[
                  Text(
                    message.senderName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  message.body,
                  style: TextStyle(color: textColor, height: 1.35),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat.Hm().format(message.createdAt.toLocal()),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isMine
                        ? Colors.white70
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Message psychologist...',
                  prefixIcon: Icon(Icons.lock_rounded),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              onPressed: isSending ? null : onSend,
              tooltip: 'Send',
              icon: isSending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
