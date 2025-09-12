// lib/widgets/loading_gate.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/pages/main_app_screen.dart';
import 'package:sales_app_mvp/providers/app_data_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart'; // Import your app theme

class LoadingGate extends ConsumerStatefulWidget {
  const LoadingGate({super.key});

  @override
  ConsumerState<LoadingGate> createState() => _LoadingGateState();
}

class _LoadingGateState extends ConsumerState<LoadingGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appDataProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appDataState = ref.watch(appDataProvider);

    switch (appDataState.status) {
      case InitializationStatus.loaded:
      // Data is ready, go to the main app.
        return const MainAppScreen();

      case InitializationStatus.uninitialized:
      case InitializationStatus.loading:
      // --- THIS IS THE NEW UI FOR THE LOADING STATE ---
        return _buildLoadingScreen(appDataState);

      case InitializationStatus.error:
      // Show an error screen, but you can style it like the loading screen
        return _buildLoadingScreen(appDataState, hasError: true);
    }
  }

  /// Builds the styled loading/error screen.
  Widget _buildLoadingScreen(AppDataState state, {bool hasError = false}) {
    final theme = ref.watch(themeProvider);

    final Color iconColor = hasError ? Colors.red : theme.secondary;
    final Color textColor = hasError ? Colors.red : theme.inactive;
    final Color progressColor = hasError ? Colors.red : theme.secondary;
    final Color progressBackgroundColor =
    hasError ? Colors.red.withOpacity(0.3) : theme.primary;

    return Scaffold(
      backgroundColor: theme.pageBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            // --- 1. AD PLACEHOLDER ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              height: 250, // Standard IAB Medium Rectangle ad size
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.primary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.inactive.withOpacity(0.2)),
              ),
              child: Center(
                child: Text(
                  'Ad Placeholder\n300 x 250',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.inactive, fontSize: 18),
                ),
              ),
            ),
            const Spacer(flex: 1),
            // --- 2. TASK TITLE ---
            Icon(
              hasError ? Icons.error_outline : Icons.shopping_cart_checkout,
              size: 60,
              color: iconColor,
            ),
            const SizedBox(height: 16),
            Text(
              state.loadingMessage,
              style: TextStyle(
                fontSize: 18,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            // --- 3. LOADING BAR ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60.0),

          child: TweenAnimationBuilder<double>(
            // The tween defines the start and end values for the animation.
            // The builder will animate from its current value to the new `end` value.
            tween: Tween(begin: 0.0, end: state.loadingProgress ?? 0.0),

            // Duration of the animation between steps.
            duration: const Duration(milliseconds: 300), // Adjust for desired speed

            // The builder is called for every frame of the animation.
            builder: (context, value, child) {
              // 'value' is the animated progress value for the current frame.
              return LinearProgressIndicator(
                value: value, // Use the animated value here!
                minHeight: 8.0,
                backgroundColor: progressBackgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                borderRadius: BorderRadius.circular(10),
              );
            },
          ),
        ),
      ],
    ),
      )
    );
  }
}