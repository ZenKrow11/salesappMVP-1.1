// lib/services/ad_manager.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// An enum to uniquely identify ad placements for pre-loading.
enum AdPlacement { splashScreen, productSwiper }

final String bannerAdUnitId = defaultTargetPlatform == TargetPlatform.android
    ? 'ca-app-pub-3940256099942544/6300978111'
    : 'ca-app-pub-3940256099942544/2934735716';

final String interstitialAdUnitId = defaultTargetPlatform == TargetPlatform.android
    ? 'ca-app-pub-3940256099942544/1033173712'
    : 'ca-app-pub-3940256099942544/4411468910';

final adManagerProvider = StateNotifierProvider<AdManager, AdState>((ref) {
  final adManager = AdManager();
  ref.onDispose(() => adManager.disposeAllAds());
  return adManager;
});

class AdState {
  final InterstitialAd? interstitialAd;
  // A map to hold our pre-loaded banner ads.
  final Map<AdPlacement, BannerAd> loadedBannerAds;

  AdState({this.interstitialAd, this.loadedBannerAds = const {}});

  AdState copyWith({
    InterstitialAd? interstitialAd,
    Map<AdPlacement, BannerAd>? loadedBannerAds,
  }) {
    return AdState(
      interstitialAd: interstitialAd, // No ?? needed, we want to be able to clear it
      loadedBannerAds: loadedBannerAds ?? this.loadedBannerAds,
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

  /// Pre-loads a single banner ad and stores it in the state.
  void preloadBannerAd(AdPlacement placement, AdSize adSize) {
    // Don't load if an ad for this placement is already loaded or being loaded.
    if (state.loadedBannerAds.containsKey(placement)) {
      return;
    }

    final bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      request: const AdRequest(),
      size: adSize,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Pre-loaded BannerAd for $placement loaded successfully.');
          // Ad is loaded, add it to the state map.
          final newAds = Map<AdPlacement, BannerAd>.from(state.loadedBannerAds);
          newAds[placement] = ad as BannerAd;
          state = state.copyWith(loadedBannerAds: newAds);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd for $placement failed to load: $error');
          ad.dispose(); // Clean up the failed ad object.
        },
      ),
    );
    bannerAd.load();
  }

  /// Disposes a specific banner ad when it's no longer needed.
  void disposeAd(AdPlacement placement) {
    final ad = state.loadedBannerAds[placement];
    ad?.dispose();
    final newAds = Map<AdPlacement, BannerAd>.from(state.loadedBannerAds);
    newAds.remove(placement);
    state = state.copyWith(loadedBannerAds: newAds);
  }

  // This is your existing lazy-loading method for ads like the one on the home page.
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

  /// Cleans up all ads when the provider is disposed.
  void disposeAllAds() {
    state.interstitialAd?.dispose();
    for (var ad in state.loadedBannerAds.values) {
      ad.dispose();
    }
  }

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
    state = AdState(interstitialAd: null);
    loadInterstitialAd();
  }

  void disposeAds() {
    state.interstitialAd?.dispose();
  }
}