import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/mr_card.dart';
import '../../../core/widgets/profile_button.dart';
import '../../../core/widgets/screen_state.dart';
import '../../mood/data/mood_repository.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(moodSummaryProvider);
    final aiInsights = ref.watch(moodAiInsightsProvider(null));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(moodSummaryProvider);
        ref.invalidate(moodAiInsightsProvider(null));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 112),
            sliver: SliverList.list(
              children: [
                const GradientHeader(
                  title: 'Your Insights',
                  subtitle: 'Private patterns from your last 30 days.',
                  icon: Icons.trending_up_rounded,
                  gradient: LinearGradient(
                    colors: [AppColors.blue, Color(0xFF38BDF8), AppColors.cyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  trailing: ProfileButton(),
                ),
                const SizedBox(height: AppSpacing.xl),
                summary.when(
                  data: (data) => _InsightsContent(
                    summary: data,
                    aiInsights: aiInsights,
                    onRetryInsights: () =>
                        ref.invalidate(moodAiInsightsProvider(null)),
                  ),
                  loading: () => const InlineLoadingCard(
                    message: 'Building your insights...',
                  ),
                  error: (error, stackTrace) => InlineErrorCard(
                    error: error,
                    onRetry: () => ref.invalidate(moodSummaryProvider),
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

class _InsightsContent extends StatelessWidget {
  const _InsightsContent({
    required this.summary,
    required this.aiInsights,
    required this.onRetryInsights,
  });

  final MoodSummary summary;
  final AsyncValue<MoodAiInsights> aiInsights;
  final VoidCallback onRetryInsights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasScores = summary.weeklyScores.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Average',
                value: summary.averageScore == 0
                    ? '--'
                    : summary.averageScore.toStringAsFixed(1),
                icon: Icons.trending_up_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _MetricCard(
                label: 'Entries',
                value: summary.totalEntries.toString(),
                icon: Icons.edit_note_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _MetricCard(
                label: 'Top Mood',
                value: summary.mostFrequentMood ?? '--',
                icon: Icons.sentiment_very_satisfied_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        MRCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mood Trend',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (hasScores)
                SizedBox(
                  height: 230,
                  child: _WeeklyLineChart(points: summary.weeklyScores),
                )
              else
                const _EmptyChartMessage(),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'AI Mood Insights',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        aiInsights.when(
          data: (insights) {
            if (insights.cards.isEmpty) {
              return const MRCard(
                child: Text('Log a mood to receive AI-personalized insights.'),
              );
            }
            return Column(
              children: [
                for (final card in insights.cards) ...[
                  _AiInsightTile(card: card),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            );
          },
          loading: () =>
              const InlineLoadingCard(message: 'Generating AI insights...'),
          error: (error, stackTrace) => InlineErrorCard(
            title: 'AI insights unavailable',
            error: error,
            onRetry: onRetryInsights,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
      gradient: const LinearGradient(
        colors: [Color(0xFFEFFCF5), Color(0xFFE8F9FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.emerald, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _WeeklyLineChart extends StatelessWidget {
  const _WeeklyLineChart({required this.points});

  final List<MoodScorePoint> points;

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].score),
    ];

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 10,
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return Text(DateFormat.E().format(points[index].day.toLocal()));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 4,
            color: AppColors.emerald,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.emerald.withValues(alpha: .12),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChartMessage extends StatelessWidget {
  const _EmptyChartMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'Log a few moods to unlock weekly trends.',
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _AiInsightTile extends StatelessWidget {
  const _AiInsightTile({required this.card});

  final MoodAiInsightCard card;

  @override
  Widget build(BuildContext context) {
    final color = switch (card.tone) {
      'celebratory' => AppColors.emerald,
      'grounding' => AppColors.amber,
      'clinical' => AppColors.blue,
      _ => AppColors.teal,
    };
    final icon = switch (card.priority) {
      'high' => Icons.priority_high_rounded,
      'low' => Icons.lightbulb_rounded,
      _ => Icons.auto_awesome_rounded,
    };

    return MRCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: .12),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(card.message),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              card.action,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
