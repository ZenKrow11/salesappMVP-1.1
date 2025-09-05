// lib/widgets/splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sales_app_mvp/main.dart';
import 'package:sales_app_mvp/providers/app_data_provider.dart';
import 'package:sales_app_mvp/providers/storage_providers.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';


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
    const animationDuration = Duration(milliseconds: 300);
    const stepInterval = Duration(milliseconds: 15);
    final steps = (animationDuration.inMilliseconds /
        stepInterval.inMilliseconds).round();
    final progressIncrement = (target - currentProgress) / steps;

    for (int i = 1; i <= steps; i++) {
      state = StartupState(
          progress: currentProgress + (progressIncrement * i),
          message: message);
      await Future.delayed(stepInterval);
    }
    state = StartupState(progress: target, message: message);
  }

  // --- THIS IS THE NEW, ROBUST INITIALIZATION METHOD ---
  Future<void> _initialize() async {
    try {
      // Step 1: Prepare local storage.
      await _animateProgress(0.25, 'Preparing local storage...');
      await _ref.read(hiveInitializationProvider.future);

      // Step 2: Wait for a valid user session.
      await _animateProgress(0.5, 'Verifying session...');
      await _ref.read(authStateChangesProvider.future);

      final user = _ref.read(authStateChangesProvider).value;
      if (user == null) {
        await _animateProgress(1.0, 'Redirecting...');
        await Future.delayed(const Duration(milliseconds: 250));
        return; // Exit early if no user is signed in
      }

      // Step 3: NOW that we have a user, initialize the app data.
      await _animateProgress(0.75, 'Loading latest deals...');
      await _ref.read(appDataProvider.notifier).initialize();

      final appDataState = _ref.read(appDataProvider);
      if (appDataState.status == InitializationStatus.error) {
        throw Exception("Failed to initialize application data.");
      }

      // Step 4: Finalize and navigate.
      await _animateProgress(1.0, 'All set!');
      await Future.delayed(const Duration(milliseconds: 250));

    } catch (e, stack) {
      debugPrint("Startup Error: $e\n$stack");
      state =
          StartupState(progress: 1.0, message: 'Error: Could not load data.');
    }
  }
}

// --- FIX: This code was moved OUTSIDE of the StartupNotifier class ---
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

    final bool hasError = startupState.message.startsWith('Error:');
    final Color iconColor = hasError ? Colors.red : theme.secondary;
    final Color textColor = hasError ? Colors.red : theme.inactive;
    final Color progressColor = hasError ? Colors.red : theme.secondary;
    final Color progressBackgroundColor =
    hasError ? Colors.red.withOpacity(0.3) : theme.primary;

    ref.listen(startupProvider, (previous, next) {
      // We navigate if the process completes, regardless of whether there was a user.
      // The AuthGate will handle the redirection to login or home.
      if (next.progress == 1.0 && !hasError) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
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
            Icon(
              hasError ? Icons.error_outline : Icons.shopping_cart_checkout,
              size: 80,
              color: iconColor,
            ),
            const SizedBox(height: 24),
            Text(startupState.message,
                style: TextStyle(
                    fontSize: 18,
                    color: textColor,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80.0),
              child: LinearProgressIndicator(
                value: startupState.progress,
                minHeight: 8.0,
                backgroundColor: progressBackgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}