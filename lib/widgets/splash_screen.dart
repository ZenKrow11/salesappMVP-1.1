// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../main.dart'; // For AuthGate
import '../providers/storage_providers.dart'; // For hiveInitializationProvider
import '../providers/products_provider.dart'; // For allProductsProvider
import '../widgets/theme_color.dart'; // For your app's colors

/// A stream provider that tells us the current user's auth state.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// --- REMOVED: initialDataReadyProvider is no longer needed. ---
// The logic is now handled directly by appReadyProvider.

// --- SIMPLIFIED: The "App Ready" Coordinator ---
/// This master provider coordinates all essential startup tasks.
/// It waits for both core services (like Hive) and the initial product data fetch to complete.
final appReadyProvider = FutureProvider<void>((ref) async {
  // Wait for all futures in the list to complete.
  await Future.wait([
    ref.watch(hiveInitializationProvider.future), // Waits for Hive to be set up.

    // --- THIS IS THE FIX ---
    // We wait for the FETCH action to complete, not the synchronous data provider.
    ref.watch(productFetchProvider.future),
  ]);
});


class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The rest of the widget is exactly the same and works perfectly.
    final appReady = ref.watch(appReadyProvider);

    appReady.when(
      data: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthGate()),
          );
        });
      },
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
      loading: () {}, // UI is shown below, so this can be empty.
    );

    // This UI remains unchanged.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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