import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/mr_card.dart';
import '../data/chatbot_repository.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({this.initialMessage = '', super.key});

  final String initialMessage;

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    _ChatMessage.assistant(
      'Hello, I am the MindRise assistant. I can share mental health education, coping ideas, and guidance on MindRise support.',
    ),
  ];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final initialMessage = widget.initialMessage.trim();
    if (initialMessage.isNotEmpty) {
      _messageController.text = initialMessage;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _send() async {
    final body = _messageController.text.trim();
    if (body.isEmpty || _isSending) return;

    final history = _messages
        .where((message) => message.includeInHistory)
        .toList(growable: false)
        .takeLast(8)
        .map(
          (message) => ChatbotHistoryMessage(
            role: message.role,
            content: message.content,
          ),
        )
        .toList(growable: false);

    setState(() {
      _messages.add(_ChatMessage.user(body));
      _messageController.clear();
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final result = await ref
          .read(chatbotRepositoryProvider)
          .sendMessage(message: body, history: history);
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage.assistant(
            result.reply.isEmpty
                ? 'I am here with you. Try one slow breath and tell me what feels heaviest right now.'
                : result.reply,
          ),
        );
      });
      _scrollToBottom();
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

  void _usePrompt(String prompt) {
    _messageController.text = prompt;
    _messageController.selection = TextSelection.collapsed(
      offset: _messageController.text.length,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _AssistantHeader(onBack: _leave),
            ),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  const _SafetyNotice(),
                  const SizedBox(height: AppSpacing.md),
                  if (_messages.length == 1) ...[
                    _PromptCard(onPromptSelected: _usePrompt),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  for (final message in _messages) ...[
                    _MessageBubble(message: message),
                    const SizedBox(height: 10),
                  ],
                  if (_isSending) ...[
                    const _TypingBubble(),
                    const SizedBox(height: 10),
                  ],
                ],
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

class _AssistantHeader extends StatelessWidget {
  const _AssistantHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.emerald.withValues(alpha: .18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MindRise Assistant',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Mental health education and coping guidance',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MRCard(
      padding: const EdgeInsets.all(16),
      gradient: const LinearGradient(
        colors: [Color(0xFFFFF8DF), Color(0xFFEFFCF5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_rounded, color: AppColors.emerald),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Supportive education only. If you may be in immediate danger, contact local emergency services, a nearby health facility, or a trusted person now.',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.onPromptSelected});

  final ValueChanged<String> onPromptSelected;

  static const prompts = [
    'I feel stressed and need a quick reset.',
    'How can I handle anxiety before school?',
    'Help me build confidence today.',
    'What can I do when I feel alone?',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MRCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start with a prompt',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final prompt in prompts)
                ActionChip(
                  label: Text(prompt),
                  avatar: const Icon(Icons.auto_awesome_rounded, size: 18),
                  onPressed: () => onPromptSelected(prompt),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMine = message.role == 'user';
    final background = isMine
        ? AppColors.emerald
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = isMine ? Colors.white : theme.colorScheme.onSurface;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 342),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 18),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Text(
              message.content,
              style: TextStyle(color: textColor, height: 1.38),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Thinking...'),
            ],
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
                maxLength: 1200,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: 'Ask about stress, anxiety, self-esteem...',
                  prefixIcon: Icon(Icons.psychology_alt_rounded),
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

class _ChatMessage {
  _ChatMessage({required this.role, required this.content})
    : id = DateTime.now().microsecondsSinceEpoch.toString();

  _ChatMessage.user(String content) : this(role: 'user', content: content);

  _ChatMessage.assistant(String content)
    : this(role: 'assistant', content: content);

  final String id;
  final String role;
  final String content;

  bool get includeInHistory => role == 'user' || role == 'assistant';
}

extension _TakeLast<T> on List<T> {
  Iterable<T> takeLast(int count) {
    if (length <= count) return this;
    return skip(length - count);
  }
}
