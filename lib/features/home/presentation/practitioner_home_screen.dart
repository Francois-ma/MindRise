import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/mr_button.dart';
import '../../../core/widgets/mr_card.dart';
import '../../../core/widgets/profile_button.dart';
import '../../../core/widgets/screen_state.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../support/data/support_repository.dart';

class PractitionerHomeScreen extends ConsumerStatefulWidget {
  const PractitionerHomeScreen({super.key});

  @override
  ConsumerState<PractitionerHomeScreen> createState() =>
      _PractitionerHomeScreenState();
}

class _PractitionerHomeScreenState
    extends ConsumerState<PractitionerHomeScreen> {
  bool _isSavingAvailability = false;
  bool _isSavingContact = false;

  Future<void> _refresh() async {
    await Future.wait([
      ref.refresh(practitionersProvider.future),
      ref.refresh(supportThreadsProvider.future),
    ]);
  }

  Future<void> _setAvailability(PractitionerAvailabilityStatus status) async {
    if (_isSavingAvailability) return;
    setState(() => _isSavingAvailability = true);
    try {
      await ref
          .read(supportRepositoryProvider)
          .updateAvailability(status: status);
      ref.invalidate(practitionersProvider);
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
      if (mounted) setState(() => _isSavingAvailability = false);
    }
  }

  Future<void> _editContact(Practitioner practitioner) async {
    final controller = TextEditingController(text: practitioner.phoneNumber);
    final phoneNumber = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call & WhatsApp number'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'International telephone number',
            hintText: '+250 788 123 456',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save number'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (phoneNumber == null || _isSavingContact) return;

    setState(() => _isSavingContact = true);
    try {
      await ref
          .read(supportRepositoryProvider)
          .updateContact(phoneNumber: phoneNumber);
      ref.invalidate(practitionersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your Call and WhatsApp number was updated.'),
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
      if (mounted) setState(() => _isSavingContact = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final practitioners = ref.watch(practitionersProvider);
    final threads = ref.watch(supportThreadsProvider);

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
                  title: 'Practitioner Workspace',
                  subtitle:
                      'Welcome, ${user?.name.split(' ').first ?? 'Practitioner'}. Manage your live support and patient conversations.',
                  icon: Icons.support_agent_rounded,
                  gradient: const LinearGradient(
                    colors: [AppColors.emerald, AppColors.teal, AppColors.blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  trailing: const ProfileButton(),
                  largeTitle: true,
                ),
                const SizedBox(height: AppSpacing.xl),
                practitioners.when(
                  data: (items) => _LiveStatusCard(
                    practitioner: _ownProfile(items),
                    isSaving: _isSavingAvailability,
                    isSavingContact: _isSavingContact,
                    onChanged: _setAvailability,
                    onEditContact: _editContact,
                  ),
                  loading: () => const InlineLoadingCard(
                    message: 'Loading your live support status...',
                  ),
                  error: (error, stackTrace) => InlineErrorCard(
                    error: error,
                    onRetry: () => ref.invalidate(practitionersProvider),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                threads.when(
                  data: (items) => _WorkspaceSnapshot(threads: items),
                  loading: () => const InlineLoadingCard(
                    message: 'Loading your practitioner workspace...',
                  ),
                  error: (error, stackTrace) => InlineErrorCard(
                    error: error,
                    onRetry: () => ref.invalidate(supportThreadsProvider),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const _SectionHeading(
                  eyebrow: 'PATIENT SUPPORT',
                  title: 'Recent conversations',
                  subtitle:
                      'Open a patient conversation and respond privately.',
                ),
                const SizedBox(height: AppSpacing.md),
                threads.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const _EmptyInbox();
                    }
                    return Column(
                      children: [
                        for (final thread in items.take(4)) ...[
                          _PractitionerConversationTile(
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
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: MRButton(
                        label: 'Open patient inbox',
                        icon: Icons.forum_rounded,
                        onPressed: () => context.go('/support'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/learn'),
                        icon: const Icon(Icons.menu_book_rounded),
                        label: const Text('Resources'),
                      ),
                    ),
                  ],
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

class _LiveStatusCard extends StatelessWidget {
  const _LiveStatusCard({
    required this.practitioner,
    required this.isSaving,
    required this.isSavingContact,
    required this.onChanged,
    required this.onEditContact,
  });

  final Practitioner? practitioner;
  final bool isSaving;
  final bool isSavingContact;
  final ValueChanged<PractitionerAvailabilityStatus> onChanged;
  final ValueChanged<Practitioner> onEditContact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (practitioner == null) {
      return const MRCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.badge_outlined, color: AppColors.amber),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Your practitioner profile needs to be completed by a MindRise administrator before you can go online.',
              ),
            ),
          ],
        ),
      );
    }

    final availabilityStatus = practitioner!.availabilityStatus;
    final isOnline =
        availabilityStatus == PractitionerAvailabilityStatus.online;
    return MRCard(
      gradient: LinearGradient(
        colors: isOnline
            ? const [Color(0xFFE5FFF3), Color(0xFFE8F9FF)]
            : const [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isOnline ? AppColors.emerald : AppColors.muted,
                backgroundImage: practitioner!.profilePictureUrl.isNotEmpty
                    ? NetworkImage(practitioner!.profilePictureUrl)
                    : null,
                child: practitioner!.profilePictureUrl.isEmpty
                    ? const Icon(Icons.person_rounded, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You are ${availabilityStatus.label.toLowerCase()}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      practitioner!.specialization.isEmpty
                          ? 'MindRise practitioner'
                          : practitioner!.specialization,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isOnline
                ? 'Patients can choose you for support. Stay online only while you are ready to respond.'
                : 'Go online when you are ready to receive patient support requests.',
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 19, color: AppColors.teal),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  practitioner!.phoneNumber.isEmpty
                      ? 'No Call & WhatsApp number added'
                      : practitioner!.phoneNumber,
                ),
              ),
              TextButton.icon(
                onPressed: isSavingContact
                    ? null
                    : () => onEditContact(practitioner!),
                icon: isSavingContact
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
            ],
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

class _WorkspaceSnapshot extends StatelessWidget {
  const _WorkspaceSnapshot({required this.threads});

  final List<SupportThread> threads;

  @override
  Widget build(BuildContext context) {
    final openThreads = threads.where((thread) => !thread.isClosed).length;
    final textThreads = threads
        .where((thread) => thread.contactMethod == SupportContactMethod.text)
        .length;
    final recentToday = threads.where((thread) {
      final local = thread.updatedAt.toLocal();
      final now = DateTime.now();
      return local.year == now.year &&
          local.month == now.month &&
          local.day == now.day;
    }).length;

    return Row(
      children: [
        Expanded(
          child: _SnapshotMetric(
            label: 'Open',
            value: '$openThreads',
            icon: Icons.forum_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _SnapshotMetric(
            label: 'Text',
            value: '$textThreads',
            icon: Icons.chat_bubble_outline_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _SnapshotMetric(
            label: 'Today',
            value: '$recentToday',
            icon: Icons.today_rounded,
          ),
        ),
      ],
    );
  }
}

class _SnapshotMetric extends StatelessWidget {
  const _SnapshotMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MRCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.teal, size: 21),
          const SizedBox(height: 9),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _PractitionerConversationTile extends StatelessWidget {
  const _PractitionerConversationTile({
    required this.thread,
    required this.onTap,
  });

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
            child: const Icon(Icons.person_rounded, color: AppColors.blue),
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
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    return const MRCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.forum_outlined, color: AppColors.teal),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'No patient conversations yet. New private support requests will appear here.',
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
