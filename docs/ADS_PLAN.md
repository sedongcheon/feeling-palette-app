# 광고 통합 플랜 가이드

Feeling Palette에 **리워드 + 배너 + 전면** 광고를 **AdMob + Pangle mediation**으로 도입하기 위한 설계 문서. 아직 구현 전 단계이며, 이 문서는 착수 시 레퍼런스로 사용됩니다.

---

## 1. 핵심 방침

| 항목 | 결정 |
|------|------|
| 광고 형식 | 리워드 + 배너 + 전면 광고 3종 병행 |
| Mediation | **1단계(현재): AdMob 단독** / 2단계: Pangle 추가 (사업자 등록 이후) / 3단계: AppLovin·Meta·Unity |
| 광고 ID 관리 | 코드 상수 + `kDebugMode` 스위치 (`.env.json` 사용 안 함) |
| 보너스 저장 | `flutter_secure_storage`에 `bonus_YYYY-MM-DD` 키 |
| 광고 제거 IAP | 비소모성 단일 상품 `remove_ads` (₩2,500). 구현은 Phase 9로 후속 |

> **Pangle 유보 사유**: 개인 개발자 자격으로 가입 시 반려율 높음 + 사업자 등록 필요. 현재 단계에선 수익 규모 대비 리스크가 커서 AdMob 단독으로 시작. 앱 성장 및 사업자 등록 여부 판단 후 Pangle mediation 추가 예정.

### 광고 배치 철학
- 일기 작성 / 잠금 / PIN 설정 / AI 분석 진행 중 화면은 **광고 없음** — 감정 맥락을 깨지 않기 위함
- 배너는 **정보 조회** 탭에만 (캘린더 / 통계 / 타임라인)
- 전면은 **분석 완료 후**, 빈도 보수적으로
- 리워드는 **사용자 자발적** opt-in, 분석 한도 언락 용도로만

---

## 2. 결정 사항 상세

### 2.1 전면 광고 주기

| 값 | 설정 |
|---|------|
| 트리거 | AI 분석 **2번째 완료 시마다** |
| 세션 캡 | 최대 1회 / 세션 |
| 쿨다운 | 최소 3분 (연속 트리거 방지) |

**근거**: 실제 유저 대부분은 하루 1개 일기 × 1~3번 분석 패턴. 매 5회면 전면광고가 평생 안 뜸. 매 2회·세션 1회·쿨다운 3분이 "1세션 1회" 리듬을 만들면서 체감 과하지 않음.

### 2.2 리워드 보너스 정책

| 값 | 설정 |
|---|------|
| 1회 시청당 보상 | **+1 분석 언락** |
| 일일 시청 한도 | **5회** |
| 일일 최대 보너스 | +5 (절대 상한: 하루 8개 분석) |
| CTA 노출 조건 | `dailyAnalysisLimitReached == true` |

**근거**: 일일 한도를 3개로 타이트하게 잡은 결과, +1씩 최대 5회 언락 = 총 8개가 균형점. "작게 자주"가 광고 시청률과 사용자 만족도 모두 유리 — 보상이 크면 시청 후 만족하고 이탈, 작으면 "하나 더 보고 싶다"로 재시청 유도. 업계 평균(하루 3~5회) 상단에 맞춤.

### 2.3 Mediation 전략

**1단계 (초기 런칭, 현재 단계)**
- **AdMob 단독**
- Mediation 설정 없이 AdMob 자체 인벤토리만 사용
- 구현 복잡도 최소, 회사 겸업/사업자 이슈 없음

**2단계 (사업자 등록 후 / 앱 정착 후)**
- Pangle 추가 — APAC 특히 국내 fill rate·eCPM 강점
- AdMob 대시보드에서 mediation 그룹 추가로 붙일 수 있음
- 코드 변경 거의 없음 (네이티브 dependency만 추가)

**3단계 (3개월 이상 운영 후)**
- AppLovin MAX
- Meta Audience Network
- Unity Ads
- (선택) Kakao AdFit — 국내 fill 보강

