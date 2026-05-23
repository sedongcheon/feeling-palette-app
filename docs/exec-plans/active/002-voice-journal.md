---
slug: voice-journal
title: 음성 일기 + AI 코칭 플로우 추가 (v1 안전 추가)
owner: implementer
status: in-progress
created: 2026-05-23
last_verified: 2026-05-23
related: [../../product-specs/voice-journal.md, ../../product-specs/diary.md, ../../product-specs/emotion-analysis.md]
---

# 002 — Voice journal

## Goal

출시 운영 중인 v1 앱에 **음성 → STT → 편집 → AI 분석** 신규 플로우를
회귀 없이 추가한다. 기존 텍스트 composer는 그대로 두고, composer 카드
우측에 마이크 아이콘 1개를 추가해 진입한다. 분석 결과는 `DiaryEntry`로
저장되어 캘린더/타임라인/통계가 자동 노출한다.

## Scope guard (출시 안전)

- iOS deployment target / Android minSdk 변경 **금지**.
- 기존 권한 / Firebase / IAP / Ads 설정 **건드리지 않음**.
- 기존 `EmotionAnalyzer` / `/api/diary/analyze` 엔드포인트 그대로 재사용.
  새 백엔드 엔드포인트는 향후 별도 plan에서 swap.
- 기존 사용자 데이터 영향 없음 (DB 컬럼 ADD only, DEFAULT 'text').

## Phases

- [x] **A. Plan + spec** — `docs/product-specs/voice-journal.md` 추가,
  본 plan 작성. Verify: 파일 존재 + 링크 정상.

- [x] **B. 패키지 추가** — `pubspec.yaml`에 `speech_to_text`,
  `permission_handler` 추가 (record는 의존성 mismatch로 drop, decision
  log 참고). `flutter pub get` clean.

- [x] **C. 권한** — iOS `Info.plist`에 `NSMicrophoneUsageDescription`
  + `NSSpeechRecognitionUsageDescription` 추가. Android
  `AndroidManifest.xml`에 `RECORD_AUDIO` 추가.

- [x] **D. DB 마이그레이션** — `database.dart`의 `_dbVersion` 5→6,
  `onUpgrade`에 `ALTER TABLE diary_entries ADD COLUMN source TEXT NOT
  NULL DEFAULT 'text'` 추가. `onCreate`에도 동일 컬럼 포함. `DiaryEntry`/
  `DiaryDao` 업데이트. `flutter analyze` clean.

- [x] **E. UserHashService** — `lib/services/user_hash_service.dart`.
  secure storage에 UUID 발급(없으면), SHA-256 해시 반환.

- [x] **F. VoiceJournal 모델 + 서비스** — `lib/models/voice_journal.dart`,
  `lib/services/voice_journal_service.dart`. 정규식 익명화 + 기존
  `/api/diary/analyze` 호출 + 응답을 `VoiceAnalyzeResponse`로 매핑.
  Crashlytics `recordError`로 boundary 실패 관측.

- [x] **G. 3개 화면** — `lib/screens/voice_recording_screen.dart` /
  `voice_edit_screen.dart` / `voice_analysis_result_screen.dart`.
  Provider 패턴, `AppPalette`, Navigator 1.0, ARB 다국어.

- [x] **H. HomeScreen 진입점** — `home_screen.dart`의 composer 카드
  하단 Row에 마이크 IconButton 추가. 기존 "추가" 버튼은 그대로.

- [x] **I. ARB 동기화** — `app_ko.arb`(마스터) + `app_en.arb`에 새
  voice_journal* 키 22개 추가. `flutter gen-l10n` 후 untranslated 0.

- [x] **J. 최종 검증** — `flutter analyze` clean, `flutter build apk
  --debug` ✓, `flutter build ios --debug --no-codesign` ✓. 실기기
  happy path smoke는 사용자 검증으로 follow-up.

## Decision log

| Date       | Decision                                                                 | Reason |
|------------|--------------------------------------------------------------------------|--------|
| 2026-05-23 | 기존 `/api/diary/analyze` 재사용, 응답을 클라에서 매핑 (Q1)              | 새 엔드포인트가 백엔드에 실제 존재하는지 미확인. 클라만으로 e2e 동작 가능. swap point는 service 한 곳. |
| 2026-05-23 | `DiaryEntry.source` 컬럼 1개 추가, 별도 `VoiceJournal` 테이블 없음 (Q2)  | 캘린더/타임라인/통계가 자동 노출. DB 변경 ALTER 1줄. |
| 2026-05-23 | UUID + secure storage + SHA-256 해시 (Q3)                                | 표준. 재설치 시 새 ID = 추적 불가. |
| 2026-05-23 | 원문은 로컬 sqflite에, 전송은 익명화본만 (Q4)                            | 일기 가치(원본 보존) + 프라이버시(전송 최소) 동시 만족. |
| 2026-05-23 | 진입점은 composer 카드 내 마이크 IconButton (Q6 A안)                     | 기존 멘탈 모델 자연스럽고 회귀 위험 가장 적음. |
| 2026-05-23 | 오디오 파일은 임시 디렉토리에만 저장, EditScreen 진입 직후 삭제          | 음성 보관은 out of scope, 디스크/프라이버시 절감. |
| 2026-05-23 | NER 익명화는 후속 plan, 본 plan은 정규식(전화/이메일/주민번호)만         | MVP 범위 제한. 회귀 위험 최소. |
| 2026-05-23 | `record` 패키지 제거, `speech_to_text`만 사용                            | record 5.2.1의 platform interface mismatch로 Android 빌드 실패. 오디오 파일 보관이 out-of-scope라 audio 캡처가 사실상 불필요 → 단일 패키지로 단순화. |

