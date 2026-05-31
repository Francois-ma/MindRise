import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/mr_card.dart';
import '../../../core/widgets/screen_state.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../mood/data/mood_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final summary = ref.watch(moodSummaryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: AppBackground(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              sliver: SliverList.list(
                children: [
                  GradientHeader(
                    title: user?.name ?? 'MindRise member',
                    subtitle: user?.email ?? 'Authenticated account',
                    icon: Icons.verified_user_rounded,
                    leading: IconButton(
                      onPressed: () => context.go('/home'),
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _AccountStatusCard(user: user),
                  const SizedBox(height: AppSpacing.xl),
                  summary.when(
                    data: (data) => _WellnessStats(summary: data),
                    loading: () => const InlineLoadingCard(
                      message: 'Loading your wellness record...',
                    ),
                    error: (error, stackTrace) => InlineErrorCard(
                      title: 'Wellness record unavailable',
                      error: error,
                      onRetry: () => ref.invalidate(moodSummaryProvider),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _AccountSection(
                    title: 'Account Access',
                    children: [
                      _AccountRow(
                        icon: Icons.mail_rounded,
                        label: 'Email',
                        value: user?.email ?? 'Not available',
                      ),
                      _AccountRow(
                        icon: Icons.badge_rounded,
                        label: 'Role',
                        value: _roleLabel(user?.role),
                      ),
                      _AccountRow(
                        icon: Icons.verified_rounded,
                        label: 'Verification',
                        value: user?.isEmailVerified == true
                            ? 'Verified'
                            : 'Verification required',
                        valueColor: user?.isEmailVerified == true
                            ? AppColors.emerald
                            : theme.colorScheme.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _PrivacyCard(),
                  const SizedBox(height: AppSpacing.xl),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Log Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: .35),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'MindRise v1.0.0',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountStatusCard extends StatelessWidget {
  const _AccountStatusCard({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verified = user?.isEmailVerified == true;

    return MRCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: verified
                ? AppColors.emerald
                : theme.colorScheme.errorContainer,
            child: Icon(
              verified ? Icons.lock_rounded : Icons.lock_open_rounded,
              color: verified
                  ? Colors.white
                  : theme.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verified ? 'Secure account' : 'Verification required',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  verified
                      ? 'Your MindRise account is authorized for private wellness features.'
                      : 'Verify your email before using private wellness features.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(
                      icon: Icons.verified_user_rounded,
                      label: verified ? 'Verified' : 'Pending',
                      color: verified
                          ? AppColors.emerald
                          : theme.colorScheme.error,
                    ),
                    _StatusChip(
                      icon: Icons.badge_rounded,
                      label: _roleLabel(user?.role),
                      color: AppColors.teal,
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
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WellnessStats extends StatelessWidget {
  const _WellnessStats({required this.summary});

  final MoodSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ProfileStat(
            label: 'Average',
            value: summary.averageScore == 0
                ? '--'
                : summary.averageScore.toStringAsFixed(1),
            icon: Icons.monitor_heart_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ProfileStat(
            label: 'Entries',
            value: summary.totalEntries.toString(),
            icon: Icons.calendar_month_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ProfileStat(
            label: 'Top mood',
            value: _formatMood(summary.mostFrequentMood),
            icon: Icons.psychology_alt_rounded,
          ),
        ),
      ],
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return MRCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Icon(icon, color: AppColors.emerald),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        MRCard(
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.emerald),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: valueColor ?? theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MRCard(
      gradient: LinearGradient(
        colors: [
          theme.colorScheme.primaryContainer.withValues(alpha: .72),
          theme.colorScheme.surfaceContainerLow,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_rounded, color: AppColors.emerald),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Private by design',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your wellness records are loaded only after sign-in and are tied to your secure MindRise account.',
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

String _roleLabel(AppUserRole? role) {
  return switch (role) {
    AppUserRole.patient => 'Member',
    AppUserRole.practitioner => 'Practitioner',
    AppUserRole.admin => 'Administrator',
    AppUserRole.unknown || null => 'Member',
  };
}

String _formatMood(String? mood) {
  if (mood == null || mood.trim().isEmpty) return '--';
  return mood
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
