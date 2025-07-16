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

// --- NEW: Step 1 - Define a state class for our startup progress ---
@immutable
class StartupState {
  const StartupState({required this.progress, required this.message});

  final double progress;
  final String message;
}

// --- NEW: Step 2 - Create a StateNotifier to manage the startup process ---
class StartupNotifier extends StateNotifier<StartupState> {
  StartupNotifier(this._ref) : super(const StartupState(progress: 0.0, message: 'Initializing...')) {
    _initialize();
  }

  final Ref _ref;

  // This method runs the startup tasks sequentially and updates the state.
  Future<void> _initialize() async {
    // Task 1: Initialize Hive (Let's say this is 50% of the work)
    state = const StartupState(progress: 0.0, message: 'Preparing local storage...');
    await _ref.read(hiveInitializationProvider.future);
    state = const StartupState(progress: 0.5, message: 'Loading latest deals...');

    // Task 2: Fetch products (The other 50%)
    await _ref.read(productFetchProvider.future);
    state = const StartupState(progress: 1.0, message: 'All set!');

    // A small delay to allow the user to see the "All set!" message.
    await Future.delayed(const Duration(milliseconds: 300));
  }
}

/// The provider that the UI will watch to get progress updates.
final startupProvider = StateNotifierProvider<StartupNotifier, StartupState>((ref) {
  return StartupNotifier(ref);
});

// --- DEPRECATED: The old appReadyProvider is no longer needed. ---
// final appReadyProvider = FutureProvider<void>((ref) async { ... });


class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- MODIFIED: Watch our new startupProvider instead of the old one ---
    final startupState = ref.watch(startupProvider);

    // Navigate when initialization is complete (progress is 1.0)
    ref.listen(startupProvider, (previous, next) {
      if (next.progress == 1.0) {
        // Use addPostFrameCallback to ensure the build method is complete.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthGate()),
          );
        });
      }
    });

    // We don't need the .when() handler anymore as the UI is always visible
    // and updates based on the startupState.

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
            Text(
              // --- MODIFIED: Show the dynamic message from our state ---
              startupState.message,
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.inactive,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              // --- REPLACED: Use a LinearProgressIndicator ---
              child: LinearProgressIndicator(
                // The value comes directly from our startup state
                value: startupState.progress,
                backgroundColor: AppColors.inactive.withValues(alpha: 10.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}