## Risks & open questions

1. **`speech_to_text` 한국어 인식 품질이 Android에서 디바이스마다 다름**
   (Google 앱 STT에 의존). 인식 실패 시 EditScreen에서 사용자가 직접
   타이핑할 수 있도록 빈 TextField로도 진입 가능하게 설계.

2. **iOS 시뮬레이터에서는 마이크/STT 제한** — 실기기 검증 필요.
   본 plan의 Phase J 빌드 통과까지만 자동 검증, 실기기 happy path는
   사용자가 확인.

3. **기존 텍스트 일기 회귀 가능성** — DB 마이그레이션과 composer 변경이
   기존 흐름에 영향. `DiaryEntry.source` 컬럼은 DEFAULT 'text'로
   안전, composer는 기존 "추가" 버튼 동작 변경 없이 옆에 아이콘만 추가.

4. **백엔드 새 엔드포인트 swap 시점** — 본 plan과 분리. 백엔드 작업이
   완료되면 별도 plan(`003-voice-journal-v1-api-swap`)에서 service
   파일 한 곳만 수정.

## Progress log

- 2026-05-23  Plan + spec 작성, product-specs/index.md / exec-plans/index.md
  등록.
- 2026-05-23  Phases B~I 일괄 적용. record 5.2.1 platform interface
  mismatch로 Android 빌드 실패 → record drop, speech_to_text 단독 사용.
  spec/plan에 decision 기록.
- 2026-05-23  Phase J — Android(`app-debug.apk`) + iOS(`Runner.app`)
  빌드 모두 성공. `flutter analyze` clean. Crashlytics recordError를
  voice_journal_service의 boundary 실패에 추가.
- 2026-05-23  실기기(iPhone, iOS 26.5) install + 사용자 검증.
  - 1차 검증에서 quota 우회 회귀 발견 — 음성 일기가 daily quota를
    완전히 우회 (사용자 보고: 6→7번 무제한). 원인: `bypassDailyQuota`를
    저장 단계에만 두고 EditScreen에서 백엔드 호출 전 검증을 누락.
  - 핫픽스: EditScreen의 "이 일기로 분석받기"가 백엔드 호출 전에
    `dailyAnalysisLimitReached` 체크. quota 초과 시 새 스낵바
    `voiceJournalDailyLimitReached`로 차단.
  - 재install 시 EXC_BAD_ACCESS 발생 → `cd ios && pod install`로 해결.
  - 깨끗한 상태에서 재검증 → 7번째 음성 일기 시도가 EditScreen에서
    정상 차단됨. **패치 검증 합격**.

## Success criteria

- [→] 새 음성 → 편집 → 분석 → 저장 플로우가 end-to-end 동작 (실기기
  수동 시나리오 — 사용자 검증 follow-up).
- [x] 마이크 권한 거부 / 네트워크 실패 / STT 인식 실패 시 사용자 메시지 +
  재시도 (RecordingScreen, EditScreen, AnalysisResultScreen에 각각).
- [x] 기존 텍스트 composer "추가" 버튼 동작 회귀 없음 (composer 내부
  Row만 변경, 버튼 로직 동일).
- [x] 기존 사용자 데이터 정상 조회 — DB v5→v6 `ALTER TABLE ... ADD
  COLUMN source DEFAULT 'text'`로 기존 entries 자동 backfill.
- [x] `flutter analyze` clean.
- [x] `flutter build apk --debug` 성공.
- [x] `flutter build ios --debug --no-codesign` 성공.
- [x] iOS 실기기(iPhone, iOS 26.5) happy path + quota 차단 사용자 검증
  완료. Android 실기기는 follow-up.

## 적용 후 빌드 정책

- 본 plan은 신규 기능 추가 → `pubspec.yaml`의 `version:` 빌드 번호 +1
  (예: 1.0.3+17 → 1.0.4+18). 단, 빌드 번호 bump는 사용자 검증 후
  별도 commit.
- 출시 운영 중인 +9 / +10 검토에는 영향 없음 (별도 빌드).
