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
      // Decide which loading screen to show based on the loading type.
        if (appDataState.loadingType == LoadingType.fromNetwork) {
          return _buildNetworkLoadingScreen(appDataState);
        } else {
          // Default to the simpler cache/spinner screen.
          return _buildCacheLoadingScreen(appDataState);
        }

      case InitializationStatus.error:
      // Always show the simple error screen for any errors.
        return _buildCacheLoadingScreen(appDataState, hasError: true);
    }
  }

  /// Builds the detailed loading screen for downloading from the network.
  Widget _buildNetworkLoadingScreen(AppDataState state) {
    final theme = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: theme.pageBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            Flexible(
              flex: 5,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
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
            const Spacer(flex: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                state.loadingMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: theme.inactive,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60.0),
              // We remove the TweenAnimationBuilder to show the real progress directly.
              child: LinearProgressIndicator(
                value: state.loadingProgress,
                minHeight: 8.0,
                backgroundColor: theme.primary,
                valueColor: AlwaysStoppedAnimation<Color>(theme.secondary),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Spacer(flex: 4),
          ],
        ),
      ),
    );
  }

  /// Builds the simple loading screen for loading from cache or showing errors.
  Widget _buildCacheLoadingScreen(AppDataState state, {bool hasError = false}) {
    final theme = ref.watch(themeProvider);
    final Color indicatorColor = hasError ? Colors.red : theme.secondary;
    final Color textColor = hasError ? Colors.red : theme.inactive;

    return Scaffold(
      backgroundColor: theme.pageBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 5,
                valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              state.loadingMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}