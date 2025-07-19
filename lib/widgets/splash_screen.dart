// lib/screens/splash_screen.dart (or wherever this file is located)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math'; // For min() function in animation

// IMPORTANT: Make sure these paths are correct for your project structure
import '../main.dart'; // For AuthGate.routeName
import '../providers/storage_providers.dart'; // For hiveInitializationProvider
import '../providers/products_provider.dart'; // For productFetchProvider
import '../widgets/theme_color.dart'; // For your app's colors

/// A stream provider that tells us the current user's auth state.
/// This is already defined in main.dart, so you can technically remove this
/// duplicate definition if you import main.dart, but having it here doesn't hurt.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

@immutable
class StartupState {
  const StartupState({required this.progress, required this.message});

  final double progress;
  final String message;
}

class StartupNotifier extends StateNotifier<StartupState> {
  StartupNotifier(this._ref) : super(const StartupState(progress: 0.0, message: 'Initializing...')) {
    _initialize();
  }

  final Ref _ref;

  Future<void> _animateProgress(double target, String message) async {
    final double currentProgress = state.progress;
    final int steps = ((target - currentProgress).abs() * 100).round();
    if (steps == 0) return;

    for (int i = 1; i <= steps; i++) {
      final newProgress = min(currentProgress + (i * 0.01), target);
      state = StartupState(progress: newProgress, message: message);
      await Future.delayed(const Duration(milliseconds: 20));
    }
    state = StartupState(progress: target, message: message);
  }

  Future<void> _initialize() async {
    await _animateProgress(0.25, 'Preparing local storage...');
    await _ref.read(hiveInitializationProvider.future);
    await _animateProgress(0.5, 'Local storage ready.');
    await Future.delayed(const Duration(milliseconds: 400));
    await _animateProgress(0.75, 'Loading latest deals...');
    // Make sure 'productFetchProvider' exists in your products_provider.dart file
    await _ref.read(productsProvider.future);
    await _animateProgress(1.0, 'All set!');
    await Future.delayed(const Duration(milliseconds: 250));
  }
}

final startupProvider = StateNotifierProvider<StartupNotifier, StartupState>((ref) {
  return StartupNotifier(ref);
});

//============================================================================
//  SPLASH SCREEN WIDGET - REFACTORED
//============================================================================
class SplashScreen extends ConsumerWidget {
  // 1. ADD THE STATIC ROUTENAME. Your MaterialApp will use this.
  static const routeName = '/';

  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startupState = ref.watch(startupProvider);

    // 2. THIS IS THE ONLY CHANGE NEEDED.
    // We listen for the progress to complete and then navigate using the named route.
    ref.listen(startupProvider, (previous, next) {
      if (next.progress == 1.0) {
        // Use a post-frame callback to ensure the build method is complete
        // before we try to navigate away.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Check if the widget is still mounted (in the widget tree)
          if (context.mounted) {
            // THE REFACTORED LINE:
            // Instead of building a MaterialPageRoute, we use the named route
            // for the AuthGate that we defined in main.dart.
            Navigator.of(context).pushReplacementNamed(AuthGate.routeName);
          }
        });
      }
    });

    // The UI of your splash screen does not need any changes. It's already great.
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
              startupState.message,
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.inactive,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80.0),
              child: LinearProgressIndicator(
                value: startupState.progress,
                minHeight: 8.0,
                backgroundColor: AppColors.primary,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}