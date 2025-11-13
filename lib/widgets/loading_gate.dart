// lib/widgets/loading_gate.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide InitializationStatus;

import 'package:sales_app_mvp/components/preloaded_ad_widget.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/providers/app_data_provider.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/services/ad_manager.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

// This helper function remains the same.
String _getTranslatedMessage(AppDataState state, AppLocalizations l10n) {
  // If progress is 0, we are in the initial "splash" state.
  if (state.loadingProgress == 0.0 && state.status != InitializationStatus.error) {
    return l10n.initializing;
  }

  switch (state.loadingMessage) {
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
        // Only preload the ad if we anticipate a network load.
        if (!isPremium && ref.read(appDataProvider).loadingType == LoadingType.fromNetwork) {
          ref.read(adManagerProvider.notifier).preloadBannerAd(AdPlacement.splashScreen, AdSize.banner);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appDataState = ref.watch(appDataProvider);
    final theme = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context)!;

    final hasError = appDataState.status == InitializationStatus.error;
    final isIndeterminate = appDataState.loadingProgress == 0.0 && !hasError;

    // --- SMART ANIMATION DURATION ---
    // Use a quick, satisfying animation for fast cache loads.
    // Use a smoother, shorter animation for each step of a network load.
    final animationDuration = appDataState.loadingType == LoadingType.fromCache
        ? const Duration(milliseconds: 400)
        : const Duration(milliseconds: 300);

    final Color iconColor = hasError ? Colors.red : theme.secondary;
    final Color textColor = hasError ? Colors.red : theme.inactive;
    final Color progressColor = hasError ? Colors.red : theme.secondary;
    final Color progressBackgroundColor =
        hasError ? Colors.red.withAlpha((255 * 0.3).round()) : theme.primary;

    return Scaffold(
      backgroundColor: theme.pageBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            // --- SMART AD DISPLAY ---
            // Only show the ad banner for non-premium users during a network load.
            Flexible(
              flex: 5,
              child: (ref.watch(isPremiumProvider) || appDataState.loadingType != LoadingType.fromNetwork)
                  ? const SizedBox(height: 50) // Reserve space to prevent layout jumps
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
                _getTranslatedMessage(appDataState, l10n),
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
              // --- SMART PROGRESS INDICATOR ---
              child: isIndeterminate
                  ? LinearProgressIndicator(
                backgroundColor: progressBackgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              )
                  : TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: appDataState.loadingProgress),
                duration: animationDuration,
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
    );
  }
}