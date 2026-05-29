import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/mr_card.dart';
import '../../auth/presentation/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
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
                    title: user?.name ?? 'Francois',
                    subtitle: user?.email ?? 'francois@mindrise.com',
                    icon: Icons.person_rounded,
                    leading: IconButton(
                      onPressed: () => context.go('/home'),
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: Colors.white,
                    ),
                    trailing: IconButton.filledTonal(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile editing is coming soon.'),
                          ),
                        );
                      },
                      tooltip: 'Edit profile',
                      icon: const Icon(Icons.edit_rounded),
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: .20),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Row(
                    children: [
                      Expanded(
                        child: _ProfileStat(
                          label: 'Current Streak',
                          value: '7 days',
                          icon: Icons.workspace_premium_rounded,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _ProfileStat(
                          label: 'Total Entries',
                          value: '42',
                          icon: Icons.calendar_month_rounded,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _ProfileStat(
                          label: 'Mood Average',
                          value: '7.2/10',
                          icon: Icons.favorite_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SettingsSection(
                    title: 'Preferences',
                    children: [
                      _SettingsTile(
                        icon: Icons.notifications_rounded,
                        label: 'Notifications',
                        trailing: Switch(
                          value: true,
                          onChanged: (_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Notification settings are coming soon.',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.calendar_today_rounded,
                        label: 'Daily Reminders',
                        trailing: Switch(
                          value: true,
                          onChanged: (_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Reminder settings are coming soon.',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const _SettingsTile(
                        icon: Icons.settings_rounded,
                        label: 'App Settings',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _SettingsSection(
                    title: 'Account',
                    children: [
                      _SettingsTile(
                        icon: Icons.lock_rounded,
                        label: 'Privacy & Security',
                      ),
                      _SettingsTile(
                        icon: Icons.person_rounded,
                        label: 'Personal Information',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _SettingsSection(
                    title: 'Support',
                    children: [
                      _SettingsTile(
                        icon: Icons.help_rounded,
                        label: 'Help Center',
                      ),
                    ],
                  ),
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
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

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
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        MRCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.label, this.trailing});

  final IconData icon;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      minVerticalPadding: 12,
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$label is coming soon.')));
      },
    );
  }
}
