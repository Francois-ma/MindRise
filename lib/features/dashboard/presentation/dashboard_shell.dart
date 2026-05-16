import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_background.dart';

class DashboardShell extends StatelessWidget {
  const DashboardShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(child: navigationShell),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: .92),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: .10),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (index) => navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                ),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.favorite_rounded),
                    label: 'Mood',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.bar_chart_rounded),
                    label: 'Insights',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.air_rounded),
                    label: 'Reset',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.menu_book_rounded),
                    label: 'Learn',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.chat_bubble_rounded),
                    label: 'Support',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
