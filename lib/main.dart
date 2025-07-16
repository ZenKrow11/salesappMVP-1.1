import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

// Import your other files
import 'firebase_options.dart';
import 'widgets/splash_screen.dart'; // Assumes this is the correct path
import 'widgets/login_screen.dart';   // Assumes this is the correct path
import 'pages/main_app_screen.dart';  // Assumes this is the correct path

//============================================================================
//  MAIN FUNCTION - The App's Entry Point (No changes needed here)
//============================================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_DE', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Hive.initFlutter();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

//============================================================================
//  ROOT WIDGET - REFACTORED
//============================================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // You can define your app-wide theme here
      ),
      debugShowCheckedModeBanner: false,

      // 1. Define the screen the app starts on using its route name.
      initialRoute: SplashScreen.routeName,

      // 2. Define all the app's top-level screens in the routes table.
      // This is the fix for your "Could not find a generator for route" error.
      routes: {
        SplashScreen.routeName: (context) => const SplashScreen(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        MainAppScreen.routeName: (context) => const MainAppScreen(),
        // We also give the AuthGate a route name so the SplashScreen can navigate to it.
        AuthGate.routeName: (context) => const AuthGate(),
      },
    );
  }
}

//============================================================================
//  AUTH STATE PROVIDER & AUTH GATE (Minor change to add routeName)
//============================================================================

/// A stream provider that tells us the current user's auth state.
/// This is the single source of truth for authentication in the app.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// This widget listens to the auth state and decides which screen to show.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  // A routeName for navigating to this widget.
  static const routeName = '/auth-gate';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    // This logic is excellent and doesn't need to change.
    // It correctly returns a widget based on the auth state.
    return authState.when(
      data: (user) {
        if (user != null) {
          // User is logged in, show the main app screen.
          return const MainAppScreen();
        } else {
          // User is logged out, show the login screen.
          return const LoginScreen();
        }
      },
      // These loading and error states are good fallbacks.
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text("Auth Error: $err")),
      ),
    );
  }
}