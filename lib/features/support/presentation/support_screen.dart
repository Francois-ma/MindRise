import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/mr_button.dart';
import '../../../core/widgets/mr_card.dart';
import '../../../core/widgets/profile_button.dart';
import '../../../core/widgets/screen_state.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/support_repository.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _messageController = TextEditingController();
  String? _busyConnection;
  bool _availabilitySaving = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      ref.invalidate(practitionersProvider);
      ref.invalidate(onlinePractitionersProvider);
      ref.invalidate(supportThreadsProvider);
      ref.invalidate(supportNotificationsProvider);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  void _openAiAssistant() {
    context.push('/chatbot', extra: _messageController.text.trim());
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.refresh(practitionersProvider.future),
      ref.refresh(onlinePractitionersProvider.future),
      ref.refresh(supportThreadsProvider.future),
      ref.refresh(crisisResourcesProvider.future),
      ref.refresh(supportNotificationsProvider.future),
    ]);
  }

  Future<void> _connect(
    Practitioner practitioner,
    SupportContactMethod method,
  ) async {
    final key = '${practitioner.id}:${method.apiValue}';
    if (_busyConnection != null) return;
    setState(() => _busyConnection = key);

    try {
      final thread = await ref
          .read(supportRepositoryProvider)
          .startPractitionerThread(practitioner, contactMethod: method);
      ref.invalidate(supportThreadsProvider);

      if (!mounted) return;
      if (method == SupportContactMethod.text) {
        context.push('/support/thread/${thread.id}', extra: thread);
        return;
      }

      final uri = method == SupportContactMethod.phone
          ? Uri(
              scheme: 'tel',
              path: practitioner.phoneNumber.replaceAll(RegExp(r'\s+'), ''),
            )
          : Uri.tryParse(practitioner.whatsappUrl);
      final opened =
          uri != null &&
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${method.label} could not be opened on this device.',
            ),
          ),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userMessageFromError(error))));
      }
    } finally {
      if (mounted) setState(() => _busyConnection = null);
    }
  }

  Future<void> _setAvailability(PractitionerAvailabilityStatus status) async {
    if (_availabilitySaving) return;
    setState(() => _availabilitySaving = true);
    try {
      await ref
          .read(supportRepositoryProvider)
          .updateAvailability(status: status);
      ref.invalidate(practitionersProvider);
      ref.invalidate(onlinePractitionersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Your practitioner status is now ${status.label.toLowerCase()}.',
            ),
          ),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userMessageFromError(error))));
      }
    } finally {
      if (mounted) setState(() => _availabilitySaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final role = user?.role ?? AppUserRole.unknown;
    final onlinePractitioners = ref.watch(onlinePractitionersProvider);
    final practitioners = ref.watch(practitionersProvider);
    final threads = ref.watch(supportThreadsProvider);
    final crisisResources = ref.watch(crisisResourcesProvider);
    final notifications = ref.watch(supportNotificationsProvider);
    final isPractitioner = role == AppUserRole.practitioner;
    final isPatient = role == AppUserRole.patient;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 112),
            sliver: SliverList.list(
              children: [
                GradientHeader(
                  title: isPractitioner ? 'Patient Support' : 'Support',
                  subtitle: isPractitioner
                      ? 'Control your availability and answer private conversations.'
                      : 'Choose an online practitioner and connect privately.',
                  icon: isPractitioner
                      ? Icons.support_agent_rounded
                      : Icons.chat_bubble_rounded,
                  gradient: const LinearGradient(
                    colors: [AppColors.blue, Color(0xFF38BDF8), AppColors.cyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  trailing: const ProfileButton(),
                ),
                const SizedBox(height: AppSpacing.lg),
                const MRCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.rose),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'MindRise support is not an emergency service. If you are in immediate danger, thinking about harming yourself, or someone else may be harmed, please contact emergency services or go to the nearest hospital immediately.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                notifications.when(
                  data: (items) => _NotificationCard(notifications: items),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (isPractitioner) ...[
                  practitioners.when(
                    data: (items) => _AvailabilityCard(
                      practitioner: _ownProfile(items),
                      isSaving: _availabilitySaving,
                      onChanged: _setAvailability,
                    ),
                    loading: () => const InlineLoadingCard(
                      message: 'Loading your practitioner status...',
                    ),
                    error: (error, stackTrace) => InlineErrorCard(
                      error: error,
                      onRetry: () => ref.invalidate(practitionersProvider),
                    ),
                  ),
                ] else ...[
                  _AiAssistantCard(
                    controller: _messageController,
                    onOpen: _openAiAssistant,
                  ),
                ],
                if (isPatient) ...[
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionHeading(
                    eyebrow: 'ONLINE NOW',
                    title: 'Choose a practitioner',
                    subtitle:
                        'Start a private text conversation, phone call, or video call.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  onlinePractitioners.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return const _EmptySupportCard(
                          icon: Icons.schedule_rounded,
                          title: 'No practitioner is online right now',
                          message:
                              'Pull down to refresh or use urgent help if the situation cannot wait.',
                        );
                      }
                      return Column(
                        children: [
                          for (final practitioner in items) ...[
                            _PractitionerCard(
                              practitioner: practitioner,
                              busyConnection: _busyConnection,
                              onConnect: (method) =>
                                  _connect(practitioner, method),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ],
                      );
                    },
                    loading: () => const InlineLoadingCard(
                      message: 'Finding online practitioners...',
                    ),
                    error: (error, stackTrace) => InlineErrorCard(
                      error: error,
                      onRetry: () =>
                          ref.invalidate(onlinePractitionersProvider),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                _SectionHeading(
                  eyebrow: 'PRIVATE CONVERSATIONS',
                  title: isPractitioner
                      ? 'Patient support inbox'
                      : 'Your practitioner messages',
                  subtitle: isPractitioner
                      ? 'Open a conversation to read and reply.'
                      : 'Return to your recent practitioner conversations.',
                ),
                const SizedBox(height: AppSpacing.md),
                threads.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const _EmptySupportCard(
                        icon: Icons.forum_outlined,
                        title: 'No conversations yet',
                        message:
                            'Your private practitioner conversations will appear here.',
                      );
                    }
                    return Column(
                      children: [
                        for (final thread in items) ...[
                          _ConversationTile(
                            thread: thread,
                            onTap: () => context.push(
                              '/support/thread/${thread.id}',
                              extra: thread,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    );
                  },
                  loading: () => const InlineLoadingCard(
                    message: 'Loading private conversations...',
                  ),
                  error: (error, stackTrace) => InlineErrorCard(
                    error: error,
                    onRetry: () => ref.invalidate(supportThreadsProvider),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
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

  Practitioner? _ownProfile(List<Practitioner> practitioners) {
    for (final practitioner in practitioners) {
      if (practitioner.isMyProfile) return practitioner;
    }
    return null;
  }
}

class _AiAssistantCard extends StatelessWidget {
  const _AiAssistantCard({required this.controller, required this.onOpen});

  final TextEditingController controller;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MRCard(
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
                radius: 24,
                backgroundColor: AppColors.emerald,
                child: Icon(Icons.smart_toy_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
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
                    const SizedBox(height: 4),
                    Text(
                      'Ask for grounding ideas and practical next steps.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: controller,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Ask what you need support with...',
              prefixIcon: Icon(Icons.edit_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: MRButton(
              label: 'Ask MindRise Assistant',
              icon: Icons.smart_toy_rounded,
              onPressed: onOpen,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notifications});

  final List<SupportNotification> notifications;

  @override
  Widget build(BuildContext context) {
    final unread = notifications.where((item) => !item.isRead).take(3).toList();
    if (unread.isEmpty) return const SizedBox.shrink();
    return MRCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: AppColors.blue),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Support updates',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final item in unread)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('${item.title}: ${item.body}'),
            ),
        ],
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({
    required this.practitioner,
    required this.isSaving,
    required this.onChanged,
  });

  final Practitioner? practitioner;
  final bool isSaving;
  final ValueChanged<PractitionerAvailabilityStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    if (practitioner == null) {
      return const _EmptySupportCard(
        icon: Icons.badge_outlined,
        title: 'Practitioner profile required',
        message:
            'Ask a MindRise administrator to complete your practitioner profile before going online.',
      );
    }

    final availabilityStatus = practitioner!.availabilityStatus;
    final isOnline =
        availabilityStatus == PractitionerAvailabilityStatus.online;
    final theme = Theme.of(context);
    return MRCard(
      gradient: LinearGradient(
        colors: isOnline
            ? const [Color(0xFFE8FFF5), Color(0xFFE8F9FF)]
            : const [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.lime : AppColors.muted,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isOnline ? AppColors.lime : AppColors.muted)
                          .withValues(alpha: .24),
                      blurRadius: 0,
                      spreadRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'You are ${availabilityStatus.label.toLowerCase()}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isOnline
                ? 'Patients can choose you for support while you remain online.'
                : 'Go online when you are ready to receive patient support requests.',
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final status in PractitionerAvailabilityStatus.values)
                OutlinedButton.icon(
                  onPressed: isSaving || availabilityStatus == status
                      ? null
                      : () => onChanged(status),
                  icon: Icon(
                    status == PractitionerAvailabilityStatus.online
                        ? Icons.wifi_rounded
                        : status == PractitionerAvailabilityStatus.busy
                        ? Icons.headset_mic_rounded
                        : Icons.wifi_off_rounded,
                  ),
                  label: Text(status.label),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PractitionerCard extends StatelessWidget {
  const _PractitionerCard({
    required this.practitioner,
    required this.busyConnection,
    required this.onConnect,
  });

  final Practitioner practitioner;
  final String? busyConnection;
  final ValueChanged<SupportContactMethod> onConnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MRCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.emerald,
                child: Text(
                  _initials(practitioner.displayName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      practitioner.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      practitioner.specialization.isEmpty
                          ? 'MindRise practitioner'
                          : practitioner.specialization,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const _OnlineBadge(),
            ],
          ),
          if (practitioner.bio.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              practitioner.bio,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _ConnectionButton(
                  label: 'Text',
                  icon: Icons.chat_bubble_outline_rounded,
                  isLoading: _isBusy(SupportContactMethod.text),
                  onPressed: () => onConnect(SupportContactMethod.text),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ConnectionButton(
                  label: 'Call',
                  icon: Icons.phone_outlined,
                  isLoading: _isBusy(SupportContactMethod.phone),
                  onPressed: practitioner.canCall
                      ? () => onConnect(SupportContactMethod.phone)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ConnectionButton(
                  label: 'WhatsApp',
                  icon: Icons.chat_outlined,
                  isLoading: _isBusy(SupportContactMethod.video),
                  onPressed: practitioner.canWhatsApp
                      ? () => onConnect(SupportContactMethod.video)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isBusy(SupportContactMethod method) {
    return busyConnection == '${practitioner.id}:${method.apiValue}';
  }
}

class _ConnectionButton extends StatelessWidget {
  const _ConnectionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isLoading,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      ),
      child: isLoading
          ? const SizedBox.square(
              dimension: 17,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 19),
                const SizedBox(height: 4),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.thread, required this.onTap});

  final SupportThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MRCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.blue.withValues(alpha: .12),
            child: Icon(
              _methodIcon(thread.contactMethod),
              color: AppColors.blue,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        thread.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat.MMMd().format(thread.updatedAt.toLocal()),
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  thread.latestMessage?.body ??
                      thread.contactMethod.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FFF5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.lime.withValues(alpha: .25)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_rounded, size: 13, color: AppColors.teal),
          SizedBox(width: 4),
          Text(
            'Online',
            style: TextStyle(
              color: AppColors.teal,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.teal,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(subtitle, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _EmptySupportCard extends StatelessWidget {
  const _EmptySupportCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MRCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.teal.withValues(alpha: .12),
            child: Icon(icon, color: AppColors.teal),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(message, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
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
                'Need urgent help?',
                style: TextStyle(fontWeight: FontWeight.w800),
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
          SizedBox(
            width: double.infinity,
            child: MRButton(
              label: primary?.phoneNumber.isNotEmpty == true
                  ? primary!.phoneNumber
                  : 'Emergency resources',
              icon: Icons.phone_rounded,
              gradient: const LinearGradient(
                colors: [AppColors.rose, Color(0xFFFB7185)],
              ),
              onPressed: () => _callResource(context, primary),
            ),
          ),
        ],
      ),
    );
  }
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

IconData _methodIcon(SupportContactMethod method) {
  return switch (method) {
    SupportContactMethod.text => Icons.chat_bubble_outline_rounded,
    SupportContactMethod.phone => Icons.phone_outlined,
    SupportContactMethod.video => Icons.chat_outlined,
  };
}
