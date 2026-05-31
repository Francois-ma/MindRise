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
import '../theme/app_colors.dart';
import '../widgets/app_background.dart';

const _authCheckPath = '/auth-check';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: _authCheckPath,
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final path = state.uri.path;
      final isLoadingRoute = path == _authCheckPath;
      final isVerifyRoute = path == '/verify-email';
      final isAuthRoute =
          path == '/login' || path == '/signup' || isVerifyRoute;

      if (auth.isLoading) {
        return isLoadingRoute ? null : _authCheckPath;
      }

      if (!auth.isAuthenticated) {
        if (isLoadingRoute) return '/login';
        return isAuthRoute ? null : '/login';
      }

      if (!auth.isAuthorized) {
        final email = auth.user?.email ?? auth.pendingVerificationEmail ?? '';
        if (email.isEmpty) return '/login';
        if (isVerifyRoute) return null;
        return _verificationLocation(email);
      }

      if (isLoadingRoute || isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: _authCheckPath,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: _AuthCheckScreen()),
      ),
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

String _verificationLocation(String email) {
  return Uri(
    path: '/verify-email',
    queryParameters: {'email': email},
  ).toString();
}

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this.ref) {
    ref.listen(authControllerProvider, (previous, next) => notifyListeners());
  }

  final Ref ref;
}

class _AuthCheckScreen extends StatelessWidget {
  const _AuthCheckScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emerald.withValues(alpha: .14),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/images/mindrise_icon.jpeg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Checking your session',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.emerald,
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
