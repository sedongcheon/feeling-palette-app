import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/ad_ids.dart';
import 'consent_service.dart';

/// Central hub for all ad interactions.
///
/// Responsibilities:
///   - Initialize the Mobile Ads SDK (once, after consent is gathered)
///   - Create banner ads on demand (caller disposes)
///   - Preload interstitial + rewarded ads and expose throttled show methods
///   - Expose [adFree] flag — Phase 9 IAP toggles it to hide banner/interstitial.
///     Rewarded ads stay available even when ad-free.
///
/// Exposed as a [ChangeNotifier] so UI widgets can reactively hide ad slots
/// when [adFree] flips or when the SDK finishes initializing.
class AdsService extends ChangeNotifier {
  AdsService._();
  static final AdsService instance = AdsService._();

  // Throttle config (mirrors docs/ADS_PLAN.md §5)
  static const int kInterstitialEveryNAnalyses = 2;
  static const int kInterstitialSessionCap = 1;
  static const Duration kInterstitialCooldown = Duration(minutes: 3);

  bool _initialized = false;
  bool _adFree = false;

  InterstitialAd? _interstitialAd;
  bool _interstitialLoading = false;

  RewardedAd? _rewardedAd;
  bool _rewardedLoading = false;

  int _sessionInterstitialShown = 0;
  int _sessionAnalysisCount = 0;
  DateTime? _lastInterstitialShownAt;

  bool get isInitialized => _initialized;
  bool get adFree => _adFree;
  bool get canShowBanner => _initialized && !_adFree;
  bool get rewardedReady => _rewardedAd != null;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  Future<void> initialize() async {
    if (_initialized) return;
    if (!await ConsentService.instance.canRequestAds()) {
      if (kDebugMode) debugPrint('[Ads] Consent denies ad requests; skipping init.');
      return;
    }
    await MobileAds.instance.initialize();
    if (AdIds.testDeviceIds.isNotEmpty) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: AdIds.testDeviceIds),
      );
    }
    _initialized = true;
    if (kDebugMode) debugPrint('[Ads] SDK initialized');
    notifyListeners();

    if (!_adFree) {
      preloadInterstitial();
    }
    preloadRewarded();
  }

  /// Called by the IAP flow (Phase 9). Banner + interstitial disappear; any
  /// currently preloaded interstitial is discarded. Rewarded ads still work.
  void setAdFree(bool value) {
    if (_adFree == value) return;
    _adFree = value;
    if (_adFree) {
      _interstitialAd?.dispose();
      _interstitialAd = null;
    } else if (_initialized && _interstitialAd == null) {
      preloadInterstitial();
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Banner
  // ---------------------------------------------------------------------------

  /// Creates a new banner ad. Returns `null` when ads should not be shown
  /// (SDK not ready or user is ad-free). Caller must call `load()` then
  /// eventually `dispose()`.
  BannerAd? createBanner({AdSize size = AdSize.banner}) {
    if (_adFree || !_initialized) return null;
    return BannerAd(
      adUnitId: AdIds.banner,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, err) {
          if (kDebugMode) debugPrint('[Ads] Banner failed: $err');
          ad.dispose();
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Interstitial
  // ---------------------------------------------------------------------------

  void preloadInterstitial() {
    if (_adFree || !_initialized) return;
    if (_interstitialAd != null || _interstitialLoading) return;
    _interstitialLoading = true;
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoading = false;
        },
        onAdFailedToLoad: (err) {
          _interstitialAd = null;
          _interstitialLoading = false;
          if (kDebugMode) debugPrint('[Ads] Interstitial failed: $err');
        },
      ),
    );
  }

  /// Shows an interstitial **if** all conditions pass:
  ///   - not ad-free, SDK initialized
  ///   - session cap not reached
  ///   - cooldown elapsed since last show
  ///   - an ad is preloaded
  ///
  /// Returns `true` when the ad was shown. Preloads the next one on dismiss.
  Future<bool> maybeShowInterstitial() async {
    if (_adFree || !_initialized) return false;
    if (_sessionInterstitialShown >= kInterstitialSessionCap) return false;
    final last = _lastInterstitialShownAt;
    if (last != null &&
        DateTime.now().difference(last) < kInterstitialCooldown) {
      return false;
    }
    final ad = _interstitialAd;
    if (ad == null) {
      preloadInterstitial();
      return false;
    }
    _interstitialAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        if (kDebugMode) debugPrint('[Ads] Interstitial show failed: $err');
        preloadInterstitial();
      },
    );
    await ad.show();
    _sessionInterstitialShown++;
    _lastInterstitialShownAt = DateTime.now();
    return true;
  }

  /// Call right after a successful AI analysis. Tracks session count and
  /// fires an interstitial on every [kInterstitialEveryNAnalyses]-th success
  /// (subject to session cap and cooldown).
  void onAnalysisCompleted() {
    _sessionAnalysisCount++;
    if (_sessionAnalysisCount % kInterstitialEveryNAnalyses == 0) {
      unawaited(maybeShowInterstitial());
    }
  }

  // ---------------------------------------------------------------------------
  // Rewarded
  // ---------------------------------------------------------------------------

  void preloadRewarded() {
    if (!_initialized) return;
    if (_rewardedAd != null || _rewardedLoading) return;
    _rewardedLoading = true;
    RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedLoading = false;
          notifyListeners();
        },
        onAdFailedToLoad: (err) {
          _rewardedAd = null;
          _rewardedLoading = false;
          if (kDebugMode) debugPrint('[Ads] Rewarded failed: $err');
          notifyListeners();
        },
      ),
    );
  }

  /// Shows the rewarded ad. Returns `true` if the user earned the reward
  /// (watched to the threshold), `false` if dismissed early, not ready, or
  /// failed to show. Business logic (e.g., `+3` analyses) is applied by the
  /// caller when this returns `true`.
  Future<bool> showRewarded() async {
    if (!_initialized) return false;
    final ad = _rewardedAd;
    if (ad == null) {
      preloadRewarded();
      return false;
    }
    _rewardedAd = null;
    final completer = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preloadRewarded();
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        preloadRewarded();
        if (kDebugMode) debugPrint('[Ads] Rewarded show failed: $err');
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    await ad.show(
      onUserEarnedReward: (ad, reward) {
        earned = true;
      },
    );
    return completer.future;
  }
}
