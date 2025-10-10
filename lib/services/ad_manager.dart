// lib/services/ad_manager.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// --- Ad Unit IDs (Unchanged) ---
final String bannerAdUnitId = defaultTargetPlatform == TargetPlatform.android
    ? 'ca-app-pub-3940256099942544/6300978111'
    : 'ca-app-pub-3940256099942544/2934735716';

final String interstitialAdUnitId = defaultTargetPlatform == TargetPlatform.android
    ? 'ca-app-pub-3940256099942544/1033173712'
    : 'ca-app-pub-3940256099942544/4411468910';

final adManagerProvider = StateNotifierProvider<AdManager, AdState>((ref) {
  final adManager = AdManager();
  ref.onDispose(() => adManager.disposeAds());
  return adManager;
});

/// Holds the state of our loaded ads that are managed centrally (like interstitials).
class AdState {
  // NOTE: The BannerAd is no longer here.
  final InterstitialAd? interstitialAd;

  AdState({this.interstitialAd});

  AdState copyWith({InterstitialAd? interstitialAd}) {
    return AdState(
      interstitialAd: interstitialAd ?? this.interstitialAd,
    );
  }
}

class AdManager extends StateNotifier<AdState> {
  AdManager() : super(AdState());

  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;
    MobileAds.instance.initialize();
    _isInitialized = true;
  }

  // --- THIS IS THE CORRECT METHOD ---
  /// Creates, loads, and returns a new, unique BannerAd object.
  /// The widget that calls this is responsible for managing the ad's lifecycle.
  BannerAd createBannerAd(BannerAdListener listener) {
    final bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: listener,
    );
    bannerAd.load();
    return bannerAd;
  }

  // --- The Interstitial and Dispose logic remains the same, but note the change in disposeAds ---
  void loadInterstitialAd() {
    if (state.interstitialAd != null) return;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          state = state.copyWith(interstitialAd: ad);
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  void showInterstitialAd({required VoidCallback onAdDismissed}) {
    if (state.interstitialAd == null) {
      onAdDismissed();
      loadInterstitialAd();
      return;
    }

    state.interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        debugPrint('InterstitialAd failed to show: $err');
        ad.dispose();
        onAdDismissed();
      },
    );

    state.interstitialAd!.show();
    state = AdState(interstitialAd: null); // Clear the used ad
    loadInterstitialAd(); // Pre-load the next one
  }

  void disposeAds() {
    // We only need to dispose the centrally managed ads here.
    state.interstitialAd?.dispose();
  }
}