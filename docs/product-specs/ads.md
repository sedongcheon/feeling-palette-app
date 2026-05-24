---
title: Ads — product spec
owner: harness-engineer
status: living
last_verified: 2026-05-23
related:
  - recommend.md
domain: ads
---

# Ads (AdMob)

무료 사용자에게 광고 노출. 프리미엄 사용자에게는 절대 노출 금지.

## User stories

1. 무료 사용자가 타임라인을 스크롤하면 N개 일기마다 inline 광고 1개를 본다.
2. 무료 사용자는 AI 분석을 5회(`kInterstitialEveryNAnalyses`) 누적할 때마다
   전면(interstitial) 광고를 1번 본다. 단 직전 노출 후 90초
   (`kInterstitialCooldown`) 안엔 다시 안 뜬다. 텍스트 일기와 음성 일기는
   같은 카운터를 공유한다.
3. 무료 사용자는 일일 분석 한도(3건)에 도달하면 보상(rewarded) 광고를
   봐서 보너스 분석을 받을 수 있다 (최대 5건/일).
4. 프리미엄 사용자는 배너/전면 광고를 보지 않는다 (보상 광고는 계속 사용
   가능).
5. 분석을 받은 일기에 대해 사용자가 결과 화면에서 "🎁 음악·책 추천 받기"를
   누르면 보상 광고를 보고 위로 메시지 + 음악 + 책 추천을 받는다 (도메인:
   [recommend](recommend.md)).

## Out of scope

- 네이티브 광고 — 현재는 배너/inline + interstitial + rewarded.

## Acceptance

- AdMob fill rate > 95% (지역에 따라 다름).
- 광고 로드 실패 시 자리차지 박스 없이 자연스럽게 흐름 진행.
- 프리미엄 사용자 화면에 광고 코드 자체가 실행되지 않음 (CPU/네트워크 절약).
- 동의(consent) UMP를 통과한 사용자에게만 personalized ads, 그 외는 NPA.
- 기기 ID 광고 추적 동의는 iOS ATT + Android UMP 둘 다 처리.

## 광고 단위

- 현재 production unit id는 `lib/services/ads_service.dart` 또는
  `.env.json`에서 주입 (확인 필요).
- 테스트 모드는 `kDebugMode`일 때 또는 `--dart-define` flag로 활성화.

## 분기 정책

- iOS·Android 동일하게 활성화 (`docs/design-docs/core-beliefs.md` #8).

## 전면 광고 트리거 정책

`lib/services/ads_service.dart` 기준. UI는 직접 트리거 안 함 — service가
카운트 + 쿨다운 + preload를 캡슐화한다.

| 항목 | 값 | 근거 |
|---|---|---|
| 주기 | AI 분석 5회마다 1번 시도 | `kInterstitialEveryNAnalyses` |
| 쿨다운 | 직전 노출 후 90초 안엔 skip | `kInterstitialCooldown` |
| 카운터 영속화 | `SharedPreferences['ads_analysis_count']` (lifetime 누적) | — |
| 보상 광고 직후 분석 | 카운트도 안 늘리고 광고도 안 뜸 | `_skipNextAnalysisInterstitial` |
| 보상 광고 시청 후 차단 | 5분 동안 interstitial 시간 기반 차단 | `kInterstitialBlockAfterRewarded` / `_blockInterstitialUntil` |
| Preload | 1개 사전 로드, dismiss 후 자동 재 preload | `preloadInterstitial` |
| Prerequisite | UMP consent + SDK initialized + 비-프리미엄 | `initialize` / `setAdFree` |

**호출 위치 (`onAnalysisCompleted()`)**:

- 텍스트 일기 분석 성공 → `widgets/today_entry_card.dart`
- 음성 일기 분석 성공 → `screens/voice_analysis_result_screen.dart`

새 도메인이 AI 분석을 추가하면 동일 패턴으로 `onAnalysisCompleted()`를
호출해 카운터에 합류시킨다.

## 보상 광고 진입점

같은 rewarded ad 자원(`AdsService.showRewarded()`)을 여러 진입점이 공유한다.
각 진입점은 `earned` 콜백 후의 후속 동작만 다르고, 광고 자체는 동일.

| 진입점 | 화면 / 위치 | earned 후 동작 |
|---|---|---|
| 보너스 분석 | HomeScreen quota 배지 / `today_entry_card` | `DiaryProvider._grantBonus` — 일일 분석 한도 +1 (최대 5건/일) |
| Weekly insight unlock | `weekly_insight_block` | 주간 인사이트 1회 생성 권한 |
| 음악·책 추천 | 분석 결과 화면 (텍스트 `today_entry_card` + 음성 `voice_analysis_result_screen`) | `RecommendService.recommend(content=일기 본문)` → `RecommendScreen` push |

추천 흐름은 **분석으로 카운트되지 않는다** — `onAnalysisCompleted` 호출
없음, quota 영향 없음.

## Non-functional

- 광고 SDK는 `main.dart`에서 비동기 초기화 (첫 프레임 안 막음).
- 광고 노출은 타임라인 첫 페이지 로드 후, 사용자가 적어도 1번 스크롤한
  후에만 inline 시작 (입장 직후 흐림 방지).

## 관련

- [docs/ADS_PLAN.md](../ADS_PLAN.md)
- [docs/ADS_TESTING.md](../ADS_TESTING.md)
