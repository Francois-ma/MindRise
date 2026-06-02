import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/mr_card.dart';
import '../../../core/widgets/profile_button.dart';
import '../../../core/widgets/screen_state.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../mood/data/mood_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).user;
    final summary = ref.watch(moodSummaryProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(moodSummaryProvider),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 112),
            sliver: SliverList.list(
              children: [
                GradientHeader(
                  title:
                      'Welcome back, ${user?.name.split(' ').first ?? 'there'}',
                  subtitle: 'A calmer day starts with one honest check-in.',
                  icon: Icons.auto_awesome_rounded,
                  trailing: const ProfileButton(),
                  largeTitle: true,
                ),
                const SizedBox(height: AppSpacing.xl),
                const _TrustRibbon(),
                const SizedBox(height: AppSpacing.lg),
                summary.when(
                  data: (data) => _CareSnapshot(summary: data),
                  loading: () => const InlineLoadingCard(
                    message: 'Syncing your care snapshot...',
                  ),
                  error: (error, stackTrace) => InlineErrorCard(
                    title: 'Care snapshot unavailable',
                    error: error,
                    onRetry: () => ref.invalidate(moodSummaryProvider),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                MRCard(
                  child: Column(
                    children: [
                      Text(
                        'Quick Mood Check',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.spaceBetween,
                        children: const [
                          _MoodShortcut(
                            icon: Icons.sentiment_very_satisfied,
                            label: 'Happy',
                          ),
                          _MoodShortcut(icon: Icons.spa_rounded, label: 'Calm'),
                          _MoodShortcut(
                            icon: Icons.sentiment_neutral_rounded,
                            label: 'Neutral',
                          ),
                          _MoodShortcut(
                            icon: Icons.sentiment_dissatisfied_rounded,
                            label: 'Sad',
                          ),
                          _MoodShortcut(
                            icon: Icons.thunderstorm_rounded,
                            label: 'Stress',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const MRCard(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFF7D6), Color(0xFFFFEDD5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: AppColors.amber),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Small check-ins create useful patterns. Log the moment while it is fresh.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const _CarePlanCard(),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.25,
                  children: [
                    _ActionTile(
                      icon: Icons.favorite_rounded,
                      label: 'Track Mood',
                      metric: '30 sec',
                      gradient: AppColors.primaryGradient,
                      onTap: () => context.go('/mood'),
                    ),
                    _ActionTile(
                      icon: Icons.bar_chart_rounded,
                      label: 'View Insights',
                      metric: 'Patterns',
                      gradient: const LinearGradient(
                        colors: [AppColors.blue, AppColors.cyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () => context.go('/insights'),
                    ),
                    _ActionTile(
                      icon: Icons.air_rounded,
                      label: 'Reset Mind',
                      metric: '1-5 min',
                      gradient: const LinearGradient(
                        colors: [AppColors.amber, Color(0xFFF97316)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () => context.go('/reset'),
                    ),
                    _ActionTile(
                      icon: Icons.menu_book_rounded,
                      label: 'Learn',
                      metric: 'Guides',
                      gradient: const LinearGradient(
                        colors: [AppColors.lime, AppColors.emerald],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () => context.go('/learn'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _WideAction(
                  icon: Icons.edit_note_rounded,
                  label: 'Write in Journal',
                  onTap: () => context.go('/mood'),
                ),
                const SizedBox(height: AppSpacing.md),
                _WideAction(
                  icon: Icons.smart_toy_rounded,
                  label: 'Ask MindRise Assistant',
                  color: AppColors.emerald,
                  onTap: () => context.push('/chatbot'),
                ),
                const SizedBox(height: AppSpacing.md),
                _WideAction(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Talk to Support',
                  color: AppColors.blue,
                  onTap: () => context.go('/support'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustRibbon extends StatelessWidget {
  const _TrustRibbon();

  @override
  Widget build(BuildContext context) {
    return const MRCard(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _TrustItem(
              icon: Icons.verified_user_rounded,
              label: 'Private',
            ),
          ),
          Expanded(
            child: _TrustItem(
              icon: Icons.science_rounded,
              label: 'Evidence-informed',
            ),
          ),
          Expanded(
            child: _TrustItem(icon: Icons.groups_rounded, label: 'Community'),
          ),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.emerald, size: 22),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _CarePlanCard extends StatelessWidget {
  const _CarePlanCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MRCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.emerald,
                child: Icon(Icons.route_rounded, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Today\'s care path',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _CareStep(
            label: 'Check in honestly',
            icon: Icons.favorite_rounded,
          ),
          const _CareStep(
            label: 'Notice one pattern',
            icon: Icons.insights_rounded,
          ),
          const _CareStep(
            label: 'Choose one small reset',
            icon: Icons.spa_rounded,
          ),
        ],
      ),
    );
  }
}

class _CareStep extends StatelessWidget {
  const _CareStep({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.teal, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _CareSnapshot extends StatelessWidget {
  const _CareSnapshot({required this.summary});

  final MoodSummary summary;

  @override
  Widget build(BuildContext context) {
    return MRCard(
      child: Row(
        children: [
          Expanded(
            child: _SnapshotMetric(
              label: 'Mood Avg',
              value: summary.averageScore == 0
                  ? '--'
                  : summary.averageScore.toStringAsFixed(1),
              icon: Icons.monitor_heart_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SnapshotMetric(
              label: 'Entries',
              value: summary.totalEntries.toString(),
              icon: Icons.calendar_month_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SnapshotMetric(
              label: 'Top Mood',
              value: summary.mostFrequentMood ?? '--',
              icon: Icons.psychology_alt_rounded,
            ),
          ),
        ],
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.emerald),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _MoodShortcut extends StatelessWidget {
  const _MoodShortcut({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: InkWell(
        onTap: () => context.go('/mood'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Icon(icon, size: 30, color: AppColors.emerald),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.metric,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String metric;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white),
                const Spacer(),
                Text(
                  metric,
                  style: TextStyle(color: Colors.white.withValues(alpha: .78)),
                ),
              ],
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideAction extends StatelessWidget {
  const _WideAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.emerald,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color),
      label: Align(alignment: Alignment.centerLeft, child: Text(label)),
      style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft),
    );
  }
}