**근거**: Mediation 추가는 수익 증분 15~25% 수준인데 초기 복잡도·계정 리스크가 큼. AdMob 단독으로도 글로벌 광고 인벤토리 확보 가능하므로 MVP에 충분. 앱이 자리 잡고 운영 여력 생기면 점진적 확장.

### 2.4 광고 ID 관리 — 코드 상수 + `kDebugMode`

```dart
// lib/constants/ad_ids.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kDebugMode;

class AdIds {
  // --- App IDs ---
  static String get appId => Platform.isAndroid
      ? (kDebugMode
          ? 'ca-app-pub-3940256099942544~3347511713'   // Google test
          : 'ca-app-pub-XXXX~YYYY')                    // real
      : (kDebugMode
          ? 'ca-app-pub-3940256099942544~1458002511'   // Google test
          : 'ca-app-pub-XXXX~YYYY');                   // real

  // --- Ad Unit: Banner ---
  static String get banner => Platform.isAndroid
      ? (kDebugMode
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-XXXX/YYYY')
      : (kDebugMode
          ? 'ca-app-pub-3940256099942544/2934735716'
          : 'ca-app-pub-XXXX/YYYY');

  // --- Ad Unit: Interstitial ---
  static String get interstitial => Platform.isAndroid
      ? (kDebugMode
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-XXXX/YYYY')
      : (kDebugMode
          ? 'ca-app-pub-3940256099942544/4411468910'
          : 'ca-app-pub-XXXX/YYYY');

  // --- Ad Unit: Rewarded ---
  static String get rewarded => Platform.isAndroid
      ? (kDebugMode
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-XXXX/YYYY')
      : (kDebugMode
          ? 'ca-app-pub-3940256099942544/1712485313'
          : 'ca-app-pub-XXXX/YYYY');
}
```

**근거**
- AdMob ID는 시크릿이 아님 (광고 요청 시 평문 노출). 외부 주입 불필요
- 디버그 빌드에서 자동으로 테스트 ID가 박히므로 **계정 정지 위험 제거**
- `.env.json` 관리 부담 없음 — `flutter build` 한 번이면 릴리스 ID 자동 적용

### 2.5 광고 제거 IAP (Phase 9 선행 설계)

| 항목 | 값 |
|------|----|
| 상품 타입 | 비소모성 (Non-consumable) |
| Product ID | `remove_ads` |
| 가격 | ₩2,500 |
| 효과 | 배너 + 전면 광고 제거. **리워드는 유지** (자발적 시청이므로) |
| 미래 확장 | "Premium" 구독으로 전환 시 "광고 제거 + 분석 무제한" 번들 |

**사전 설계 포인트**: `AdsService`에 `bool get adFree` getter를 Phase 3부터 포함시켜, Phase 9에서 IAP 연결 시 한 줄만 바꾸면 되도록 구조화.

---

## 3. 페이즈별 실행 플랜

### Phase 0 — 외부 준비 (사용자 작업)

| # | 작업 | 비고 |
|---|------|------|
| 0.1 | AdMob 계정 생성 | `apps.admob.com` |
| 0.2 | 앱 2개 등록 | Android, iOS |
| 0.3 | 광고 단위 6개 발급 | Banner / Interstitial / Rewarded × 2플랫폼 |
| ~~0.4~~ | ~~Pangle 계정 생성~~ | **유보** — 사업자 등록 후 재검토 |
| ~~0.5~~ | ~~AdMob Mediation에 Pangle 연결~~ | **유보** |
| 0.6 | 개인정보처리방침 URL 준비 | AdMob 검수 필수 |
| 0.7 | 세금 / 지불 정보 등록 | 수익 발생 임박 시 |

### Phase 1 — 네이티브 설정 (AdMob 단독)
- **패키지 추가**: `google_mobile_ads`, `app_tracking_transparency`, `in_app_purchase`
- **Android**
  - `AndroidManifest.xml`: AdMob App ID `<meta-data>` 추가
  - (Pangle adapter는 추후 단계에서 추가)
