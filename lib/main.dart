// lib/main.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sales_app_mvp/providers/auth_wrapper.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/pages/main_app_screen.dart';
import 'package:sales_app_mvp/providers/grouped_products_provider.dart';
import 'package:sales_app_mvp/services/ad_manager.dart';
import 'package:sales_app_mvp/services/firestore_service.dart';
import 'package:sales_app_mvp/widgets/login_screen.dart';

import 'firebase_options.dart';

const bool USE_EMULATOR = bool.fromEnvironment('USE_EMULATOR');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_DE', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (USE_EMULATOR) {
    try {
      final host = '192.168.1.116';
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8081);
      debugPrint('>>> CONNECTING TO FIREBASE EMULATORS AT $host <<<');
    } catch (e) {
      debugPrint('Error: Failed to connect to Firebase emulators. $e');
    }
  } else {
    debugPrint('>>> CONNECTING TO LIVE FIREBASE PRODUCTION <<<');
  }

  /// firebase emulators:start --only firestore,auth

  await Hive.initFlutter();

  // Pre-initialize providers that need to start work before the UI is built.
  final container = ProviderContainer();
  container.read(adManagerProvider.notifier).initialize();
  if (!USE_EMULATOR) {
    container
        .read(adManagerProvider.notifier)
        .preloadBannerAd(AdPlacement.splashScreen, AdSize.banner);
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authStateObserverProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return ProviderScope(
          parent: ProviderScope.containerOf(context),
          overrides: [
            localizationProvider
                .overrideWithValue(AppLocalizations.of(context)!),
          ],
          child: child!,
        );
      },
      home: const AuthWrapper(),
      routes: {
        LoginScreen.routeName: (context) => const LoginScreen(),
        MainAppScreen.routeName: (context) => const MainAppScreen(),
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Core Application Providers defined in main.dart
// -----------------------------------------------------------------------------

/// Streams the current Firebase Authentication user state (logged in or out).
/// This is the primary source of truth for the user's auth status.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// An observer that watches the authentication state. When a user logs in,
/// it triggers the creation of their Firestore profile document if it doesn't exist.
/// This is a "fire-and-forget" provider that runs a crucial background task.
final authStateObserverProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<User?>>(authStateChangesProvider,
          (previous, next) async {
        final user = next.value;
        if (user != null) {
          await ref.read(firestoreServiceProvider).createUserProfile(user);
        }
      });
});