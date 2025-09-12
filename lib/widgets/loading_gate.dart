// lib/widgets/loading_gate.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/pages/main_app_screen.dart';
import 'package:sales_app_mvp/providers/app_data_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

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
        return const MainAppScreen();
      case InitializationStatus.uninitialized:
      case InitializationStatus.loading:
        return _buildLoadingScreen(appDataState);
      case InitializationStatus.error:
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
      // CHANGE 1: Wrapped the body in a LayoutBuilder and SingleChildScrollView
      // This prevents content from overflowing on small screens.
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight( // Ensures the Column tries to be as tall as its parent
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3), // Pushes content down from the top

                      // CHANGE 2: Ad placeholder is now wrapped in Flexible
                      // This allows it to shrink if needed.
                      Flexible(
                        flex: 5, // Gives it proportional space
                        child: ConstrainedBox(
                          // It can be UP TO 250px tall, but can be smaller.
                          constraints: const BoxConstraints(
                            maxHeight: 250,
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
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
                        ),
                      ),

                      const Spacer(flex: 2), // Space between ad and loading info

                      // This section is now the focal point
                      Icon(
                        hasError ? Icons.error_outline : Icons.shopping_cart_checkout,
                        size: 60,
                        color: iconColor,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          state.loadingMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60.0),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: state.loadingProgress ?? 0.0),
                          duration: const Duration(milliseconds: 300),
                          builder: (context, value, child) {
                            return LinearProgressIndicator(
                              value: value,
                              minHeight: 8.0,
                              backgroundColor: progressBackgroundColor,
                              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                              borderRadius: BorderRadius.circular(10),
                            );
                          },
                        ),
                      ),

                      const Spacer(flex: 4), // More space at the bottom to push everything up
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}