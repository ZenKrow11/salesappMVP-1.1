// lib/components/ad_placeholder_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/services/ad_manager.dart';

enum AdType { banner }

class AdPlaceholderWidget extends ConsumerStatefulWidget {
  final AdType adType;
  const AdPlaceholderWidget({super.key, required this.adType});

  @override
  ConsumerState<AdPlaceholderWidget> createState() => _AdPlaceholderWidgetState();
}

class _AdPlaceholderWidgetState extends ConsumerState<AdPlaceholderWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load the ad here. This gets called when the widget is first inserted into the tree.
    if (_bannerAd == null) {
      _loadAd();
    }
  }

  void _loadAd() {
    final adManager = ref.read(adManagerProvider.notifier);

    // Ask the AdManager factory to create a new ad for this specific widget instance.
    _bannerAd = adManager.createBannerAd(
      BannerAdListener(
        onAdLoaded: (ad) {
          // Once loaded, rebuild the widget to show the ad.
          if (mounted) { // Check if the widget is still in the tree
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load for this widget: $error');
          ad.dispose();
        },
      ),
    );
  }

  @override
  void dispose() {
    // Clean up the ad when this widget is removed from the screen.
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    if (isPremium || _bannerAd == null) {
      return const SizedBox.shrink(); // Show nothing if premium or ad isn't even trying to load.
    }

    if (_isAdLoaded) {
      // If the ad is ready, show it.
      return Container(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: AdWidget(ad: _bannerAd!),
      );
    } else {
      // Otherwise, show a loading placeholder.
      return Container(
        width: double.infinity,
        height: 50, // Standard banner height
        color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
      );
    }
  }
}