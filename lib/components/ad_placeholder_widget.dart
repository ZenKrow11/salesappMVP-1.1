// lib/components/ad_placeholder_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/services/ad_manager.dart';
import 'package:visibility_detector/visibility_detector.dart';

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
  bool _isAdLoadInitiated = false;
  int _retryAttempt = 0;

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadAd() {
    // Prevent multiple load attempts
    if (_isAdLoadInitiated) {
      return;
    }
    _isAdLoadInitiated = true;

    final adManager = ref.read(adManagerProvider.notifier);

    _bannerAd = adManager.createBannerAd(
      BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('BannerAd loaded successfully.');
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error. Attempt #${_retryAttempt + 1}');
          ad.dispose();

          // Don't retry forever. Let's try 3 times.
          if (_retryAttempt < 3) {
            _retryAttempt++;
            // Wait for 30 seconds before trying again.
            Future.delayed(const Duration(seconds: 30), () {
              if (mounted) {
                // Reset the flag to allow a new load attempt
                _isAdLoadInitiated = false;
                _loadAd();
              }
            });
          }
        },
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    // Hide ad for premium users or if it failed to load permanently
    if (isPremium || (_bannerAd == null && _retryAttempt >= 3)) {
      return const SizedBox.shrink();
    }

    return VisibilityDetector(
      key: Key('ad_placeholder_${widget.key}'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0 && !_isAdLoaded) {
          _loadAd();
        }
      },
      child: _isAdLoaded && _bannerAd != null
          ? Container(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: AdWidget(ad: _bannerAd!),
      )
          : Container(
        width: double.infinity,
        height: 50, // Standard banner height
        color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: const Text('Ad Loading...'), // Good for debugging
      ),
    );
  }
}