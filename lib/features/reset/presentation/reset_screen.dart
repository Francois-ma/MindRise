import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/mr_button.dart';
import '../../../core/widgets/mr_card.dart';
import '../../../core/widgets/mr_text_field.dart';
import '../../../core/widgets/profile_button.dart';

enum ResetActivity { breathing, gratitude, reframing, meditation }

class ResetScreen extends StatefulWidget {
  const ResetScreen({super.key});

  @override
  State<ResetScreen> createState() => _ResetScreenState();
}

class _ResetScreenState extends State<ResetScreen>
    with SingleTickerProviderStateMixin {
  final _gratitudeControllers = List.generate(
    3,
    (_) => TextEditingController(),
  );
  final _negativeThoughtController = TextEditingController();
  final _reframedThoughtController = TextEditingController();
  late final AnimationController _breathingController;
  Timer? _timer;
  ResetActivity? _activity;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
      lowerBound: .7,
      upperBound: 1.35,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingController.dispose();
    for (final controller in _gratitudeControllers) {
      controller.dispose();
    }
    _negativeThoughtController.dispose();
    _reframedThoughtController.dispose();
    super.dispose();
  }

  void _startBreathing(int seconds) {
    _timer?.cancel();
    setState(() => _remainingSeconds = seconds);
    _breathingController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _breathingController.stop();
        setState(() => _remainingSeconds = 0);
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = _activity == null
        ? _activityList(context)
        : _activityDetail(context, _activity!);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      child: content,
    );
  }

  Widget _activityList(BuildContext context) {
    return CustomScrollView(
      key: const ValueKey('reset-list'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 112),
          sliver: SliverList.list(
            children: [
              const GradientHeader(
                title: 'Reset Your Mind',
                subtitle: 'Choose a wellness activity to center yourself',
                icon: Icons.air_rounded,
                gradient: LinearGradient(
                  colors: [AppColors.amber, Color(0xFFF97316)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                trailing: ProfileButton(),
              ),
              const SizedBox(height: AppSpacing.xl),
              _ActivityTile(
                title: 'Breathing Exercises',
                description: 'Calm your mind with guided breathing',
                icon: Icons.air_rounded,
                color: AppColors.blue,
                onTap: () =>
                    setState(() => _activity = ResetActivity.breathing),
              ),
              const SizedBox(height: AppSpacing.md),
              _ActivityTile(
                title: 'Gratitude Journaling',
                description: "Focus on what you're grateful for",
                icon: Icons.favorite_rounded,
                color: AppColors.emerald,
                onTap: () =>
                    setState(() => _activity = ResetActivity.gratitude),
              ),
              const SizedBox(height: AppSpacing.md),
              _ActivityTile(
                title: 'Thought Reframing',
                description:
                    'Transform negative thoughts into constructive ones',
                icon: Icons.refresh_rounded,
                color: AppColors.amber,
                onTap: () =>
                    setState(() => _activity = ResetActivity.reframing),
              ),
              const SizedBox(height: AppSpacing.md),
              _ActivityTile(
                title: 'Quick Meditation',
                description: 'Short guided meditation sessions',
                icon: Icons.psychology_rounded,
                color: AppColors.lime,
                onTap: () =>
                    setState(() => _activity = ResetActivity.meditation),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Quick Affirmations',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final affirmation in const [
                'You are safe.',
                'This moment will pass.',
                'You are in control.',
                'You are worthy of peace.',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: MRCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.blue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(affirmation)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _activityDetail(BuildContext context, ResetActivity activity) {
    final title = switch (activity) {
      ResetActivity.breathing => 'Breathing Exercise',
      ResetActivity.gratitude => 'Gratitude Journaling',
      ResetActivity.reframing => 'Thought Reframing',
      ResetActivity.meditation => 'Quick Meditation',
    };

    return CustomScrollView(
      key: ValueKey(activity),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 112),
          sliver: SliverList.list(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _activity = null),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to Activities'),
                ),
              ),
              GradientHeader(
                title: title,
                subtitle: 'A focused exercise for this moment',
                icon: Icons.spa_rounded,
              ),
              const SizedBox(height: AppSpacing.xl),
              switch (activity) {
                ResetActivity.breathing => _breathingView(),
                ResetActivity.gratitude => _gratitudeView(),
                ResetActivity.reframing => _reframingView(),
                ResetActivity.meditation => _meditationView(),
              },
            ],
          ),
        ),
      ],
    );
  }

  Widget _breathingView() {
    final minutes = (_remainingSeconds ~/ 60).toString();
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return MRCard(
      child: Column(
        children: [
          const SizedBox(height: 16),
          ScaleTransition(
            scale: _breathingController,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withValues(alpha: .25),
                    blurRadius: 40,
                    spreadRadius: 16,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _remainingSeconds == 0 ? 'Breathe' : '$minutes:$seconds',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _startBreathing(60),
                  child: const Text('1 min'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _startBreathing(180),
                  child: const Text('3 min'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _startBreathing(300),
                  child: const Text('5 min'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gratitudeView() {
    return Column(
      children: [
        for (var i = 0; i < _gratitudeControllers.length; i++) ...[
          MRCard(
            child: MRTextField(
              label: 'Gratitude ${i + 1}',
              hint: 'I am grateful for...',
              controller: _gratitudeControllers[i],
              icon: Icons.favorite_rounded,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        MRButton(
          label: 'Save Gratitude',
          icon: Icons.save_rounded,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _reframingView() {
    return Column(
      children: [
        MRCard(
          child: MRTextField(
            label: 'Negative thought',
            controller: _negativeThoughtController,
            maxLines: 4,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        MRCard(
          child: MRTextField(
            label: 'Balanced reframe',
            controller: _reframedThoughtController,
            maxLines: 4,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        MRButton(
          label: 'Save Reframe',
          icon: Icons.check_rounded,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _meditationView() {
    return Column(
      children: const [
        _MeditationTile(
          title: 'Body Scan',
          duration: '5 min',
          description: 'Release tension from head to toe',
        ),
        SizedBox(height: AppSpacing.md),
        _MeditationTile(
          title: 'Loving Kindness',
          duration: '7 min',
          description: 'Cultivate compassion for yourself',
        ),
        SizedBox(height: AppSpacing.md),
        _MeditationTile(
          title: 'Mindful Awareness',
          duration: '10 min',
          description: 'Be present in this moment',
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MRCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _MeditationTile extends StatelessWidget {
  const _MeditationTile({
    required this.title,
    required this.duration,
    required this.description,
  });

  final String title;
  final String duration;
  final String description;

  @override
  Widget build(BuildContext context) {
    return MRCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            Icons.play_circle_fill_rounded,
            color: AppColors.emerald,
            size: 34,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Chip(label: Text(duration)),
        ],
      ),
    );
  }
}
