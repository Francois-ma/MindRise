import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureFirebase();
  runApp(const ProviderScope(child: MindRiseApp()));
}

Future<void> _configureFirebase() async {
  try {
    await Firebase.initializeApp();
    await NotificationService.initialize();
  } on Object {
    // Firebase is optional until platform-specific configuration files are added.
  }
}

class MindRiseApp extends ConsumerWidget {
  const MindRiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'MindRise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
