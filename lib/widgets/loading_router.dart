// lib/widgets/loading_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/pages/main_app_screen.dart';
import 'package:sales_app_mvp/providers/app_data_provider.dart';
import 'package:sales_app_mvp/services/ad_manager.dart'; // <-- Import AdManager
import 'package:sales_app_mvp/widgets/fast_loading_screen.dart';
import 'package:sales_app_mvp/widgets/loading_gate.dart';

class LoadingRouter extends ConsumerWidget {
  const LoadingRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AppDataState>(appDataProvider, (previous, next) {
      if (next.status == InitializationStatus.loaded) {
        // --- THIS IS THE FIX for the dispose error ---
        // Before we navigate away, we safely tell the AdManager to clean up
        // the ad that was used during the loading phase.
        ref.read(adManagerProvider.notifier).disposeAd(AdPlacement.splashScreen);

        Future.delayed(const Duration(milliseconds: 50), () {
          if (context.mounted) {
            Navigator.of(context).pushReplacementNamed(MainAppScreen.routeName);
          }
        });
      }
    });

    final appDataState = ref.watch(appDataProvider);

    switch (appDataState.loadingType) {
      case LoadingType.fromNetwork:
        return const LoadingGate();
      case LoadingType.fromCache:
        return const FastLoadingScreen();
      case LoadingType.unknown:
      return const FastLoadingScreen();
    }
  }
}