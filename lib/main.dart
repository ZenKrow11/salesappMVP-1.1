import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Your other imports
import 'firebase_options.dart'; // Make sure you have this file from FlutterFire CLI
import 'widgets/splash_screen.dart'; // We start with the splash screen

Future<void> main() async {
  // Ensure Flutter engine is ready
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive's file system path. This is fast and required.
  // We no longer open boxes here; Riverpod will handle that.
  await Hive.initFlutter();

  // NOTE: You no longer need to call a custom HiveService.init() here.

  runApp(
    // ProviderScope is what makes Riverpod work throughout your app
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

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

// NOTE: I'm assuming you have an AuthGate widget. It remains unchanged.
// For context, it might look something like this:
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    // This would listen to your Firebase Auth state and show either
    // the HomeScreen or the LoginScreen. This logic is unchanged.
    return const Scaffold(body: Center(child: Text("Main App Area")));
  }
}