// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../main.dart'; // For AuthGate
import '../providers/storage_providers.dart'; // For hiveInitializationProvider
import '../providers/products_provider.dart'; // IMPORTANT: You must import your products provider
import '../widgets/theme_color.dart'; // For your app's colors

/// A stream provider that tells us the current user's auth state. (Unchanged)
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// --- NEW PROVIDER 1: Initial Data Loader ---
/// This provider is responsible for fetching the first batch of essential data.
/// The splash screen will wait for this to complete.
///
/// **ACTION REQUIRED:** Replace the placeholder logic with your actual data fetching
/// from Firestore, likely by watching your existing `productsProvider`.
final initialDataReadyProvider = FutureProvider<void>((ref) async {
  // This will trigger the initial fetch of your products and wait for it.
  // If the fetch fails, this provider will enter an error state,
  // which can be handled on the splash screen.
  await ref.watch(allProductsProvider.future);
});


// --- NEW PROVIDER 2: The "App Ready" Coordinator ---
/// This master provider coordinates all essential startup tasks.
/// It waits for both core services (like Hive) and initial data to be ready.
/// The splash screen will only disappear when this provider has successfully completed.
final appReadyProvider = FutureProvider<void>((ref) async {
  // Wait for all futures in the list to complete.
  await Future.wait([
    ref.watch(hiveInitializationProvider.future), // Waits for Hive
    ref.watch(initialDataReadyProvider.future),  // Waits for initial products
  ]);
});


class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We now watch our new master provider.
    final appReady = ref.watch(appReadyProvider);

    // When all tasks are complete, navigate to the AuthGate.
    appReady.when(
      data: (_) {
        // Use addPostFrameCallback to schedule navigation for after the build phase.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthGate()),
          );
        });
      },
      // The error state will catch failures from ANY of the startup tasks.
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Failed to initialize the app. Please restart.\n\nError: $err",
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      loading: () {
        // While loading, the UI below is shown.
      },
    );

    // --- NEW AESTHETIC ---
    // This is the UI that is displayed while appReadyProvider is in its loading state.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // A large, themed icon for branding.
            const Icon(
              Icons.shopping_cart_checkout,
              size: 80,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading Deals...',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.inactive,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            // A clean, themed progress indicator.
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}