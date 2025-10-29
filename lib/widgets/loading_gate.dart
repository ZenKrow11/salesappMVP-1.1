// lib/widgets/loading_gate.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// --- THIS IS THE FIX ---
// We import the google_mobile_ads package but explicitly hide the conflicting
// InitializationStatus enum, as we want to use our own from app_data_provider.
import 'package:google_mobile_ads/google_mobile_ads.dart' hide InitializationStatus;

import 'package:sales_app_mvp/components/preloaded_ad_widget.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/providers/app_data_provider.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/services/ad_manager.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';


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
      if (mounted) {
        final isPremium = ref.read(isPremiumProvider);
        if (!isPremium) {
          ref.read(adManagerProvider.notifier).preloadBannerAd(AdPlacement.splashScreen, AdSize.banner);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appDataState = ref.watch(appDataProvider);
    // Now that the ambiguity is resolved, this line will work correctly.
    final hasError = appDataState.status == InitializationStatus.error;

    return _buildLoadingScreen(appDataState, hasError: hasError);
  }

  Widget _buildLoadingScreen(AppDataState state, {bool hasError = false}) {
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
                      Flexible(
                        flex: 5,
                        child: ref.watch(isPremiumProvider)
                            ? const SizedBox.shrink()
                            : const PreloadedAdWidget(
                          placement: AdPlacement.splashScreen,
                          adSize: AdSize.banner,
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