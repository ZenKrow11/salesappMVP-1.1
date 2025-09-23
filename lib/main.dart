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
import 'package:sales_app_mvp/providers/auth_controller.dart';

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

/*
  // START: Block to connect to Firebase Emulators in debug mode
  if (kDebugMode) {
    try {
      // Emulator connection
      //final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';

      // Physical phone connection
      final host = Platform.isAndroid ? '192.168.1.116' : 'localhost';

      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    } catch (e) {
      debugPrint('Error: Failed to connect to Firebase emulators. $e');
    }
  }
  // END: Emulator connection block
*/


  /// firebase emulators:start --only firestore,auth

  await Hive.initFlutter();

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
      title: 'SaleSeekr', // Using hardcoded title since appName is not in localization
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
      routes: {
        LoginScreen.routeName: (context) => const LoginScreen(),
        MainAppScreen.routeName: (context) => const MainAppScreen(),
      },

      // ===================== WIRING UP LOCALIZATION =====================
      // These lines were correct before, they just couldn't find the class.
      // Now they will work.
      //localizationsDelegates: AppLocalizations.localizationsDelegates,
      //supportedLocales: AppLocalizations.supportedLocales,

      // Optional but recommended: Localize the app's title
      // onGenerateTitle: (context) {
      //   // This requires you to have an appName key in your localization files
      //   // Since appName is not currently defined, we're using hardcoded title above
      //   return AppLocalizations.of(context)!.appName;
      // },
      // ===================================================================
    );
  }
}

//============================================================================
//  AUTH STATE & DATA VALIDATION PROVIDERS (THIS PART IS CORRECT)
//============================================================================
final authValidationProvider = StreamProvider<User?>((ref) async* {
  // Listen to the raw Firebase auth state changes
  final authStream = FirebaseAuth.instance.authStateChanges();

  // Yield values from the auth stream
  await for (final user in authStream) {
    if (user == null) {
      // 1. User is signed out, yield null to navigate to LoginScreen.
      yield null;
    } else {
      // 2. User is signed in according to the local cache.
      //    NOW, we must verify their data exists in Firestore.
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          // 3. SUCCESS: The user is valid in Auth AND Firestore.
          //    Yield the user object to navigate to the main app.
          yield user;
        } else {
          // 4. FAILSAFE: Orphan user detected (exists in Auth, not Firestore).
          //    Sign them out immediately and yield null. The UI will react to the null.
          //    Use `ref.read` only within the `build` method or other lifecycle methods
          //    that are guaranteed to run *after* the provider scope is initialized.
          //    For a StreamProvider, this is typically fine.
          await ref.read(authControllerProvider.notifier).signOut();
          yield null;
        }
      } catch (e) {
        // 5. Handle potential Firestore errors (e.g., network issue).
        //    Sign out as a safety measure and yield null.
        print('Error validating user document: $e');
        await ref.read(authControllerProvider.notifier).signOut();
        yield null;
      }
    }
  }
});

//============================================================================
//  AUTH GATE WIDGET (THIS IS THE REPLACED, SIMPLIFIED PART)
//============================================================================
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch our new, all-in-one validation provider
    // This is the key change: it watches `authValidationProvider` now.
    final authValidationState = ref.watch(authValidationProvider);

    return authValidationState.when(
      data: (user) {
        // The provider has already done all the checks.
        // If user is not null here, they are fully validated.
        if (user != null) {
          // User is fully authenticated and has a Firestore document
          return const LoadingGate(); // Proceed to the app
        } else {
          // User is signed out, or their account was invalid/orphaned
          return const LoginScreen(); // Show login screen
        }
      },
      loading: () => const SplashScreen(), // Show splash while validation happens
      error: (err, stack) => Scaffold(
        // Handle any unexpected errors from the stream itself
        body: Center(child: Text("Authentication Error: $err")),
      ),
    );
  }
}