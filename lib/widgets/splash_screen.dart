// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import '../main.dart'; // For AuthGate
import '../providers/storage_providers.dart'; // For hiveInitializationProvider

/// A stream provider that tells us the current user's auth state.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// This provider now only waits for services that are TRULY essential
/// for the app to function at all (like Hive).
final coreServicesReadyProvider = FutureProvider<void>((ref) async {
  await ref.watch(hiveInitializationProvider.future);
});


class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We now watch the core services provider.
    final coreServices = ref.watch(coreServicesReadyProvider);

    // When the core services are ready, navigate to the AuthGate.
    // AuthGate will then decide whether to show HomeScreen or LoginScreen.
    coreServices.when(
      data: (_) {
        // Use addPostFrameCallback to avoid "setState during build" errors.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthGate()),
          );
        });
      },
      loading: () {
        // While loading, we show the splash UI. This part is unchanged.
      },
      error: (err, stack) {
        // If core services fail (e.g., Hive can't initialize), show an error.
        // This is a critical failure, so the app can't proceed.
        return Center(
          child: Text("Critical Error: $err"),
        );
      },
    );

    // This is the UI that is displayed while coreServicesReadyProvider is running.
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Initializing..."),
          ],
        ),
      ),
    );
  }
}