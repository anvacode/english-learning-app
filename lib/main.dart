import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'logic/lesson_controller.dart';
import 'logic/auth_provider.dart';
import 'services/theme_service.dart';
import 'services/firebase_service.dart';
import 'services/audio_service.dart';
import 'services/sync_service.dart';
import 'services/sync_queue_service.dart';
import 'services/usage_tracking_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with error handling
  try {
    await FirebaseService().initialize();
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Firebase initialization failed: $e');
    debugPrint('🔄 App will continue in offline mode');
  }

  await UsageTrackingService.instance.initialize();

  // Register lifecycle observer for cleanup on exit
  AppLifecycleListener(
    onResume: () {
      UsageTrackingService.instance.resume();
    },
    onInactive: () {
      UsageTrackingService.instance.pause().then(
        (_) => SyncService().scheduleSync(),
      );
    },
    onPause: () {
      UsageTrackingService.instance.pause().then(
        (_) => SyncService().scheduleSync(),
      );
    },
    onDetach: () {
      UsageTrackingService.instance.pause().then(
        (_) => SyncService().scheduleSync(),
      );
    },
    onExitRequested: () async {
      await UsageTrackingService.instance.pause();
      await SyncService().syncUserData();
      AudioService.disposeInstance();
      SyncService.disposeInstance();
      SyncQueueService.disposeInstance();
      return AppExitResponse.exit;
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => LessonController()),
        ChangeNotifierProvider(
          create: (context) => ThemeService()..initialize(),
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'English AI App',
            theme: ThemeService.getThemeData(themeService.activeThemeId),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
