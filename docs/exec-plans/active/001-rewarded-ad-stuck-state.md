---
slug: rewarded-ad-stuck-state
title: 보상 광고 미준비 시 "광고 미시청" 오해 메시지 + iOS 닫기 버튼 가시성
owner: harness-engineer
status: completed
created: 2026-05-23
last_verified: 2026-05-23
related: [../../product-specs/ads.md, ../../product-specs/month-summary.md, ../../product-specs/weekly-insight.md]
---

# 001 — Rewarded ad stuck state

## Goal

iOS에서 보상 광고를 강제 종료한 사용자가 이후 "광고 시청이 완료되지 않아
요약을 만들지 못했어요" 메시지에 갇혀 광고 보기 자체를 진행하지 못하는
패턴을 해소한다.

## 사용자 보고 (2026-05-23)

> 보상 광고가 떴는데 창 닫기 버튼이 안 보여 계속... 앱을 강제로 닫았는데
> 그다음부터 광고 시청이 완료되지 않아 요약을 만들지 못했어요. 라는
> 얼럿이 뜨고 광고 보기를 이제는 진행 자체를 못하게 됨. iOS에서 발생.
> Android는 광고 보다 닫고 다시 들어가도 동일 메시지 안 뜨는 듯.

## Root cause 분석 (조사 결과)

### 문제 A — 광고 미준비 시 false 반환 → 오해 메시지 (구조적, 양 플랫폼)

`AdsService.showRewarded()` (`lib/services/ads_service.dart:231`):

```dart
Future<bool> showRewarded() async {
  if (!_initialized) return false;
  final ad = _rewardedAd;
  if (ad == null) {
    preloadRewarded();
    return false;          // <-- 광고 미준비 = 시청 안한 것과 같은 false
  }
  // ...
}
```

caller (`diary_provider.dart:229, 293, 413`)는 `false`를 모두
`XxxAdException`으로 변환 → 화면에 "광고 시청이 완료되지 않아..." 표시.

**그러나** caller UI(`_GenerateButton`, `today_entry_card`, stats summary)는
`rewardedReady`를 체크하지 않음 — quota(`canAd`)와 in-flight만 본다. 따라서:

1. 광고가 아직 로드 중 → `rewardedReady = false`인데 버튼은 활성화.
2. 사용자가 탭 → `showRewarded()`는 즉시 `false` 반환 (`_rewardedAd == null`).
3. caller가 `AdException` throw → "광고 시청이 완료되지 않아..." 표시.
4. 사용자 입장: *광고가 뜨지도 않았는데 "시청 안 했다"고 한다* — 혼란.

iOS는 강제 종료 후 SDK가 광고 캐시를 잃으면 재로드가 느려 이 상태에 빠질
확률이 더 높다. Android는 보통 더 빨리 재로드되어 안 보일 수 있음.

### 문제 B — iOS 보상 광고 닫기 버튼 가시성 (외부 SDK)

`google_mobile_ads: ^5.2.0` 사용. 사용자 보고는 "창 닫기 버튼이 안 보였다".

가능 원인:
- iOS notch / Dynamic Island가 광고 닫기 X 버튼 영역과 겹침 (광고 콘텐츠
  자체 책임 — Google 광고 인벤토리 중 일부가 safe area 미준수).
- 보상 광고는 *시청 시간* 채우기 전엔 X 버튼이 안 보이는 게 정상. 그러나
  완료 후엔 보여야 함. 광고에 따라 30s+ 걸릴 수 있음.
- 광고 콘텐츠 측의 deceptive ad practice (스킵 버튼 숨김 또는 작게).

이 문제는 우리 코드만으로 완전 해결 불가. 다만 *완화*는 가능 (아래 Phase E).

## Phases

- [x] **A. `RewardedOutcome` enum** — `showRewarded()` 반환 타입을
  `Future<bool>` → `Future<RewardedOutcome>` (notReady / dismissedEarly /
  earned / failed). preload는 안 건드림. Verify: `flutter analyze` clean ✓.

