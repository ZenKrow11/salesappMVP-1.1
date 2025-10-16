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


import 'package:sales_app_mvp/providers/grouped_products_provider.dart';
import 'generated/app_localizations.dart';


//============================================================================
//  MAIN FUNCTION - The App's Entry Point
//============================================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_DE', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

/*
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

 */


  // firebase emulators:start --only firestore,auth

  // Initialize Hive for Flutter.
  await Hive.initFlutter();

  // Run the app with a single, simple ProviderScope.
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
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,

      // The builder provides a context that is *inside* the MaterialApp,
      // which is essential for AppLocalizations.of(context) to work.
      builder: (context, child) {
        return ProviderScope(
          // This links to the root ProviderScope established in main().
          parent: ProviderScope.containerOf(context),
          overrides: [
            // This is now safe because the builder's context is valid.
            // It provides the l10n object for any provider that needs it.
            localizationProvider.overrideWithValue(AppLocalizations.of(context)!),
          ],
          // The 'child' is whatever widget tree 'home' or 'routes' would normally build.
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


//============================================================================
//  SPLASH & AUTH PROVIDERS
//============================================================================
final splashControllerProvider = FutureProvider<void>((ref) async {
  await Future.delayed(const Duration(seconds: 2));
});

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
    final authState = ref.watch(authStateChangesProvider);
    final splashHasFinished = ref.watch(splashControllerProvider);

    if (splashHasFinished is! AsyncData) {
      return const SplashScreen();
    }

    return authState.when(
      data: (user) {
        if (user != null) {
          return const LoadingGate();
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