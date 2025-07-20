// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

import '../main.dart';
import '../providers/storage_providers.dart';
// UPDATED import
import '../providers/products_provider.dart';
import '../providers/grouped_products_provider.dart';
import '../widgets/theme_color.dart';

// StartupState class and StartupNotifier can remain mostly the same,
// but we'll update the _initialize method.

@immutable
class StartupState {
  const StartupState({required this.progress, required this.message});
  final double progress;
  final String message;
}

class StartupNotifier extends StateNotifier<StartupState> {
  StartupNotifier(this._ref)
      : super(const StartupState(progress: 0.0, message: 'Initializing...')) {
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
      await Future.delayed(const Duration(milliseconds: 15));
    }
    state = StartupState(progress: target, message: message);
  }

  // THE CORRECTED INITIALIZE METHOD
  Future<void> _initialize() async {
    // Step 1: Initialize Hive (0% -> 20%)
    await _animateProgress(0.20, 'Preparing local storage...');
    await _ref.read(hiveInitializationProvider.future);

    // Step 2: Fetch products using the new stable provider (20% -> 50%)
    // This now handles both cache-first and initial-sync scenarios.
    await _animateProgress(0.50, 'Loading latest deals...');
    await _ref.read(initialProductsProvider.future);

    // Step 3: Pre-process the homepage view (50% -> 90%)
    await _animateProgress(0.90, 'Getting things ready...');
    await _ref.read(homePageProductsProvider.future);

    // Step 4: Finalize (90% -> 100%)
    await _animateProgress(1.0, 'All set!');
    await Future.delayed(const Duration(milliseconds: 250));
  }
}

final startupProvider =
StateNotifierProvider<StartupNotifier, StartupState>((ref) {
  return StartupNotifier(ref);
});

// The SplashScreen widget itself does not need any changes.
class SplashScreen extends ConsumerWidget {
  static const routeName = '/';
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startupState = ref.watch(startupProvider);
    ref.listen(startupProvider, (previous, next) {
      if (next.progress == 1.0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.of(context).pushReplacementNamed(AuthGate.routeName);
          }
        });
      }
    });
    return Scaffold( /* ... Your existing splash screen UI ... */
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_checkout, size: 80, color: AppColors.secondary),
            const SizedBox(height: 24),
            Text(startupState.message, style: const TextStyle(fontSize: 18, color: AppColors.inactive, fontWeight: FontWeight.w600)),
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