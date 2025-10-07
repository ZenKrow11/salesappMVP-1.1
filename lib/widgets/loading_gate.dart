// lib/widgets/loading_gate.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. IMPORT THE GENERATED LOCALIZATIONS FILE
import 'package:sales_app_mvp/generated/app_localizations.dart';

import 'package:sales_app_mvp/pages/main_app_screen.dart';
import 'package:sales_app_mvp/providers/app_data_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

// 2. ADD THE TRANSLATION HELPER FUNCTION
/// A helper function to translate the loading message key from the state.
String _getTranslatedMessage(String key, AppLocalizations l10n) {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appDataProvider.notifier).initialize();
    });
  }

  // 3. LISTEN TO NAVIGATE AWAY (REMOVED FROM BUILD METHOD)
  @override
  Widget build(BuildContext context) {
    ref.listen<AppDataState>(appDataProvider, (previous, next) {
      if (next.status == InitializationStatus.loaded) {
        // Use pushReplacementNamed to prevent the user from navigating back to the loading screen.
        Navigator.of(context).pushReplacementNamed(MainAppScreen.routeName);
      }
    });

    final appDataState = ref.watch(appDataProvider);

    // This logic is cleaner than returning MainAppScreen directly from here.
    return _buildLoadingScreen(appDataState, hasError: appDataState.status == InitializationStatus.error);
  }

  Widget _buildLoadingScreen(AppDataState state, {bool hasError = false}) {
    final theme = ref.watch(themeProvider);
    // 4. GET THE LOCALIZATIONS OBJECT
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
                                // 5. LOCALIZE THE AD PLACEHOLDER TEXT
                                l10n.adPlaceholder,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: theme.inactive, fontSize: 18),
                              ),
                            ),
                          ),
                        ),
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
                          // 6. TRANSLATE THE KEY FROM THE STATE
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