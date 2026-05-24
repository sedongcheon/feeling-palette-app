---
slug: recommend-and-palette
title: /api/diary/recommend 신규 + analyze palette 5색 흡수
owner: implementer
status: completed
created: 2026-05-23
last_verified: 2026-05-24
closed: 2026-05-24
related:
  - ../../product-specs/ads.md
  - ../../product-specs/voice-journal.md
  - /Users/cheonsedong/Documents/appProject/feelingPaletteAgent/docs/10-flutter-integration.md
---

# 003 — Recommend + palette

## Goal

2026-05-23 백엔드 머지 두 변경을 출시 운영 중인 v1 앱에 회귀 없이 흡수:

1. **`/api/diary/analyze` 응답 `palette: List<String>` 5색**
   (`palette[0] == color`, backward-compatible). 분석 결과 화면 디자인을
   더 풍부하게 만드는 재료. 구버전 서버/응답이 와도 안전하게 fallback.
2. **신규 `POST /api/diary/recommend`** — 광고 시청 후 위로 문장 +
   음악 1~3 + 책 1~3 + disclaimer. 새 화면 + rewarded ad 분기 추가.

진입점: **분석 결과 화면(텍스트/음성 둘 다)에 "🎁 음악·책 추천 받기"
버튼 → rewarded → /recommend → 새 RecommendScreen**.

## Scope guard (출시 안전)

- iOS deployment target / Android minSdk 변경 **금지**.
- 기존 권한 / Firebase / IAP / Ads 설정 변경 **금지** (광고 단위 id 그대로).
- 기존 rewarded ad의 "보너스 분석 +1" 흐름 **유지**. 추천은 별도 진입점
  (사용자 선택 시 카드의 "추천 받기" 버튼 → 광고 → 추천).
  같은 rewarded 광고 자원을 공유한다 — `showRewarded()`만 호출하면 됨.
- 기존 `EmotionAnalyzer` / `VoiceJournalService`의 `color` 동작은 그대로
  (server `color` 무시하고 local `emotionInfoOf(primary).hex` 사용).
  Palette는 **추가** 필드로 응답에 싣고 결과 화면에서만 활용.
- 추천 화면은 분석 한도/카운터에 영향 없음 — 카운트 증가 안 함, interstitial
  카운터 (`onAnalysisCompleted`) 호출 안 함.
- 기존 사용자 데이터 영향 없음 (DB schema 변경 없음).

## Phases

- [x] **A. Plan + product-spec** — 본 plan + 신규
  `docs/product-specs/recommend.md` (도메인 스펙: API 매핑, UX 흐름,
  disclaimer 의무, 보안/PII 정책, 광고 자원 공유 노트). 
  `docs/product-specs/ads.md`에 rewarded 분기 표를 추가 (보너스 분석 / 추천).
  Verify: 파일 존재 + product-specs/index.md 갱신.

- [x] **B. Recommend 모델** — `lib/models/recommendation.dart` 신규.
  `RecommendResponse`, `MusicRecommendation`, `BookRecommendation`,
  `RecommendException`. fromJson은 boundary parsing 규칙 따라서 null/형
  안전. `primary_emotion`은 `EmotionType`으로 변환 (analyze와 동일 로직).
  Verify: `flutter analyze` clean.

- [x] **C. Recommend 서비스** — `lib/services/recommend_service.dart`.
  POST `/api/diary/recommend` 호출, 20s timeout, 400/500/timeout 분기,
  Crashlytics `recordError`로 boundary 실패 관측. 응답을
  `RecommendResponse`로 매핑. user_id_hash 전송은 v1 아니라 일단 보류
  (서버가 무시한다고 명시됨).
  Verify: `flutter analyze` clean. (단위 테스트는 v1 미구현 정책 그대로
  스킵 — tech-debt에 추가.)

- [x] **D. analyze palette 흡수** — `lib/services/emotion_analyzer.dart`
  와 `lib/services/voice_journal_service.dart` 두 군데에서 응답의
  `palette` (List<String>)을 parse해 모델로 전달.
  - `AnalysisResult`에 `List<String> palette` 추가, 구버전 서버 호환
    fallback: `[emotionInfoOf(primary).hex]`.
  - `VoiceAnalyzeResponse`에 `palette` 추가, 구버전 fallback: 위와 동일.
  - 기존 `color` 동작은 그대로 (server color 무시 정책 유지).
  - sqflite에는 저장 **안 함** (휘발성 응답 메타. 필요 시 향후 plan).
  Verify: `flutter analyze` clean. 호출 caller 빌드 깨지지 않음.

