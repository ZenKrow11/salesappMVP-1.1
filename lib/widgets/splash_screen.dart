// lib/pages/splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/pages/main_app_screen.dart';
import 'package:sales_app_mvp/providers/storage_providers.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

// --- UPDATED: We only need to wait on the single source of truth provider ---
import 'package:sales_app_mvp/models/products_provider.dart';

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
    // This helper function can remain as is, it's great for UX.
    final double currentProgress = state.progress;
    const animationDuration = Duration(milliseconds: 300);
    const stepInterval = Duration(milliseconds: 15);
    final steps = (animationDuration.inMilliseconds / stepInterval.inMilliseconds).round();
    final progressIncrement = (target - currentProgress) / steps;

    for (int i = 1; i <= steps; i++) {
      state = StartupState(
          progress: currentProgress + (progressIncrement * i), message: message);
      await Future.delayed(stepInterval);
    }
    state = StartupState(progress: target, message: message);
  }

  // --- REFACTORED THIS METHOD SIGNIFICANTLY ---
  Future<void> _initialize() async {
    try {
      // Step 1: Prepare local storage.
      await _animateProgress(0.33, 'Preparing local storage...');
      await _ref.read(hiveInitializationProvider.future);

      // Step 2: Trigger and wait for the main data provider to complete.
      // 'initialProductsProvider' already contains all the logic to fetch
      // from Firebase, sync to Hive, and handle offline cases.
      // We do NOT need to call the sync service separately here.
      await _animateProgress(0.66, 'Loading latest deals...');
      await _ref.read(initialProductsProvider.future);

      // Step 3: Finalize and navigate.
      await _animateProgress(1.0, 'All set!');
      await Future.delayed(const Duration(milliseconds: 250));

    } catch (e, stack) {
      // If initialProductsProvider throws an error (e.g., no internet on first launch),
      // we now handle it gracefully on the splash screen.
      debugPrint("Startup Error: $e\n$stack");
      state = StartupState(progress: 1.0, message: 'Error: Could not load data.');
      // You could add a "Retry" button here if desired.
    }
  }
}

final startupProvider =
StateNotifierProvider<StartupNotifier, StartupState>((ref) {
  return StartupNotifier(ref);
});

class SplashScreen extends ConsumerWidget {
  static const routeName = '/';
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startupState = ref.watch(startupProvider);
    final theme = ref.watch(themeProvider);

    ref.listen(startupProvider, (previous, next) {
      // We only navigate if the progress is 1.0 AND the message is 'All set!'.
      // This prevents navigating away if there was an error.
      if (next.progress == 1.0 && next.message == 'All set!') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            // --- UPDATED: Navigate to AuthGate instead of directly to MainAppScreen ---
            // This ensures your app correctly shows the login screen if the user is logged out.
            // Your main.dart is already set up to use AuthGate, so the splash
            // screen should also respect this flow.
            Navigator.of(context).pushReplacementNamed('/auth-gate');
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: theme.pageBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_checkout, size: 80, color: theme.secondary),
            const SizedBox(height: 24),
            Text(startupState.message,
                style: TextStyle(
                    fontSize: 18,
                    color: theme.inactive,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80.0),
              child: LinearProgressIndicator(
                value: startupState.progress,
                minHeight: 8.0,
                backgroundColor: theme.primary,
                valueColor: AlwaysStoppedAnimation<Color>(theme.secondary),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}