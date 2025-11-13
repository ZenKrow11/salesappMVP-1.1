// lib/components/ad_placeholder_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/services/ad_manager.dart';
import 'package:visibility_detector/visibility_detector.dart';

// --- This widget is now simplified for a single purpose: lazy-loading standard banners ---
class AdPlaceholderWidget extends ConsumerStatefulWidget {
  // No longer needs an AdType, as it only handles one type now.
  const AdPlaceholderWidget({super.key});

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
    if (_isAdLoadInitiated || !mounted) {
      return;
    }
    _isAdLoadInitiated = true;

    final adManager = ref.read(adManagerProvider.notifier);

    // --- THIS IS THE FIX ---
    // We call the simplified createBannerAd method. It has no parameters
    // other than the listener, because it's hardcoded to create a standard banner.
    _bannerAd = adManager.createBannerAd(
      BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Lazy-loaded BannerAd loaded successfully.');
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Lazy-loaded BannerAd failed to load: $error. Attempt #${_retryAttempt + 1}');
          ad.dispose();
          if (_retryAttempt < 3) {
            _retryAttempt++;
            Future.delayed(const Duration(seconds: 30), () {
              if (mounted) {
                _isAdLoadInitiated = false;
                _loadAd();
              }
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    if (isPremium || (_bannerAd == null && _retryAttempt >= 3)) {
      return const SizedBox.shrink();
    }

    return VisibilityDetector(
      key: Key('ad_placeholder_${widget.key}'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0 && !_isAdLoaded && !_isAdLoadInitiated) {
          _loadAd();
        }
      },
      child: _isAdLoaded && _bannerAd != null
          ? Container(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 8.0), // Margin is suitable for home page
        child: AdWidget(ad: _bannerAd!),
      )
          : Container(
        // The placeholder size is now always a standard banner.
        width: AdSize.banner.width.toDouble(),
        height: AdSize.banner.height.toDouble(),
        color: Theme.of(context).colorScheme.surface.withAlpha((255 * 0.1).round()),
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: const Text('Ad Loading...'),
      ),
    );
  }
}