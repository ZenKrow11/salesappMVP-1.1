
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

  // THIS IS THE KEY: Initialize Hive for Flutter.
  // This must be done before runApp and before any Hive-dependent provider is read.
  await Hive.initFlutter();

  // Now that all essential services are ready, run the app.
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

//============================================================================
//  ROOT WIDGET - UNCHANGED
//============================================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Your MaterialApp setup is correct and does not need to change.
    return MaterialApp(
      title: 'Sales App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (context) => const SplashScreen(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        MainAppScreen.routeName: (context) => const MainAppScreen(),
        AuthGate.routeName: (context) => const AuthGate(),
      },
    );
  }
}

//============================================================================
//  AUTH STATE PROVIDER & AUTH GATE - UNCHANGED
//============================================================================
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});
  static const routeName = '/auth-gate';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const MainAppScreen();
        } else {
          return const LoginScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text("Auth Error: $err")),
      ),
    );
  }
}
