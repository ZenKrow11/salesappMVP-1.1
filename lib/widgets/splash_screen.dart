// lib/widgets/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

import 'package:sales_app_mvp/pages/main_app_screen.dart'; // IMPORTANT: Import the correct screen
import 'package:sales_app_mvp/providers/storage_providers.dart';
import 'package:sales_app_mvp/models/products_provider.dart';
import 'package:sales_app_mvp/providers/grouped_products_provider.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

// StartupState class remains unchanged.
@immutable
class StartupState {
  const StartupState({required this.progress, required this.message});
  final double progress;
  final String message;
}

// StartupNotifier remains unchanged. Its logic is correct.
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

  Future<void> _initialize() async {
    // Note: The hiveInitializationProvider is already complete because we awaited it in main().
    // This will resolve instantly.
    await _animateProgress(0.20, 'Preparing local storage...');
    await _ref.read(hiveInitializationProvider.future);

    await _animateProgress(0.50, 'Loading latest deals...');
    await _ref.read(initialProductsProvider.future);

    await _animateProgress(0.90, 'Getting things ready...');
    await _ref.read(homePageProductsProvider.future);

    await _animateProgress(1.0, 'All set!');
    await Future.delayed(const Duration(milliseconds: 250));
  }
}

final startupProvider =
StateNotifierProvider<StartupNotifier, StartupState>((ref) {
  return StartupNotifier(ref);
});

// The SplashScreen widget with the corrected navigation.
class SplashScreen extends ConsumerWidget {
  static const routeName = '/';
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startupState = ref.watch(startupProvider);

    // This listener waits for the startup process to complete.
    ref.listen(startupProvider, (previous, next) {
      if (next.progress == 1.0) {
        // When progress is 100%, navigate to the main app screen.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            // THE FIX: Navigate to MainAppScreen using its routeName.
            // We use pushReplacementNamed so the user cannot press "back" to get to the splash screen.
            Navigator.of(context).pushReplacementNamed(MainAppScreen.routeName);
          }
        });
      }
    });

    // The UI of the splash screen remains the same.
    return Scaffold(
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