- [x] **B. caller 분기 + 메시지 분리** — `diary_provider.dart`의 3개 호출
  지점에서 `RewardedOutcome` switch. `notReady`/`failed` → 새 exception
  `RewardedAdNotReadyException` → UI에서 `adsNotReadyMessage` 표시.
  `dismissedEarly` → 기존 `MonthSummaryAdException`/`WeeklyInsightAdException`
  유지 → "광고를 끝까지 시청해야..." 표시. 4개 위젯의 catch도 갱신.
  Verify: `flutter analyze` clean ✓ + 실기기 보상 정상 시청 ✓.

- [~] **C. UI 게이팅 — revert됨 (회귀 원인)**. 초기 구현에서 4개 위젯에
  `context.watch<AdsService>().rewardedReady`로 버튼 disabled를 적용. 실기기
  검증 결과 *기존 코드의 숨은 트리거*인 "사용자 click이 `preloadRewarded`
  lazy 재시도"가 사라져 영영 stuck. revert. ARB의 `adsNotReadyButton` 키는
  unused 상태로 남음 (cleanup follow-up).

- [~] **D. preload 재시도 timer — revert됨**. C revert로 사용자 click이
  자연 트리거로 복원되니 background timer 불필요. Phase E의 Completer
  안전망과 함께 [plan 002로 분리](../tech-debt-tracker.md).

- [→] **E. iOS 닫기 버튼 완화 + Completer 안전망 — plan 002로 분리.**
  외부 SDK 영역 + Crashlytics 인프라 신설은 핫픽스 범위 초과. Plan 001의
  Phase A+B만으로 사용자 stuck은 해소됨.

- [x] **F. 통합 검증** — iPhone 실기기에서 사용자 검증:
  - 광고 보기 버튼 정상 활성화 ✓.
  - 광고 시청 끝까지 → 보상 정상 ✓.
  - 광고 시청 중 창 닫음 → 다음 진입 시 stuck 없이 정상 ✓.
  - 원래 보고 패턴(닫기 X 안 보임 + 강제 종료) 재현 불가 — 외부 SDK 영역
    드물게 발생, plan 002에서 안전망 추가 예정.

## Decision log

| Date       | Decision                                                                                       | Reason |
|------------|-----------------------------------------------------------------------------------------------|--------|
| 2026-05-23 | `showRewarded()` 반환 타입을 enum으로 확장. 기존 bool은 caller에서 의미 모호                  | "광고 시청 안 함" vs "광고 미준비"를 사용자 메시지에서 분리하기 위해. |
| 2026-05-23 | UI 게이팅을 caller마다 추가 (single helper 분리는 follow-up tech-debt)                         | 1 PR 1 concern. 광고 게이팅 helper는 별도 plan으로. |
| 2026-05-23 | iOS 닫기 버튼은 *완화*만, *완전 해결*은 외부 SDK 의존                                          | google_mobile_ads / 광고 콘텐츠 측의 통제 영역. 우리 측에서 강제 닫기 불가. |
| 2026-05-23 | Phase C, D revert. Phase A, B만 핫픽스 유지                                                   | 실기기 검증에서 회귀 발견 — UI 게이팅이 사용자 click(=preload 트리거)을 차단해 영영 stuck. 기존 +16 동작이 잘 됐던 이유는 사용자 click이 lazy 재시도 였기 때문. Phase C 게이팅 + Phase D timer가 그 매커니즘을 깨뜨림. |
| 2026-05-23 | Phase E (Completer 안전망, SDK 업데이트, Crashlytics)는 plan 002로 분리                       | 외부 SDK 영역 + Crashlytics 인프라 신설은 핫픽스 범위 초과. 사용자 stuck 패턴은 Phase A+B만으로 해소됨. |

## Risks & open questions

