import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_background.dart';

class DashboardShell extends StatelessWidget {
  const DashboardShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    _DashboardDestination(
      icon: Icons.home_rounded,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _DashboardDestination(
      icon: Icons.favorite_border_rounded,
      selectedIcon: Icons.favorite_rounded,
      label: 'Mood',
    ),
    _DashboardDestination(
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
      label: 'Insights',
    ),
    _DashboardDestination(
      icon: Icons.air_rounded,
      selectedIcon: Icons.air_rounded,
      label: 'Reset',
    ),
    _DashboardDestination(
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book_rounded,
      label: 'Learn',
    ),
    _DashboardDestination(
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
      label: 'Support',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 720;

        if (useRail) {
          return Scaffold(
            floatingActionButton: const _AssistantFab(),
            body: AppBackground(
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 10, 16),
                    child: DecoratedBox(
                      decoration: _navigationDecoration(context),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: NavigationRail(
                          minWidth: 84,
                          selectedIndex: navigationShell.currentIndex,
                          onDestinationSelected: _goBranch,
                          labelType: NavigationRailLabelType.selected,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: .94),
                          indicatorColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          destinations: [
                            for (final item in _destinations)
                              NavigationRailDestination(
                                icon: Icon(item.icon),
                                selectedIcon: Icon(item.selectedIcon),
                                label: Text(item.label),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: navigationShell),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          floatingActionButton: const _AssistantFab(),
          body: AppBackground(child: navigationShell),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: DecoratedBox(
                decoration: _navigationDecoration(context),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: NavigationBar(
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: _goBranch,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.onlyShowSelected,
                    destinations: [
                      for (final item in _destinations)
                        NavigationDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon),
                          label: item.label,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  BoxDecoration _navigationDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.surface.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: theme.colorScheme.outlineVariant),
      boxShadow: [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: .10),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }
}

class _DashboardDestination {
  const _DashboardDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _AssistantFab extends StatelessWidget {
  const _AssistantFab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'mindrise-ai-assistant',
      onPressed: () => context.push('/chatbot'),
      icon: const Icon(Icons.smart_toy_rounded),
      label: const Text('AI'),
    );
  }
}
