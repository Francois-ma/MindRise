import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_background.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';

class DashboardShell extends ConsumerWidget {
  const DashboardShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _patientDestinations = [
    _DashboardDestination(
      branchIndex: 0,
      icon: Icons.home_rounded,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _DashboardDestination(
      branchIndex: 1,
      icon: Icons.favorite_border_rounded,
      selectedIcon: Icons.favorite_rounded,
      label: 'Mood',
    ),
    _DashboardDestination(
      branchIndex: 2,
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
      label: 'Insights',
    ),
    _DashboardDestination(
      branchIndex: 3,
      icon: Icons.air_rounded,
      selectedIcon: Icons.air_rounded,
      label: 'Reset',
    ),
    _DashboardDestination(
      branchIndex: 4,
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book_rounded,
      label: 'Learn',
    ),
    _DashboardDestination(
      branchIndex: 5,
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
      label: 'Support',
    ),
  ];

  static const _practitionerDestinations = [
    _DashboardDestination(
      branchIndex: 0,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: 'Overview',
    ),
    _DashboardDestination(
      branchIndex: 5,
      icon: Icons.forum_outlined,
      selectedIcon: Icons.forum_rounded,
      label: 'Patients',
    ),
    _DashboardDestination(
      branchIndex: 4,
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book_rounded,
      label: 'Resources',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authControllerProvider).user?.role;
    final isPractitioner = role == AppUserRole.practitioner;
    final destinations = isPractitioner
        ? _practitionerDestinations
        : _patientDestinations;
    final selectedIndex = _selectedIndex(destinations);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 720;

        if (useRail) {
          return Scaffold(
            floatingActionButton: isPractitioner ? null : const _AssistantFab(),
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
                          selectedIndex: selectedIndex,
                          onDestinationSelected: (index) =>
                              _goDestination(destinations[index]),
                          labelType: NavigationRailLabelType.selected,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: .94),
                          indicatorColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          destinations: [
                            for (final item in destinations)
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
          floatingActionButton: isPractitioner ? null : const _AssistantFab(),
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
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (index) =>
                        _goDestination(destinations[index]),
                    labelBehavior:
                        NavigationDestinationLabelBehavior.onlyShowSelected,
                    destinations: [
                      for (final item in destinations)
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

  int _selectedIndex(List<_DashboardDestination> destinations) {
    final index = destinations.indexWhere(
      (destination) => destination.branchIndex == navigationShell.currentIndex,
    );
    return index < 0 ? 0 : index;
  }

  void _goDestination(_DashboardDestination destination) {
    navigationShell.goBranch(
      destination.branchIndex,
      initialLocation: destination.branchIndex == navigationShell.currentIndex,
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
    required this.branchIndex,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final int branchIndex;
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