1. ~~사용자에게 확인 필요 (3가지)~~ **Decided 2026-05-23**:
   (a) 광고 화면 아예 안 뜨고 즉시 얼럿 → 문제 A 확정.
   (b) 시청 완료 후에도 X 안 보임 → SDK 콜백 누락 가능성 → Phase E 안전망 필요.
   (c) iPhone 실기기 (모델·iOS 버전은 follow-up으로 수집).

2. ~~광고 보상 후에도 그 광고가 재로드 안 됨?~~
   **Decided 2026-05-23**: AdsService는 `onAdDismissed`/`onAdFailedToShow`에서
   `preloadRewarded()`를 호출하므로 재로드는 됨. 단 강제 종료 시엔 콜백
   호출 없이 죽으므로 재시작 후 `initialize() → preloadRewarded()`에 의존.

3. ~~B/C와 충돌: caller UI가 광고 미준비 시 disabled되면 notifyListeners 시점?~~
   **Decided 2026-05-23**: `preloadRewarded`의 `onAdLoaded`/`onAdFailedToLoad`에서
   이미 `notifyListeners()` 호출 (ads_service.dart:215, 222). caller 위젯이
   `context.watch<AdsService>()`로 듣고 rebuild — 변경 필요 없음.

4. **Phase E의 안전망 timer가 정당한 광고를 일찍 닫을 위험**:
   - 안전망 timer를 5s로 잡으면 보상 광고가 정상적으로 자동 dismiss되는데
     5s가 넘는 경우 거짓 양성으로 complete 처리. 단 caller는 이미 `earned`로
     보고 다음 흐름 진행하므로 부작용은 *광고 화면이 잠시 더 떠있다가* 사용자가
     수동으로 닫는 정도. 5s가 합리적인지 검증 필요.
   - **Decided 2026-05-23**: 일단 5s로 시작, F단계 실기기 검증에서 조정.

## Progress log

- 2026-05-23 09:10  Plan 작성. Root cause 분석 완료. 사용자 confirm 필요한
  open question 3개 (#1).
- 2026-05-23 09:25  사용자 답변 받음: (a) 광고 화면 아예 안 뜸; (b) 시청 완료
  후에도 X 안 보임; (c) iPhone 실기기.
- 2026-05-23 09:40~10:00  Phase A~D 한 번에 적용 + 빌드.
- 2026-05-23 10:10  사용자 실기기 보고: "광고 준비 중" 상태에서 변하지 않음.
- 2026-05-23 10:30  진단: `git stash`로 +16 복원 → 빌드. 사용자 확인:
  +16에서는 보상 광고 정상. → **회귀 확정**.
- 2026-05-23 10:50  Phase C, D revert. Phase A, B만 유지. `git stash pop` 후
  Phase C/D 코드 정확히 revert. `flutter analyze` clean.
- 2026-05-23 11:05  재빌드 + 실기기 검증: 광고 정상 활성화, 보상 시청 OK,
  창 닫고 재진입 시 stuck 없음. → **Plan 001 completed**.

## Success criteria

- [x] iOS에서 광고 시청 중 창 닫고 재진입 시 stuck 없이 정상 동작.
- [x] 광고 미준비 시 "광고를 준비 중이에요. 잠시 후 다시 시도해주세요." 메시지
  ("광고 시청이 완료되지 않아..."와 명확 구분).
- [x] 광고 끝까지 시청 시 보상 정상 부여.
- [~] UI 게이팅 / preload 재시도 timer → 회귀 발생, revert. plan 002로 이관.
- [x] iPhone 실기기 happy path 수동 검증 통과.
- [ ] Android 실기기 검증 — 후속 (Android는 회귀 없을 것으로 추정, 출시 후
  관찰).
- [→] iOS 닫기 안 보임 외부 SDK 안전망 → plan 002.

## 적용 후 빌드 정책

- 버전 bump: `pubspec.yaml`의 `version:` 빌드 번호 +1.
- 출시 운영 중인 +9 / +10 검토에는 영향 없음 (별도 빌드).
- 검토 통과 후 차기 빌드로 함께 출시 또는 hotfix로 단독 출시.
