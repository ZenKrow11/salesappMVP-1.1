// lib/widgets/loading_gate.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/pages/main_app_screen.dart';
import 'package:sales_app_mvp/providers/app_data_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/components/ad_placeholder_widget.dart';

// ... (the _getTranslatedMessage function remains unchanged) ...
String _getTranslatedMessage(String key, AppLocalizations l10n) {
  // ... same as before ...
  switch (key) {
    case 'loadingInitializing':
      return l10n.loadingInitializing;
    case 'loadingPreparingStorage':
      return l10n.loadingPreparingStorage;
    case 'loadingCheckingUpdates':
      return l10n.loadingCheckingUpdates;
    case 'loadingDownloadingDeals':
      return l10n.loadingDownloadingDeals;
    case 'loadingFromCache':
      return l10n.loadingFromCache;
    case 'loadingAllSet':
      return l10n.loadingAllSet;
    case 'errorCouldNotLoadData':
      return l10n.errorCouldNotLoadData;
    default:
      return l10n.loadingInitializing; // Fallback
  }
}


class LoadingGate extends ConsumerStatefulWidget {
  const LoadingGate({super.key});

  @override
  ConsumerState<LoadingGate> createState() => _LoadingGateState();
}

class _LoadingGateState extends ConsumerState<LoadingGate> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure the widget is built before starting.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if we are still mounted before triggering initialization.
      if (mounted) {
        ref.read(appDataProvider.notifier).initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- THIS IS THE FIX ---
    ref.listen<AppDataState>(appDataProvider, (previous, next) {
      if (next.status == InitializationStatus.loaded) {
        // Use Future.delayed to schedule navigation for after the current build cycle.
        // This prevents race conditions with other widgets (like ads) that might be
        // finishing their work during this same frame.
        Future.delayed(Duration.zero, () {
          if (mounted) { // Always check if the widget is still in the tree
            Navigator.of(context)
                .pushReplacementNamed(MainAppScreen.routeName);
          }
        });
      }
    });

    final appDataState = ref.watch(appDataProvider);
    final hasError = appDataState.status == InitializationStatus.error;

    return _buildLoadingScreen(appDataState, hasError: hasError);
  }

  // The _buildLoadingScreen method remains completely unchanged.
  Widget _buildLoadingScreen(AppDataState state, {bool hasError = false}) {
    // ... same as before ...
    final theme = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context)!;
    final Color iconColor = hasError ? Colors.red : theme.secondary;
    final Color textColor = hasError ? Colors.red : theme.inactive;
    final Color progressColor = hasError ? Colors.red : theme.secondary;
    final Color progressBackgroundColor =
    hasError ? Colors.red.withOpacity(0.3) : theme.primary;

    return Scaffold(
      backgroundColor: theme.pageBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),
                      const Flexible(
                        flex: 5,
                        child: AdPlaceholderWidget(adType: AdType.banner),
                      ),
                      const Spacer(flex: 2),
                      Icon(
                        hasError ? Icons.error_outline : Icons.shopping_cart_checkout,
                        size: 60,
                        color: iconColor,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          _getTranslatedMessage(state.loadingMessage, l10n),
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
                          tween: Tween(begin: 0.0, end: state.loadingProgress),
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
                      const Spacer(flex: 4),
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