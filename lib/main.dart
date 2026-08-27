import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/setup/screens/firebase_setup_screen.dart';
import 'firebase_options.dart';
import 'navigation/app_router.dart';
import 'providers/telemetry_providers.dart';
import 'services/analytics_service.dart';
import 'services/crash_reporting_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = false;
  if (DefaultFirebaseOptions.isConfigured) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Offline cache for core reads/writes (Phase 10).
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    await CrashReportingService().initialize();
    await AnalyticsService().logAppOpen();
    firebaseReady = true;
  }

  runApp(
    ProviderScope(
      overrides: [
        telemetryEnabledProvider.overrideWithValue(firebaseReady),
      ],
      child: BusinessBuddyApp(firebaseReady: firebaseReady),
    ),
  );
}

class BusinessBuddyApp extends ConsumerWidget {
  const BusinessBuddyApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!firebaseReady) {
      return MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const FirebaseSetupScreen(),
      );
    }

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
