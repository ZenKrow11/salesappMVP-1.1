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
  // Ensure Flutter engine is ready
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_DE', null);


  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive's file system path
  await Hive.initFlutter();

  // Run the app within a ProviderScope for Riverpod
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

//============================================================================
//  ROOT WIDGET
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
      // The app always starts at the SplashScreen
      home: const SplashScreen(),
    );
  }
}

//============================================================================
//  AUTH STATE PROVIDER & AUTH GATE
//============================================================================

/// A stream provider that tells us the current user's auth state.
/// This is the single source of truth for authentication in the app.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// This widget listens to the auth state and decides which screen to show.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We watch the auth state provider.
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // User is logged in, show the home page.
          return const MainAppScreen();
        } else {
          // User is logged out, show the login screen.
          return const LoginScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Text("Auth Error: $err"),
        ),
      ),
    );
  }
}