- **iOS**
  - `Info.plist`: `GADApplicationIdentifier`, `SKAdNetworkItems`, `NSUserTrackingUsageDescription` 추가
  - minDeployment 14.0 이상 확인
- **Dart**: `lib/constants/ad_ids.dart` 작성

### Phase 2 — 동의 / 프라이버시
- **UMP SDK**로 GDPR 동의 폼 (잠금 해제 후 메인 진입 전)
- **iOS ATT** 프롬프트 (거부 시 비타겟 광고만)
- `lib/services/consent_service.dart` 작성

### Phase 3 — `AdsService` 추상화

```dart
// lib/services/ads_service.dart (skeleton)
class AdsService {
  static final instance = AdsService._();

  Future<void> initialize();                // SDK + UMP + ATT
  Future<void> preloadInterstitial();
  Future<void> preloadRewarded();
  BannerAd bannerAd(String placement);      // adaptive
  Future<bool> maybeShowInterstitial();     // throttle 적용
  Future<bool> showRewarded();              // returns earned

  bool get adFree;                          // Phase 9 IAP 연동 지점

  // 내부 throttle 상태
  int _sessionInterstitialCount = 0;
  DateTime? _lastInterstitialAt;
}
```

### Phase 4 — 배너 배치
- **삽입**: `calendar_screen.dart`, `stats_screen.dart`, `timeline_screen.dart`
- `lib/widgets/banner_ad_slot.dart` — 로드 실패 시 높이 0으로 접힘
- 홈 / 잠금 / PIN / 분석 진행 중 화면은 **제외**

### Phase 5 — 전면 광고 (분석 5회마다)
- `DiaryProvider.applyAnalysis` 성공 후 세션 카운터 증가
- 5의 배수일 때 `AdsService.maybeShowInterstitial()` 호출
- Throttle이 세션 캡·쿨다운 체크

### Phase 6 — 리워드 + 보너스 시스템

**DiaryProvider 확장**
```dart
int _todayBonusAnalyses = 0;
int _todayBonusAdsShown = 0;

Future<void> loadDailyBonus();   // secure storage에서 오늘 날짜 키로 로드
Future<void> grantBonusFromAd();  // +3 추가 + ad shown 카운트 +1
bool get canWatchBonusAd;         // shown < 2
int get effectiveDailyLimit;      // 10 + _todayBonusAnalyses
```

**UI 변경**
- 홈 상단 배지: 한도 도달 시 `[광고 보고 +3 언락]` 버튼 노출
- `TodayEntryCard`의 비활성 분석 버튼도 동일 CTA 공유
- 일일 시청 2회 소진 시 → "내일 다시 시도해보세요" 비활성 상태

**저장 키 예시**
```
bonus_2026-04-18: {"bonus": 6, "adsShown": 2}
```

### Phase 7 — 통합 테스트
- Google test ad unit ID로 전 플로우 스모크
- `MobileAds.instance.updateRequestConfiguration`에 테스트 기기 ID 등록
- Mediation 대시보드에서 Pangle impression 발생 확인
- `flutter analyze` 통과

### Phase 8 — 릴리스 준비
- **iOS**: ATT 문구 한국어로 명확히 (`NSUserTrackingUsageDescription`)
- **Android**: Play Console > Data Safety에 "광고" 수집 항목 표시
- 버전 bump → 실기기 실 ID 빌드 → 심사 제출

### Phase 9 — (후속) 광고 제거 IAP
- `in_app_purchase` 구현
- App Store Connect / Play Console에 상품 등록: `remove_ads` ₩2,500
- `lib/services/premium_service.dart` 생성 → `AdsService.adFree`와 연결
- 구매 복원 버튼 (설정/백업 화면에)
- 구매 상태는 로컬 캐시 + 앱 실행 시 복원 쿼리로 이중 검증

---

## 4. 주요 파일 (신규 / 수정)

