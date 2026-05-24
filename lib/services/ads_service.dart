import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/ad_ids.dart';
import 'consent_service.dart';

/// 보상 광고 한 회 시청 시도의 결과.
///
/// caller는 outcome별로 다른 사용자 메시지를 보여줘야 한다.
/// 특히 [notReady]와 [dismissedEarly]는 사용자 경험상 명확히 구분되어야 한다 —
/// "광고를 안 봤다"가 아니라 "광고가 안 떴다"는 retry 가능한 상태이고,
/// 사용자에게 "광고 준비 중" 메시지가 적절하다.
enum RewardedOutcome {
  /// 광고가 아직 로드 안 됨. 잠시 후 재시도하면 됨.
  /// preload가 fail했거나 호출 시점에 in-flight였던 경우.
  notReady,

  /// SDK가 광고 표시를 거부 (fullScreen 권한 등). 드물다.
  failed,

  /// 광고는 표시됐지만 사용자가 보상 임계점 전에 닫음.
  dismissedEarly,

  /// 사용자가 광고를 끝까지 봐서 보상을 받음.
  earned,
}

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

  // Throttle config — 분석 5번 누적마다 광고. 90초 쿨다운으로 연쇄 방지.
  // 카운터는 SharedPreferences에 영속화되어 세션을 넘어 누적된다.
  // 보상 광고 직후의 분석은 카운터에서 제외해(_skipNextAnalysisInterstitial)
  // 한 번에 두 광고가 연달아 뜨는 일을 방지하고, rewarded 광고가 끝난 후
  // [kInterstitialBlockAfterRewarded] 동안은 시간 기반으로도 interstitial을
  // 차단해 사용자가 빠르게 여러 번 분석할 때도 두 광고가 연달아 뜨지 않게
  // 한다.
  static const int kInterstitialEveryNAnalyses = 5;
  static const Duration kInterstitialCooldown = Duration(seconds: 90);
  static const Duration kInterstitialBlockAfterRewarded = Duration(minutes: 5);
  static const String _kAnalysisCountKey = 'ads_analysis_count';

  bool _initialized = false;
  bool _adFree = false;

  InterstitialAd? _interstitialAd;
  bool _interstitialLoading = false;

  RewardedAd? _rewardedAd;
  bool _rewardedLoading = false;

  int _analysisCount = 0;
  DateTime? _lastInterstitialShownAt;
  // 직전에 보상 광고를 봐서 보너스 분석을 받은 사용자에게는 다음 분석 1회를
  // 자동 광고 카운터에서 제외한다. 보상 광고 + 전면 광고가 연달아 뜨는 부담 방지.
  bool _skipNextAnalysisInterstitial = false;
  // 보상 광고가 끝난 시점 기준 [kInterstitialBlockAfterRewarded] 동안은
  // 시간 기반으로도 interstitial을 차단한다. quota 채워서 보너스 광고를 본
  // 사용자가 그 직후 보너스 분석을 여러 번 빠르게 돌릴 때, "다음 1회만 제외"
  // 규칙만으로는 두 번째 보너스 분석부터 다시 interstitial이 뜨는 케이스를
  // 방지한다.
  DateTime? _blockInterstitialUntil;

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
    final prefs = await SharedPreferences.getInstance();
    _analysisCount = prefs.getInt(_kAnalysisCountKey) ?? 0;
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
  ///   - cooldown elapsed since last show
  ///   - an ad is preloaded
  ///
  /// Returns `true` when the ad was shown. Preloads the next one on dismiss.
  Future<bool> maybeShowInterstitial() async {
    if (_adFree || !_initialized) return false;
    final blockedUntil = _blockInterstitialUntil;
    if (blockedUntil != null && DateTime.now().isBefore(blockedUntil)) {
      return false;
    }
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
    _lastInterstitialShownAt = DateTime.now();
    return true;
  }

  /// Call right after a successful AI analysis. Tracks lifetime count
  /// (persisted via SharedPreferences) and fires an interstitial on every
  /// [kInterstitialEveryNAnalyses]-th success (subject to cooldown).
  ///
  /// 보상 광고 직후의 분석은 _skipNextAnalysisInterstitial 플래그가 켜져 있어
  /// 카운트도 증가시키지 않고 광고 트리거도 하지 않는다.
  void onAnalysisCompleted() {
    if (_skipNextAnalysisInterstitial) {
      _skipNextAnalysisInterstitial = false;
      return;
    }
    _analysisCount++;
    unawaited(_persistAnalysisCount());
    if (_analysisCount % kInterstitialEveryNAnalyses == 0) {
      unawaited(maybeShowInterstitial());
    }
  }

  Future<void> _persistAnalysisCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kAnalysisCountKey, _analysisCount);
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

  /// Shows the rewarded ad. Returns [RewardedOutcome] indicating one of four
  /// distinct states. Business logic (e.g., `+3` analyses) is applied by the
  /// caller only when this returns [RewardedOutcome.earned].
  ///
  /// Critical: [RewardedOutcome.notReady] (광고가 안 뜸) must be distinguished
  /// from [RewardedOutcome.dismissedEarly] (광고는 뜸, 사용자가 일찍 닫음) so
  /// the UI can surface "광고 준비 중" instead of "광고 시청 안 함".
  Future<RewardedOutcome> showRewarded() async {
    if (!_initialized) return RewardedOutcome.notReady;
    final ad = _rewardedAd;
    if (ad == null) {
      preloadRewarded();
      return RewardedOutcome.notReady;
    }
    _rewardedAd = null;
    final completer = Completer<RewardedOutcome>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preloadRewarded();
        if (!completer.isCompleted) {
          completer.complete(
              earned ? RewardedOutcome.earned : RewardedOutcome.dismissedEarly);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        preloadRewarded();
        if (kDebugMode) debugPrint('[Ads] Rewarded show failed: $err');
        if (!completer.isCompleted) {
          completer.complete(RewardedOutcome.failed);
        }
      },
    );
    await ad.show(
      onUserEarnedReward: (ad, reward) {
        earned = true;
        // 보상 받음 → 다음 분석 1회는 자동 광고 카운터에서 제외 +
        // [kInterstitialBlockAfterRewarded] 동안은 시간 기반으로도
        // interstitial 차단해 두 광고 연속 노출을 막는다.
        _skipNextAnalysisInterstitial = true;
        _blockInterstitialUntil =
            DateTime.now().add(kInterstitialBlockAfterRewarded);
      },
    );
    return completer.future;
  }
}
