import 'dart:async';

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
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/support_repository.dart';

const supportEmergencyDisclaimer =
    'MindRise support is not an emergency service. If you are in immediate danger, thinking about harming yourself, or someone else may be harmed, please contact emergency services or go to the nearest hospital immediately.';

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
  Timer? _pollTimer;
  String _busyAction = '';

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(supportThreadProvider(widget.threadId));
    ref.invalidate(supportMessagesProvider(widget.threadId));
    ref.invalidate(supportCallsProvider(widget.threadId));
    ref.invalidate(supportThreadsProvider);
  }

  Future<void> _run(String action, Future<void> Function() operation) async {
    if (_busyAction.isNotEmpty) return;
    setState(() => _busyAction = action);
    try {
      await operation();
      _refresh();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userMessageFromError(error))));
      }
    } finally {
      if (mounted) setState(() => _busyAction = '');
    }
  }

  Future<void> _send() async {
    final body = _messageController.text.trim();
    if (body.isEmpty) return;
    await _run('message', () async {
      await ref
          .read(supportRepositoryProvider)
          .sendMessage(threadId: widget.threadId, body: body);
      _messageController.clear();
    });
  }

  Future<void> _sessionAction(
    bool accept,
  ) => _run(accept ? 'accept' : 'reject', () async {
    if (accept) {
      await ref.read(supportRepositoryProvider).acceptSession(widget.threadId);
    } else {
      await ref.read(supportRepositoryProvider).rejectSession(widget.threadId);
    }
  });

  Future<void> _startCall(SupportCallType type) =>
      _run(type.apiValue, () async {
        await ref
            .read(supportRepositoryProvider)
            .startCall(threadId: widget.threadId, callType: type);
      });

  Future<void> _callAction(SupportCall call, String action) =>
      _run(action, () async {
        await ref
            .read(supportRepositoryProvider)
            .updateCall(callId: call.id, action: action);
      });

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(supportThreadProvider(widget.threadId));
    final messages = ref.watch(supportMessagesProvider(widget.threadId));
    final calls = ref.watch(supportCallsProvider(widget.threadId));
    final user = ref.watch(authControllerProvider).user;
    final currentUserId = user?.id ?? 0;
    final isPractitioner = user?.role == AppUserRole.practitioner;

    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: session.when(
                data: (item) => _ChatHeader(
                  title: item.displayName,
                  status: item.status.label,
                ),
                loading: () =>
                    _ChatHeader(title: widget.title, status: 'Loading'),
                error: (error, stackTrace) =>
                    _ChatHeader(title: widget.title, status: 'Unavailable'),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _EmergencyDisclaimer(),
            ),
            session.when(
              data: (item) => _SessionControls(
                session: item,
                isPractitioner: isPractitioner,
                isBusy: _busyAction.isNotEmpty,
                onAccept: () => _sessionAction(true),
                onReject: () => _sessionAction(false),
                onAudio: () => _startCall(SupportCallType.audio),
                onVideo: () => _startCall(SupportCallType.video),
              ),
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
            calls.when(
              data: (items) {
                final active = items
                    .where(
                      (call) =>
                          call.status == 'ringing' || call.status == 'accepted',
                    )
                    .firstOrNull;
                return active == null
                    ? const SizedBox.shrink()
                    : _CallBanner(
                        call: active,
                        currentUserId: currentUserId,
                        isBusy: _busyAction.isNotEmpty,
                        onAction: _callAction,
                      );
              },
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _refresh(),
                child: messages.when(
                  data: (items) => items.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(20),
                          children: const [
                            MRCard(
                              child: Text(
                                'No messages yet. Send a message to begin this private consultation.',
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          itemBuilder: (context, index) => _MessageBubble(
                            message: items[index],
                            isMine: items[index].senderId == currentUserId,
                          ),
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemCount: items.length,
                        ),
                  loading: () => ListView(
                    padding: const EdgeInsets.all(20),
                    children: const [
                      InlineLoadingCard(message: 'Loading conversation...'),
                    ],
                  ),
                  error: (error, stackTrace) => ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      InlineErrorCard(error: error, onRetry: _refresh),
                    ],
                  ),
                ),
              ),
            ),
            session.when(
              data: (item) => _Composer(
                controller: _messageController,
                isSending: _busyAction == 'message',
                enabled: item.canMessage,
                onSend: _send,
              ),
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.title, required this.status});
  final String title;
  final String status;

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
                title.isEmpty ? 'Practitioner' : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$status private support session',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmergencyDisclaimer extends StatelessWidget {
  const _EmergencyDisclaimer();
  @override
  Widget build(BuildContext context) => MRCard(
    padding: const EdgeInsets.all(12),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.warning_amber_rounded, color: AppColors.rose),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            supportEmergencyDisclaimer,
            style: TextStyle(fontSize: 12, height: 1.35),
          ),
        ),
      ],
    ),
  );
}