- [x] **E. RecommendScreen** — `lib/screens/recommend_screen.dart` 신규.
  - 헤더: 감정 뱃지 (`primaryEmotion`을 분석 결과와 동일 색상으로).
  - 위로 문장 (`comfortMessage`) 카드.
  - 🎵 음악 카드 1~3개 — title / artist / reason.
  - 📚 책 카드 1~3개 — title / author / reason.
  - 하단 disclaimer 회색 작은 글씨 (필수, §7 백엔드 문서).
  - 로딩/실패/성공 상태. 실패 시 재시도 버튼.
  - AppPalette / Navigator 1.0 / ARB 다국어 따름.
  - SafeArea, AppBar 스타일 기존 화면들과 일치.
  Verify: 빌드 + UI 시각 확인 (시뮬레이터).

- [x] **F. 진입점 — 텍스트 일기 분석 결과** — `lib/widgets/today_entry_card.dart`
  에 분석 완료 후 노출되는 결과 영역에 "🎁 음악·책 추천 받기" 버튼 1개
  추가. onPressed: rewarded 시청 → earned 시 push `RecommendScreen
  (content=일기 본문, locale=apiLocaleOf)`. 화면 내부에서 service 호출.
  dismissedEarly / notReady / failed는 SnackBar. 진행 중 buttonleading
  spinner. 진입점이 쓰는 CTA/SnackBar ARB 키도 함께 추가.
  Verify: `flutter analyze` clean (실기기 검증은 Phase J).

- [x] **G. 진입점 — 음성 일기 분석 결과** —
  `lib/screens/voice_analysis_result_screen.dart`의 버튼 Row 위에
  풀폭 outline "🎁 음악·책 추천 받기" 버튼 추가. 동일 흐름
  (showRewarded → earned → push RecommendScreen, 나머지는 SnackBar).
  일기 본문은 `widget.originalContent` 사용. locale은 `apiLocaleOf`.
  Verify: `flutter analyze` clean (실기기 검증은 Phase J).

- [x] **H. ARB 다국어 (진입점 CTA 키)** — Phase F에서 함께 추가.
  `recommendCtaLabel`, `recommendAdNotReady`, `recommendAdDismissed`
  양쪽 ARB sync + gen-l10n clean. G에서 동일 키 재사용.

- [x] **I. 빌드 검증** — `flutter analyze` clean + `flutter build apk
  --debug --dart-define-from-file=.env.json` 성공. SELF-REVIEW: PASS.

- [x] **J. 실기기 검증 (iOS + Android)** — iPhone (USB)에서 텍스트 일기
  진입점 → 광고 → 추천 화면 happy path 확인 (음악·책 추천 정상). Galaxy
  S22에서 adb 자동 검증: 캘린더 오늘 디폴트 선택 ✓, 분석 결과 화면에
  추천 진입점 ✓, 추천 화면 (감정 뱃지 + 위로 + 음악 3곡 + open_in_new
  affordance) ✓, 음악 카드 → YouTube 외부 검색 ✓, 책 카드 → Google
  외부 검색 ✓. 광고 dismissedEarly/notReady SnackBar는 코드 경로 확인
  (UI 자동 검증 한계). 기존 보너스 분석 흐름은 회귀 없음.

## Decision log

- **D-001 / palette는 모델에 받지만 sqflite 저장 안 함.** 휘발성 응답
  메타. 저장하면 schema 마이그레이션 + 캐싱 정책 결정이 추가로 따라옴.
  향후 결과 화면에서 재계산 필요해지면 별도 plan.

- **D-002 / 추천은 별도 진입점 (분석 결과 화면의 버튼).** rewarded ad는
  현재 보너스 분석 +1로 쓰이고 있는데, 백엔드 가정처럼 "광고 끝 → 추천"
  으로 교체하면 무료 분석 한도가 사실상 줄어든다. 사용자 선택 사항.
  결정: rewarded 자원은 공유, 진입점은 분리. 사용자가 "보너스 분석"
  버튼을 누르면 보너스 +1, "음악·책 추천 받기" 버튼을 누르면 추천.

- **D-003 / `color`는 서버 값 무시, local mapping 유지.** 기존 동작
  유지가 핵심. palette는 신규 디자인 자산으로만 사용 (추천 카드 톤 등).

- **D-004 / 추천은 quota / interstitial 카운터에 영향 없음.** 추천은
  광고 시청 → 보상이 핵심이라 분석으로 치지 않는다. `onAnalysisCompleted`
  호출 안 함. (rewarded ad 자체는 이미 `_skipNextAnalysisInterstitial`
  로 다음 1회 카운트 제외 처리됨 — 추천 흐름에선 그 부분도 의미 없음.)

- **D-005 / disclaimer는 키 두 군데 정의.** 서버가 보내는 텍스트가
  primary, 빈 응답일 때를 위한 fallback 키를 ARB에 둠 (`recommendDisclaimerFallback`).

