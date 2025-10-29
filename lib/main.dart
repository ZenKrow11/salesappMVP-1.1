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
import 'providers/grouped_products_provider.dart'; // Import for localizationProvider
import 'generated/app_localizations.dart';
import 'services/ad_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_DE', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // START: Block to connect to Firebase Emulators in debug mode
  if (kDebugMode) {
    try {
      //local emulator
      //final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
      // IMPORTANT: Replace with your computer's actual IP on the Wi-Fi network
      final host = '192.168.1.116';
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8081);
    } catch (e) {
      debugPrint('Error: Failed to connect to Firebase emulators. $e');
    }
  }
  // END: Emulator connection block

  /// firebase emulators:start --only firestore,auth


  await Hive.initFlutter();

  // 1. Create the single, authoritative ProviderContainer for the entire app.
  final container = ProviderContainer();

  // 2. Use THIS container to initialize and pre-load everything.
  container.read(adManagerProvider.notifier).initialize();
  container.read(adManagerProvider.notifier).preloadBannerAd(AdPlacement.splashScreen, AdSize.banner);

  // 3. THIS IS THE CRITICAL FIX:
  // Use UncontrolledProviderScope to inject our pre-configured container
  // into the widget tree. This makes it the one and only scope.
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
      // The builder is still required to get the context for AppLocalizations.
      builder: (context, child) {
        return ProviderScope(
          // This correctly finds the container from UncontrolledProviderScope.
          parent: ProviderScope.containerOf(context),
          overrides: [
            // This now correctly overrides the provider in the ONE container.
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

// --- Provider definitions (Correct and Unchanged) ---

final splashControllerProvider = FutureProvider<void>((ref) async {
  await Future.delayed(const Duration(seconds: 2));
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<User?>>(authStateChangesProvider, (previous, next) {
      final user = next.value;
      if (user != null && previous?.value == null) {
        ref.read(appDataProvider.notifier).initialize();
      }
    });

    final authState = ref.watch(authStateChangesProvider);
    final splashHasFinished = ref.watch(splashControllerProvider);

    if (splashHasFinished is! AsyncData) {
      return const SplashScreen();
    }

    return authState.when(
      data: (user) {
        if (user != null) {
          return const LoadingRouter();
        } else {
          return const LoginScreen();
        }
      },
      loading: () => const SplashScreen(),
      error: (err, stack) => Scaffold(
        body: Center(child: Text("Authentication Error: $err")),
      ),
    );
  }
}