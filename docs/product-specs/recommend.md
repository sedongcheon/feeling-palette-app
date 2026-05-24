---
title: Recommend — product spec
owner: harness-engineer
status: living
last_verified: 2026-05-23
domain: recommend
---

# Recommend (음악·책 추천)

분석을 받은 일기에 대해 위로 메시지 + 음악 1~3개 + 책 1~3개 추천을 제공.
**광고 시청을 보상으로 한 보너스 콘텐츠** 위치. 일기 분석/저장 흐름과는
분리되어 있고, 광고 미시청 사용자에게도 일기 분석 자체는 정상 작동한다.

## User stories

1. 일기를 분석받은 사용자가 결과 화면에서 "🎁 음악·책 추천 받기"를 누르면
   보상 광고를 보고 위로 메시지 + 음악 + 책 추천을 받는다.
2. 텍스트 일기와 음성 일기 둘 다 같은 진입점 패턴 (각 분석 결과 화면).
3. 광고를 끝까지 보지 않으면 추천이 제공되지 않고 친절한 안내 메시지가
   뜬다 (재시도 가능).
4. 추천 결과 화면은 곡/책이 실제 존재하지 않을 수 있다는 disclaimer를
   하단에 작은 회색 글씨로 항상 노출한다.

## Out of scope

- 음악/책 항목 딥링크 (Spotify, Google Books). 별도 plan.
- 같은 일기 → 같은 추천 캐싱. 매번 새 호출 (백엔드 §9 향후 작업).
- 추천을 일기 entry에 영구 저장. 휘발성 응답 — 다음에 다시 보려면 광고
  다시 봐야 함.
- 추천 카운터 / 한도. 광고가 자연 throttle (광고 fill rate + 사용자
  의지).

## API 매핑

백엔드 신규 `POST /api/diary/recommend`. 참고:
`/Users/cheonsedong/Documents/appProject/feelingPaletteAgent/docs/10-flutter-integration.md`.

| Flutter                              | Server                       |
|--------------------------------------|------------------------------|
| `RecommendRequest.content`           | `content` (1~1000자)          |
| `RecommendRequest.locale`            | `locale` (`ko` / `en`)       |
| `RecommendResponse.primaryEmotion`   | `primary_emotion`            |
| `RecommendResponse.comfortMessage`   | `comfort_message`            |
| `RecommendResponse.music[]`          | `music` (1~3개)               |
| `MusicRecommendation.title/artist/reason` | `title` / `artist` / `reason` |
| `RecommendResponse.books[]`          | `books` (1~3개)               |
| `BookRecommendation.title/author/reason`  | `title` / `author` / `reason` |
| `RecommendResponse.disclaimer`       | `disclaimer` (서버 보장)      |

- `primary_emotion`은 6키 (`joy/sadness/anger/anxiety/calm/excitement`) —
  `analyze`와 동일 enum 재사용.
- 응답 누락/형 불일치는 boundary parsing 규칙에 따라 안전 fallback.

## 에러 처리

| 코드     | 의미                       | UX                                                |
|----------|----------------------------|---------------------------------------------------|
| 400      | content empty / 1000자 초과 | "일기를 1~1000자로 작성해주세요" (회피 — 진입 시 점검) |
| 500      | LLM 일시 실패              | "추천을 가져오지 못했어요. 다시 시도해주세요" + 재시도 |
| timeout  | Lambda cold start 등       | 동일 메시지. 자동 재시도 없음 (사용자가 광고 또 봐야 함) |
| 그 외    | 드뭄                       | "일시 오류 — 잠시 후 다시"                         |

Crashlytics로 boundary 실패 (`recordError`) — analyze와 같은 패턴.

## 광고 자원 공유

- Rewarded ad 하나의 자원 (`AdsService.showRewarded()`)을 두 진입점이 공유:
  1. **보너스 분석 +1** — `HomeScreen` / `today_entry_card`의 기존 진입점.
     `_grantBonus`로 quota 늘림.
  2. **추천 받기** — 분석 결과 화면(텍스트/음성)의 신규 진입점.
     `recommend()` 호출 후 `RecommendScreen` push.
- 각 진입점은 `showRewarded()`만 호출하고, `earned` 후의 후속 동작이 다르다.
- `AdsService._skipNextAnalysisInterstitial`은 보너스 분석 흐름을 위한
  플래그로 그대로 유지. 추천 흐름에서는 영향 없음 (분석이 일어나지 않으므로).

## Quota / 분석 카운터 영향

- 추천은 **분석이 아니므로** quota를 소비하지 않는다. `DiaryProvider`의
  `dailyAnalysisLimitReached`에 영향 없음.
- Interstitial 카운터(`AdsService.onAnalysisCompleted`)도 호출하지 않는다.

## Privacy / PII

- 보내는 본문은 일기 본문 그대로.
- 음성 일기 진입점에서는 이미 익명화된 `originalContent`가 아니라 사용자가
  편집한 원문이 들어간다 — 단, 음성 일기는 저장 시점에도 원문이 들어가므로
  추가 위험은 없음.
- 텍스트 일기 진입점에서는 사용자가 직접 입력한 원문이 그대로 들어간다 —
  기존 `/api/diary/analyze` 호출과 동일한 데이터 노출 수준.
- 신규 PII 익명화 규칙은 없음. 향후 음성 일기와 동일한 정규식 익명화를
  추가하려면 별도 plan.

## Disclaimer (필수)

LLM이 존재하지 않는 곡/책을 만들 위험이 있어 결과 화면 하단에 disclaimer
회색 작은 글씨 노출이 **의무**다 (백엔드 §7).

- 서버 응답의 `disclaimer`가 primary.
- 응답이 비어 있으면 ARB `recommendDisclaimerFallback` 사용.

## 성공 기준

- 텍스트/음성 두 진입점에서 광고 → 추천 흐름 happy path 정상.
- disclaimer가 항상 노출됨.
- 광고 dismissedEarly / notReady / 500 / timeout 모든 케이스 SnackBar.
- 기존 보너스 분석 흐름 회귀 없음.
- ko / en 모두 자연스럽게 보임.

## 관련

- [ads.md](ads.md)
- [voice-journal.md](voice-journal.md)
- [emotion-analysis.md](emotion-analysis.md)
- [docs/exec-plans/active/003-recommend-and-palette.md](../exec-plans/active/003-recommend-and-palette.md)