- **D-006 / 추천 결과는 일회성. 저장/캐싱 안 함.** ~~같은 일기로 광고
  또 보면 새 추천 요청. 캐싱 정책은 백엔드 문서 §9 향후 작업으로 남김.~~
  *D-007로 대체됨.*

- **D-007 / 세션 메모리 캐시 도입.** Phase J 검증 중 사용자 피드백 —
  같은 일기에서 추천 화면을 닫고 다시 열 때마다 광고를 봐야 하는 게
  과하다는 의견. `lib/services/recommend_cache.dart` 싱글톤
  `Map<String, RecommendResponse>` (key: `${locale}:${content.trim()}`)
  추가. 진입점 두 곳(텍스트/음성)에서 cache hit이면 광고 skip하고 바로
  `RecommendScreen` push. 영구 캐시는 entry 단위 sqflite 스키마 변경이
  필요해 별도 plan (Out of scope 갱신).

- **D-008 / 추천 카드 탭 → 외부 검색.** 사용자 요청. 음악은 YouTube
  검색(`youtube.com/results?search_query=<title artist>`), 책은 Google
  검색(`google.com/search?q=<title author>`). 가장 보편적이고 ko/en
  모두 무난한 타겟. `url_launcher` 패키지 추가, `launchUrl(...,
  mode: externalApplication)`. 앱별 딥링크(Spotify, 교보 등)는 별도
  plan. ARB `recommendOpenLinkFailed` 추가 (실패 SnackBar).
  카드 상단에 `open_in_new` 아이콘으로 affordance.

## Risks

- **R-1 (LLM 응답 지연)**: 백엔드 doc도 10~15s 가능 안내. timeout 20s,
  로딩 스피너 + cancel 가능. 사용자가 광고 본 후 hang하면 매우 나쁜 경험.
  → Crashlytics로 timeout 빈도 모니터.
- **R-2 (광고 자원 경합)**: 한 rewarded ad가 보너스 분석/추천 둘 다
  소비. 사용자가 추천 받으려고 광고 봤는데 보너스도 1 늘어남? 아니다 —
  추천 진입점은 `showRewarded()` 만 호출하고 `_grantBonus`는 호출하지
  않음. 보너스 진입점만 `_grantBonus` 호출. 분기 명확.
- **R-3 (가짜 콘텐츠)**: LLM이 존재하지 않는 곡/책을 만들 수 있음 →
  disclaimer 노출이 의무 (백엔드 §7).
- **R-4 (palette 응답 누락)**: 구서버 / 일시 장애 시 `palette` 없음 →
  fromJson에서 fallback `[emotionInfoOf(primary).hex]`로 안전 처리.

## Success criteria

- 두 진입점(텍스트/음성) 모두에서 광고 → 추천 정상 흐름.
- disclaimer 항상 노출 (서버 값 우선, fallback 키).
- 기존 보너스 분석 흐름 회귀 없음.
- `flutter analyze` clean. release 빌드 가능 (실수행은 별도 plan).
- ko / en 양쪽 모두 자연스럽게 보임.
- 광고 dismissedEarly / notReady / 500 / timeout 케이스 SnackBar 정상.

## Out of scope

- ~~음악/책 항목 딥링크 (Spotify, Google Books). 백엔드 §9 향후 작업.~~
  *D-008에서 일반 검색 URL(YouTube/Google)로 흡수.* 앱별 딥링크
  (Spotify, Apple Music, 교보 등)는 별도 plan.
- 같은 일기 → 같은 추천 **영구** 캐싱 (앱 재시작 후에도 유지). sqflite
  schema 변경 필요. 별도 plan. (D-007로 세션 메모리 캐시는 도입됨.)
- palette를 결과 화면 디자인에 적극 활용 (그라데이션, pale 배경 등).
  v1에는 모델만 받고, 활용은 디자인 업그레이드 별도 plan.
- 새 v1 엔드포인트(`/api/v1/journal/...`) swap. 별도 plan.
- 추천 다양성 튜닝. 백엔드 작업.

## Progress log

- 2026-05-23: plan 작성. 사용자 결정 — A+B 함께, rewarded는 보너스 +
  추천 별도 진입점.
- 2026-05-23: Phase A 완료. `docs/product-specs/recommend.md` 신규,
  `docs/product-specs/ads.md`에 user story #5 + "보상 광고 진입점"
  섹션 추가, `docs/product-specs/index.md`에 recommend 행 등록,
  `docs/exec-plans/index.md` Active 테이블에 003 등록.
- 2026-05-23: Phase B 완료. `lib/models/recommendation.dart` 신규
  (`RecommendRequest`, `MusicRecommendation`, `BookRecommendation`,
  `RecommendResponse`, `RecommendException`). 모든 fromJson은
  null/형 안전 (`_stringOrEmpty`, `_parseList`). `flutter analyze`
  clean.
