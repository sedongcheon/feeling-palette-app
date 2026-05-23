---
title: google_mobile_ads — quick reference
owner: harness-engineer
status: living
last_verified: 2026-05-23
upstream: https://pub.dev/packages/google_mobile_ads
---

# google_mobile_ads (AdMob)

배너/inline + interstitial. iOS/Android **동일 활성화**.

## 초기화 (`main.dart`)

```dart
await MobileAds.instance.initialize();
await AdsService.initialize();
```

## 배너 로드

```dart
final ad = BannerAd(
  adUnitId: kBannerAdUnitId, // .env.json 또는 const
  size: AdSize.banner,
  request: const AdRequest(),
  listener: BannerAdListener(
    onAdLoaded: (_) {},
    onAdFailedToLoad: (ad, err) => ad.dispose(),
  ),
);
await ad.load();
```

위젯에서:

```dart
SizedBox(
  width: ad.size.width.toDouble(),
  height: ad.size.height.toDouble(),
  child: AdWidget(ad: ad),
);
```

## Interstitial 로드/표시

```dart
InterstitialAd.load(
  adUnitId: kInterstitialAdUnitId,
  request: const AdRequest(),
  adLoadCallback: InterstitialAdLoadCallback(
    onAdLoaded: (ad) => _interstitial = ad,
    onAdFailedToLoad: (err) {},
  ),
);

// 사용자가 자연스러운 멈춤 지점에 도달했을 때:
await _interstitial?.show();
```

## 동의 (UMP)

`lib/services/consent_service.dart`에서 UMP SDK로 동의 요청.

```dart
final params = ConsentRequestParameters();
ConsentInformation.instance.requestConsentInfoUpdate(params, () async {
  if (await ConsentInformation.instance.isConsentFormAvailable()) {
    await ConsentForm.loadAndShowConsentFormIfRequired();
  }
}, (error) {});
```

iOS는 ATT (App Tracking Transparency)도 추가.

## 규칙

- 프리미엄 사용자(`PremiumService.isPro`)에게 광고 코드 자체 실행 금지 — CPU,
  네트워크, 배터리 절약.
- 광고 unit id는 `.env.json` 또는 `--dart-define`로 주입. 하드코딩된 production id
  금지.
- `kDebugMode`일 때 또는 dart-define로 테스트 unit id 사용.
- 동의 안 한 사용자에게는 `nonPersonalizedAds: true` 옵션의 광고 요청만.

## 관련 문서

- [docs/ADS_PLAN.md](../ADS_PLAN.md)
- [docs/ADS_TESTING.md](../ADS_TESTING.md)
- [docs/product-specs/ads.md](../product-specs/ads.md)
