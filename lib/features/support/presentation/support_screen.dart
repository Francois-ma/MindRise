import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/mr_button.dart';
import '../../../core/widgets/mr_card.dart';
import '../../../core/widgets/profile_button.dart';
import '../../../core/widgets/screen_state.dart';
import '../data/support_repository.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _messageController = TextEditingController();
  bool _isStartingChat = false;
  int? _startingPractitionerId;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _startAiChat() async {
    if (_isStartingChat) return;
    final message = _messageController.text.trim().isEmpty
        ? "Hello, I'd like support today."
        : _messageController.text.trim();

    setState(() => _isStartingChat = true);
    try {
      await ref.read(supportRepositoryProvider).startAiThread(message);
      _messageController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support thread started.')),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userMessageFromError(error))));
      }
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }

  Future<void> _startPractitionerChat(Practitioner practitioner) async {
    if (_startingPractitionerId != null) return;
    setState(() => _startingPractitionerId = practitioner.id);

    try {
      final thread = await ref
          .read(supportRepositoryProvider)
          .startPractitionerThread(practitioner);
      if (mounted) {
        context.push('/support/thread/${thread.id}', extra: thread);
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userMessageFromError(error))));
      }
    } finally {
      if (mounted) setState(() => _startingPractitionerId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final practitioners = ref.watch(practitionersProvider);
    final crisisResources = ref.watch(crisisResourcesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(practitionersProvider);
        ref.invalidate(crisisResourcesProvider);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 112),
            sliver: SliverList.list(
              children: [
                const GradientHeader(
                  title: 'Support',
                  subtitle: 'Private support pathways and care resources.',
                  icon: Icons.chat_bubble_rounded,
                  gradient: LinearGradient(
                    colors: [AppColors.blue, Color(0xFF38BDF8), AppColors.cyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  trailing: ProfileButton(),
                ),
                const SizedBox(height: AppSpacing.xl),
                MRCard(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFFCF5), Color(0xFFE8F9FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 26,
                            backgroundColor: AppColors.emerald,
                            child: Icon(
                              Icons.smart_toy_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Guided Support',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Start a private support thread for grounding and next steps.',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Share what kind of support you need...',
                          prefixIcon: Icon(Icons.edit_rounded),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      MRButton(
                        label: 'Start Support Thread',
                        icon: Icons.chat_rounded,
                        isLoading: _isStartingChat,
                        onPressed: _startAiChat,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Care Professionals',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                practitioners.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const MRCard(
                        child: Text('No practitioners are listed yet.'),
                      );
                    }
                    return Column(
                      children: [
                        for (final practitioner in items) ...[
                          _DoctorTile(
                            practitioner: practitioner,
                            isLoading:
                                _startingPractitionerId == practitioner.id,
                            onChat: () => _startPractitionerChat(practitioner),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    );
                  },
                  loading: () => const InlineLoadingCard(
                    message: 'Loading practitioners...',
                  ),
                  error: (error, stackTrace) => InlineErrorCard(
                    error: error,
                    onRetry: () => ref.invalidate(practitionersProvider),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                crisisResources.when(
                  data: (items) => _EmergencyCard(resources: items),
                  loading: () => const InlineLoadingCard(
                    message: 'Loading crisis resources...',
                  ),
                  error: (error, stackTrace) => InlineErrorCard(
                    title: 'Crisis resources unavailable',
                    error: error,
                    onRetry: () => ref.invalidate(crisisResourcesProvider),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorTile extends StatelessWidget {
  const _DoctorTile({
    required this.practitioner,
    required this.onChat,
    required this.isLoading,
  });

  final Practitioner practitioner;
  final VoidCallback onChat;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return MRCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: practitioner.isAvailable
                ? AppColors.emerald
                : AppColors.blue,
            child: Text(
              _initials(practitioner.displayName),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  practitioner.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  practitioner.specialization,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    practitioner.isAvailable ? 'Available now' : 'Schedule',
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: isLoading ? null : onChat,
            child: isLoading
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Chat'),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'MR';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({required this.resources});

  final List<CrisisResource> resources;

  Future<void> _callResource(
    BuildContext context,
    CrisisResource? resource,
  ) async {
    final phoneNumber = resource?.phoneNumber.trim() ?? '';
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number is available yet.')),
      );
      return;
    }

    final uri = Uri(
      scheme: 'tel',
      path: phoneNumber.replaceAll(RegExp(r'\s+'), ''),
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open $phoneNumber.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = resources.isNotEmpty ? resources.first : null;

    return MRCard(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.rose),
              SizedBox(width: 10),
              Text(
                'Need Urgent Help?',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            primary?.description.isNotEmpty == true
                ? primary!.description
                : 'If you are experiencing a mental health crisis, contact local emergency services immediately.',
          ),
          const SizedBox(height: AppSpacing.lg),
          MRButton(
            label: primary?.phoneNumber.isNotEmpty == true
                ? primary!.phoneNumber
                : 'Emergency Resources',
            icon: Icons.phone_rounded,
            gradient: const LinearGradient(
              colors: [AppColors.rose, Color(0xFFFB7185)],
            ),
            onPressed: () => _callResource(context, primary),
          ),
        ],
      ),
    );
  }
}