### 신규 생성
- `lib/constants/ad_ids.dart` — 광고 ID 상수
- `lib/services/ads_service.dart` — 광고 제어 허브
- `lib/services/consent_service.dart` — UMP + ATT
- `lib/services/premium_service.dart` — IAP (Phase 9)
- `lib/widgets/banner_ad_slot.dart` — 배너 슬롯 위젯
- `lib/widgets/bonus_unlock_button.dart` — 리워드 CTA (선택적 추출)

### 수정
- `pubspec.yaml` — 패키지 3개 추가
- `android/app/src/main/AndroidManifest.xml` — App ID meta-data
- `android/app/build.gradle.kts` — Pangle adapter
- `ios/Runner/Info.plist` — GADApplicationIdentifier, SKAdNetworkItems, ATT 문구
- `ios/Podfile` — Pangle adapter
- `lib/main.dart` — `AdsService.initialize()` 호출 지점 추가
- `lib/providers/diary_provider.dart` — 보너스 카운터 추가, `dailyAnalysisLimitReached` 수정
- `lib/widgets/today_entry_card.dart` — 보너스 CTA 분기
- `lib/screens/home_screen.dart` — 일일 쿼터 배지에 CTA 병기
- `lib/screens/calendar_screen.dart` / `stats_screen.dart` / `timeline_screen.dart` — 배너 슬롯 삽입

---

## 5. 상수 레퍼런스

```dart
// 일일 분석 한도 (lib/models/diary.dart)
const int kMaxAnalysisCount = 3;            // 일기 1개당 분석 최대 횟수
const int kMaxDailyAnalyzedEntries = 3;     // 하루에 분석 가능한 일기 개수 (기본)

// 전면 광고 (lib/services/ads_service.dart)
const int kInterstitialEveryNAnalyses = 2;
const int kInterstitialSessionCap = 1;
const Duration kInterstitialCooldown = Duration(minutes: 3);

// 리워드 보너스 (lib/models/diary.dart)
const int kRewardBonusPerAd = 1;
const int kRewardMaxAdsPerDay = 5;
// 일일 최대 보너스 = 1 × 5 = 5
// 일일 절대 상한 = kMaxDailyAnalyzedEntries(3) + 5 = 8

// IAP
const String kIapRemoveAdsProductId = 'remove_ads';
```

---

## 6. 운영 체크리스트

### 배포 전
- [ ] 디버그 빌드에서 test ad ID만 노출되는지 확인
- [ ] 실 ID로 빌드 시 광고 정상 로드
- [ ] 개인정보처리방침 URL 유효
- [ ] ATT 프롬프트 / UMP 동의 정상 동작
- [ ] 리워드 시청 후 보너스 실제 반영
- [ ] 자정 지나면 보너스 카운트 리셋
- [ ] 네트워크 에러 시 앱 크래시 없이 배너 접힘

### 운영 중 모니터링
- **AdMob 대시보드** — eCPM, fill rate, click rate
- **Mediation 리포트** — 네트워크별 수익 분포
- **Play/App Store 리뷰** — "광고 너무 많다" 키워드 감시
- **Firebase Crashlytics** (있다면) — 광고 로드 관련 크래시

### 이상 징후 대응
| 증상 | 대응 |
|------|------|
| 배너 fill rate < 70% | Pangle 외 mediation 추가 검토 |
| 전면 광고 리뷰 컴플레인 | 쿨다운 늘리기 (4분 → 6분) 또는 세션 캡 (2 → 1) |
| 리워드 시청 완료 안 됨 | 네트워크 어댑터 버전 업데이트 / AdMob 테스트 |
| 계정 경고 (유효하지 않은 활동) | 디버그 빌드에서 실 ID 쓴 흔적 조사 |

---

## 7. 향후 확장 여지

- **App Open Ad** — 앱 실행 시 1회 노출 (수익 큼, UX 리스크도 큼)
- **네이티브 광고** — 타임라인 피드에 블렌딩
- **Premium 구독** — 광고 제거 + 분석 무제한 번들 (월 ₩1,200 or 연 ₩9,900)
- **Firebase Remote Config** — 주기/보상값을 서버에서 튜닝 가능하게
- **A/B 테스트** — 전면 광고 주기 4회 vs 5회 vs 6회 비교
