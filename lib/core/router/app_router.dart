import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/dashboard/presentation/dashboard_shell.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/learn/presentation/learn_screen.dart';
import '../../features/mood/presentation/mood_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/reset/presentation/reset_screen.dart';
import '../../features/support/data/support_repository.dart';
import '../../features/support/presentation/support_chat_screen.dart';
import '../../features/support/presentation/support_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final path = state.uri.path;
      final isAuthRoute =
          path == '/login' || path == '/signup' || path == '/verify-email';

      if (auth.isLoading) return null;
      if (!auth.isAuthenticated && !isAuthRoute) return '/login';
      if (auth.isAuthenticated && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SignupScreen()),
      ),
      GoRoute(
        path: '/verify-email',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return NoTransitionPage(child: VerifyEmailScreen(email: email));
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DashboardShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/mood',
                builder: (context, state) => const MoodScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/insights',
                builder: (context, state) => const InsightsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reset',
                builder: (context, state) => const ResetScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/learn',
                builder: (context, state) => const LearnScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/support',
                builder: (context, state) => const SupportScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/support/thread/:threadId',
        builder: (context, state) {
          final threadId =
              int.tryParse(state.pathParameters['threadId'] ?? '') ?? 0;
          final thread = state.extra is SupportThread
              ? state.extra! as SupportThread
              : null;
          return SupportChatScreen(
            threadId: threadId,
            title: thread?.displayName ?? 'Psychologist',
          );
        },
      ),
    ],
  );
});

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this.ref) {
    ref.listen(authControllerProvider, (previous, next) => notifyListeners());
  }

  final Ref ref;
}
