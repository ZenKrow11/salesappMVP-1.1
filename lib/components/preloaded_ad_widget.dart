// lib/components/preloaded_ad_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sales_app_mvp/services/ad_manager.dart';

// --- FIX #2: Convert to a simple, stateless ConsumerWidget ---
class PreloadedAdWidget extends ConsumerWidget {
  final AdPlacement placement;
  final AdSize adSize;

  const PreloadedAdWidget({
    super.key,
    required this.placement,
    required this.adSize,
  });

  // --- The problematic dispose method has been completely removed. ---

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This widget's only job is to watch the state and build the UI.
    final adState = ref.watch(adManagerProvider);
    final bannerAd = adState.loadedBannerAds[placement];

    if (bannerAd != null) {
      return SizedBox(
        width: adSize.width.toDouble(),
        height: adSize.height.toDouble(),
        child: AdWidget(ad: bannerAd),
      );
    } else {
      return Container(
        width: adSize.width.toDouble(),
        height: adSize.height.toDouble(),
        color: Theme.of(context).colorScheme.surface.withAlpha(
            (255 * 0.1).round()), // Use withAlpha to avoid precision loss
        alignment: Alignment.center,
        child: const Text('Ad Loading...'),
      );
    }
  }
}
