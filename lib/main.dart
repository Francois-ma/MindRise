import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      _configureErrorHandling();
      await _configureDeviceChrome();
      await _configureFirebase();
      runApp(const ProviderScope(child: MindRiseApp()));
    },
    (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Uncaught MindRise error: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    },
  );
}

void _configureErrorHandling() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    Zone.current.handleUncaughtError(
      details.exception,
      details.stack ?? StackTrace.current,
    );
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    Zone.current.handleUncaughtError(error, stackTrace);
    return true;
  };
}

Future<void> _configureDeviceChrome() async {
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surfaceLight,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
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
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const _MindRiseScrollBehavior(),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class _MindRiseScrollBehavior extends MaterialScrollBehavior {
  const _MindRiseScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