- 2026-05-23: Phase C 완료. `lib/services/recommend_service.dart`
  신규. 20s timeout, HTTP non-2xx / TimeoutException /
  ClientException / FormatException 모두 Crashlytics
  `recordError(reason: ...)`로 기록 후 `RecommendException` throw.
  응답 매핑은 `RecommendResponse.fromJson` 위임. `flutter analyze`
  clean.
- 2026-05-24: Phase D 완료. `AnalysisResult` / `VoiceAnalyzeResponse`
  에 `List<String> palette` 추가, `emotion_analyzer` /
  `voice_journal_service` 두 service에서 `parsed['palette']` 파싱
  + 빈/형 불일치 시 `[color]` fallback. server `color` 무시 정책은
  그대로 (local `emotionInfoOf` 우선). DB schema 미변경. `flutter
  analyze` clean.
- 2026-05-24: Phase E 완료. `lib/screens/recommend_screen.dart`
  신규 — FutureBuilder로 loading/error/success 분기. 성공 시
  감정 뱃지 + 위로 카드 + 음악 카드 1~3 + 책 카드 1~3 + disclaimer
  (서버 값 우선, 빈 응답 시 `recommendDisclaimerFallback`) + 닫기.
  실패 시 재시도 버튼. 화면이 쓰는 recommend* ARB 키 11개를
  `app_ko.arb` / `app_en.arb`에 함께 추가하고 `flutter gen-l10n`로
  AppLocalizations 재생성. Phase H 범위는 진입점 CTA 키만 남도록
  plan 갱신. `flutter analyze` clean.
- 2026-05-24: Phase F + H 완료. 진입점 CTA/SnackBar 3개 ARB 키
  추가 (`recommendCtaLabel`, `recommendAdNotReady`,
  `recommendAdDismissed`) + gen-l10n. `today_entry_card.dart`에
  결과 카드 아래 outline "🎁 음악·책 추천 받기" 버튼 추가,
  `_openRecommend()`가 `AdsService.showRewarded()` 호출 → earned
  시 push `RecommendScreen`, dismissedEarly/notReady/failed는
  SnackBar. 진행 중 button leading spinner. 기존 보너스 분석 흐름
  (`_handleBonusUnlock`) 그대로 유지 — 두 진입점이 같은 rewarded
  자원을 공유. `flutter analyze` clean.
- 2026-05-24: Phase G 완료. `voice_analysis_result_screen.dart`의
  Row 위에 동일 outline CTA 버튼 추가. `_openRecommend()` 동일
  패턴 (showRewarded → earned 시 push RecommendScreen with
  originalContent + apiLocaleOf). 진행 중 _isOpeningRecommend
  spinner. 기존 "기록 보관" / "처음으로" 흐름은 영향 없음.
  `flutter analyze` clean.
- 2026-05-24: Phase I 완료. `flutter analyze` clean (전체 프로젝트).
  `flutter build apk --debug --dart-define-from-file=.env.json`
  성공 (Gradle assembleDebug 21.8s). 다음은 Phase J 실기기 검증.
- 2026-05-24: Phase J 진행 중. iPhone 실기기 깔끔 설치 + 텍스트 일기
  진입점 + 광고 + 추천 화면 happy path 확인. 사용자 피드백 — 재진입
  시마다 광고 반복이 과함. D-007 결정: 세션 메모리 캐시 도입.
  `lib/services/recommend_cache.dart` 신규, 진입점 2곳 + 화면 1곳에서
  cache hit 분기. `flutter analyze` clean.
- 2026-05-24: D-008 결정/구현. 추천 카드 탭 → 외부 검색
  (음악: YouTube, 책: Google). `url_launcher` 패키지 추가,
  `_RecommendCard`에 `InkWell` + `open_in_new` 아이콘, 실패 시
  `recommendOpenLinkFailed` SnackBar (ko/en ARB). `flutter
  analyze` clean.
- 2026-05-24: 003 outside-of-plan polishing 묶음 (배포 직전):
  캘린더 진입 시 오늘 디폴트 선택 (`calendar_screen.dart` initState
  + refreshCurrentMonth), `kRewardBonusPerAd` 1→3 (광고당 보너스
  분석 +3), interstitial 정책 개선 — `kInterstitialEveryNAnalyses`
  3→5 + `kInterstitialBlockAfterRewarded = 5분` (rewarded 직후 5분간
  interstitial 시간 기반 차단으로 두 광고 연속 노출 회피),
  flutter_native_splash로 스플래시 추가 (light `#FAFAF8` / dark
  `#1A1A2E` + 앱 아이콘). ads.md spec 갱신. Phase J 마무리.
- 2026-05-24: Phase J 완료. iPhone + Galaxy S22 검증 OK. plan
  closed.
