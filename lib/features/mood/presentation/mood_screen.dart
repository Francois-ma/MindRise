import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/mr_button.dart';
import '../../../core/widgets/mr_card.dart';
import '../../../core/widgets/mr_text_field.dart';
import '../../../core/widgets/profile_button.dart';
import '../../../core/widgets/screen_state.dart';
import '../data/mood_repository.dart';

class MoodScreen extends ConsumerStatefulWidget {
  const MoodScreen({super.key});

  @override
  ConsumerState<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends ConsumerState<MoodScreen> {
  final _noteController = TextEditingController();
  String? _selectedMood;
  double _score = 7;
  bool _isSaving = false;

  static const moods = [
    MoodOption(
      'happy',
      'Happy',
      Icons.sentiment_very_satisfied_rounded,
      AppColors.amber,
    ),
    MoodOption('calm', 'Calm', Icons.spa_rounded, AppColors.blue),
    MoodOption(
      'stressed',
      'Stress',
      Icons.thunderstorm_rounded,
      Color(0xFFF97316),
    ),
    MoodOption(
      'sad',
      'Sad',
      Icons.sentiment_dissatisfied_rounded,
      Color(0xFF6366F1),
    ),
    MoodOption(
      'angry',
      'Angry',
      Icons.local_fire_department_rounded,
      AppColors.rose,
    ),
    MoodOption('energetic', 'Energy', Icons.bolt_rounded, AppColors.lime),
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveMood() async {
    final mood = _selectedMood;
    if (mood == null || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      await ref
          .read(moodRepositoryProvider)
          .createEntry(
            mood: mood,
            score: _score.round(),
            note: _noteController.text.trim(),
          );
      _noteController.clear();
      ref.invalidate(moodAiInsightsProvider(mood));
      ref.invalidate(moodAiInsightsProvider(null));
      setState(() {
        _selectedMood = null;
        _score = 7;
      });
      ref.invalidate(moodEntriesProvider);
      ref.invalidate(moodSummaryProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Mood saved securely.')));
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userMessageFromError(error))));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = ref.watch(moodEntriesProvider);
    final selectedMoodInsights = _selectedMood == null
        ? null
        : ref.watch(moodAiInsightsProvider(_selectedMood));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(moodEntriesProvider),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 112),
            sliver: SliverList.list(
              children: [
                const GradientHeader(
                  title: 'How are you feeling?',
                  subtitle:
                      'Your journal is private and synced to your account.',
                  icon: Icons.favorite_rounded,
                  trailing: ProfileButton(),
                ),
                const SizedBox(height: AppSpacing.xl),
                MRCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select your mood',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      GridView.builder(
                        itemCount: moods.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemBuilder: (context, index) {
                          final mood = moods[index];
                          final isSelected = _selectedMood == mood.id;
                          return _MoodTile(
                            mood: mood,
                            isSelected: isSelected,
                            onTap: () =>
                                setState(() => _selectedMood = mood.id),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (selectedMoodInsights != null) ...[
                  selectedMoodInsights.when(
                    data: (insights) =>
                        _SelectedMoodInsight(insights: insights),
                    loading: () => const InlineLoadingCard(
                      message: 'Personalizing guidance for this mood...',
                    ),
                    error: (error, stackTrace) => InlineErrorCard(
                      title: 'Mood guidance unavailable',
                      error: error,
                      onRetry: () =>
                          ref.invalidate(moodAiInsightsProvider(_selectedMood)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                MRCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Intensity',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_score.round()}/10',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.emerald,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _score,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: _score.round().toString(),
                        onChanged: (value) => setState(() => _score = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                MRCard(
                  child: MRTextField(
                    label: 'What made you feel this way?',
                    hint: 'Write your thoughts here...',
                    controller: _noteController,
                    maxLines: 5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                MRButton(
                  label: 'Save Mood',
                  icon: Icons.save_rounded,
                  isLoading: _isSaving,
                  onPressed: _selectedMood == null ? null : _saveMood,
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Entries',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                entries.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const MRCard(
                        child: Text(
                          'No entries yet. Your first check-in will appear here.',
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final entry in items.take(6)) ...[
                          _RecentMood(entry: entry),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    );
                  },
                  loading: () => const InlineLoadingCard(
                    message: 'Loading recent entries...',
                  ),
                  error: (error, stackTrace) => InlineErrorCard(
                    error: error,
                    onRetry: () => ref.invalidate(moodEntriesProvider),
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

class _SelectedMoodInsight extends StatelessWidget {
  const _SelectedMoodInsight({required this.insights});

  final MoodAiInsights insights;

  @override
  Widget build(BuildContext context) {
    final card = insights.cards.isEmpty ? null : insights.cards.first;
    if (card == null) return const SizedBox.shrink();

    final color = switch (card.tone) {
      'celebratory' => AppColors.emerald,
      'grounding' => AppColors.amber,
      'clinical' => AppColors.blue,
      _ => AppColors.teal,
    };

    return MRCard(
      gradient: LinearGradient(
        colors: [
          color.withValues(alpha: .12),
          Theme.of(context).colorScheme.surface,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: .14),
            child: Icon(Icons.auto_awesome_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(card.message),
                const SizedBox(height: 10),
                Text(
                  card.action,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MoodOption {
  const MoodOption(this.id, this.label, this.icon, this.color);

  final String id;
  final String label;
  final IconData icon;
  final Color color;
}

class _MoodTile extends StatelessWidget {
  const _MoodTile({
    required this.mood,
    required this.isSelected,
    required this.onTap,
  });

  final MoodOption mood;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: mood.label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected
              ? mood.color
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: .4)
                : Colors.transparent,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                mood.icon,
                color: isSelected ? Colors.white : mood.color,
                size: 30,
              ),
              const SizedBox(height: 8),
              Text(
                mood.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentMood extends StatelessWidget {
  const _RecentMood({required this.entry});

  final MoodEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final option = _MoodScreenState.moods.firstWhere(
      (mood) => mood.id == entry.mood,
      orElse: () => const MoodOption(
        'neutral',
        'Neutral',
        Icons.sentiment_neutral_rounded,
        AppColors.cyan,
      ),
    );

    return MRCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: option.color.withValues(alpha: .14),
            child: Icon(option.icon, color: option.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${option.label} · ${entry.score}/10',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      DateFormat.MMMd().format(entry.occurredAt.toLocal()),
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
                if (entry.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
