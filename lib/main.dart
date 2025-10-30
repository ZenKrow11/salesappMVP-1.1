// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'widgets/splash_screen.dart';
import 'widgets/login_screen.dart';
import 'pages/main_app_screen.dart';
import 'widgets/loading_router.dart';
import 'providers/app_data_provider.dart';
import 'providers/grouped_products_provider.dart';
import 'generated/app_localizations.dart';
import 'services/ad_manager.dart';

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

  await Hive.initFlutter();

  final container = ProviderContainer();
  container.read(adManagerProvider.notifier).initialize();
  if(!USE_EMULATOR) {
    container.read(adManagerProvider.notifier).preloadBannerAd(AdPlacement.splashScreen, AdSize.banner);
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
            localizationProvider.overrideWithValue(AppLocalizations.of(context)!),
          ],
          child: child!,
        );
      },
      home: const AuthGate(),
      routes: {
        LoginScreen.routeName: (context) => const LoginScreen(),
        MainAppScreen.routeName: (context) => const MainAppScreen(),
      },
    );
  }
}

// --- THIS PROVIDER IS REMOVED ---
// The artificial 2-second delay is no longer needed. The app's loading
// is now tied to the real-time check of the Firebase auth state.
/*
final splashControllerProvider = FutureProvider<void>((ref) async {
  await Future.delayed(const Duration(seconds: 2));
});
*/

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

//============================================================================
//  AUTH GATE WIDGET - OPTIMIZED VERSION
//============================================================================
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This listener correctly triggers data loading ONLY upon a successful login event.
    ref.listen<AsyncValue<User?>>(authStateChangesProvider, (previous, next) {
      final user = next.value;
      if (user != null && previous?.value == null) {
        ref.read(appDataProvider.notifier).initialize();
      }
    });

    final authState = ref.watch(authStateChangesProvider);

    // This is the new, streamlined logic.
    return authState.when(
      data: (user) {
        // If we have an answer from Firebase...
        if (user != null) {
          // ...and the user is logged in, show the data loading flow.
          return const LoadingRouter();
        } else {
          // ...and the user is logged out, go IMMEDIATELY to the LoginScreen.
          return const LoginScreen();
        }
      },
      // The ONLY time we show the SplashScreen is while we are waiting
      // for that first answer from Firebase.
      loading: () => const SplashScreen(),
      error: (err, stack) => Scaffold(
        body: Center(child: Text("Authentication Error: $err")),
      ),
    );
  }
}