class _SessionControls extends StatelessWidget {
  const _SessionControls({
    required this.session,
    required this.isPractitioner,
    required this.isBusy,
    required this.onAccept,
    required this.onReject,
    required this.onAudio,
    required this.onVideo,
  });
  final SupportThread session;
  final bool isPractitioner;
  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onAudio;
  final VoidCallback onVideo;

  @override
  Widget build(BuildContext context) {
    if (!(isPractitioner && session.status == SupportSessionStatus.pending) &&
        !session.canCall) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (isPractitioner &&
              session.status == SupportSessionStatus.pending) ...[
            FilledButton.icon(
              onPressed: isBusy ? null : onAccept,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Accept request'),
            ),
            OutlinedButton.icon(
              onPressed: isBusy ? null : onReject,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Reject'),
            ),
          ],
          if (session.canCall) ...[
            OutlinedButton.icon(
              onPressed: isBusy ? null : onAudio,
              icon: const Icon(Icons.phone_outlined),
              label: const Text('Start audio call'),
            ),
            OutlinedButton.icon(
              onPressed: isBusy ? null : onVideo,
              icon: const Icon(Icons.videocam_outlined),
              label: const Text('Start video call'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CallBanner extends StatelessWidget {
  const _CallBanner({
    required this.call,
    required this.currentUserId,
    required this.isBusy,
    required this.onAction,
  });
  final SupportCall call;
  final int currentUserId;
  final bool isBusy;
  final void Function(SupportCall, String) onAction;

  @override
  Widget build(BuildContext context) {
    final incoming = call.startedById != currentUserId;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: MRCard(
        child: Row(
          children: [
            Icon(
              call.callType == SupportCallType.video
                  ? Icons.videocam_rounded
                  : Icons.phone_in_talk_rounded,
              color: AppColors.teal,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                call.status == 'ringing'
                    ? incoming
                          ? 'Incoming ${call.callType.label.toLowerCase()} call'
                          : 'Calling...'
                    : '${call.callType.label} call connected',
              ),
            ),
            if (call.status == 'ringing' && incoming)
              IconButton.filled(
                onPressed: isBusy ? null : () => onAction(call, 'accept'),
                tooltip: 'Accept',
                icon: const Icon(Icons.call_rounded),
              ),
            if (call.status == 'ringing' && incoming)
              IconButton.outlined(
                onPressed: isBusy ? null : () => onAction(call, 'reject'),
                tooltip: 'Reject',
                icon: const Icon(Icons.call_end_rounded),
              ),
            IconButton.outlined(
              onPressed: isBusy ? null : () => onAction(call, 'end'),
              tooltip: 'End call',
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
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
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Text(
                    message.senderName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
    required this.enabled,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool isSending;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: enabled
                    ? 'Write a private message...'
                    : 'This support session is closed',
                prefixIcon: const Icon(Icons.lock_rounded),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filled(
            onPressed: isSending || !enabled ? null : onSend,
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
