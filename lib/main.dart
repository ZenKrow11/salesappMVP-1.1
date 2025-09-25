// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

// Import your other files
import 'firebase_options.dart';
import 'widgets/splash_screen.dart';
import 'widgets/login_screen.dart';
import 'pages/main_app_screen.dart';
import 'package:sales_app_mvp/widgets/loading_gate.dart';

// Required imports for the emulator setup
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'generated/app_localizations.dart';
//import 'package:flutter_gen/gen_l10n/app_localizations.dart';

//============================================================================
//  MAIN FUNCTION - The App's Entry Point
//============================================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize all external services here, in the correct order.
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
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    } catch (e) {
      debugPrint('Error: Failed to connect to Firebase emulators. $e');
    }
  }
  // END: Emulator connection block



  // firebase emulators:start --only firestore,auth

  // Initialize Hive for Flutter.
  await Hive.initFlutter();

  // Run the app.
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

//============================================================================
//  ROOT WIDGET - MyApp
//============================================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,

      // --- AuthGate is the single entry point of your app's UI. ---
      home: const AuthGate(),

      routes: {
        LoginScreen.routeName: (context) => const LoginScreen(),
        MainAppScreen.routeName: (context) => const MainAppScreen(),
      },
    );
  }
}

//============================================================================
//  SPLASH & AUTH PROVIDERS
//============================================================================

/// Ensures the splash screen is shown for a minimum duration for branding.
final splashControllerProvider = FutureProvider<void>((ref) async {
  // Adjust the duration as needed.
  await Future.delayed(const Duration(seconds: 2));
});

/// Provides the current authentication state of the user.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

//============================================================================
//  AUTH GATE WIDGET
//============================================================================

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch both the authentication state and the splash screen timer.
    final authState = ref.watch(authStateChangesProvider);
    final splashHasFinished = ref.watch(splashControllerProvider);

    // If the splash screen timer hasn't finished, always show the splash screen.
    // This takes precedence and ensures it's visible for a minimum time.
    if (splashHasFinished is! AsyncData) {
      return const SplashScreen();
    }

    // After the splash timer is done, then decide the screen based on auth state.
    return authState.when(
      data: (user) {
        if (user != null) {
          // USER IS SIGNED IN
          // Go to the LoadingGate to ensure data is ready.
          return const LoadingGate();
        } else {
          // USER IS SIGNED OUT
          // Go to the login screen.
          return const LoginScreen();
        }
      },
      // Keep showing splash if auth state is still loading after the timer.
      loading: () => const SplashScreen(),
      error: (err, stack) => Scaffold(
        body: Center(child: Text("Authentication Error: $err")),
      ),
    );
  }
}