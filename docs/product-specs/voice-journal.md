---
title: Voice Journal — product spec
owner: harness-engineer
status: living
last_verified: 2026-05-23
domain: voice_journal
---

# Voice Journal

기존 텍스트 일기에 더해 **음성으로 일기를 녹음 → 한국어 온디바이스 STT
→ 편집 → AI 코칭 분석** 플로우를 추가한다. 기존 `diary` 도메인의
sub-flow이며 별도 도메인을 새로 만들지 않는다(`DiaryEntry.source`
컬럼으로만 구분).

## User stories

1. 사용자는 홈 composer 카드 우측의 마이크 아이콘을 탭해 음성 녹음
   화면에 진입한다.
2. 사용자는 큰 원형 버튼으로 녹음을 시작/중지한다. 최대 3분.
3. 녹음 완료 시 한국어(ko_KR) 온디바이스 STT 결과가 편집 화면에
   prefill된다. 사용자는 자유롭게 수정한다.
4. 사용자는 "다시 말하기"로 녹음 화면에 재진입하거나 "이 일기로 분석받기"
   버튼으로 백엔드 분석을 요청한다.
5. 분석 결과 화면은 dominant emotion + 색상 원 + 공감 메시지 + 테마 칩을
   보여준다.
6. "기록 보관"을 누르면 음성 일기가 `DiaryEntry`로 저장되어 캘린더/타임라인/
   통계에 자동 반영된다(source='voice').

## Out of scope (현재)

- 오디오 파일 보관 / 재생 (편집 후 폐기).
- NER 기반 이름 익명화 (정규식만; 다음 단계).
- 음성 첨부 backup (Google Drive 백업은 텍스트 일기만).

## Acceptance

- 6개 스토리 happy path 수동 시나리오 통과 (iOS·Android 각 1회).
- 마이크 권한 거부 시 안내 다이얼로그 후 이전 화면 복귀.
- API 502 / 네트워크 실패 / STT 실패 시 사용자 메시지 + 재시도 가능.
- p95 STT 종료 → prefill: 1.5s (3분 발화 기준).
- 기존 텍스트 일기 플로우 회귀 없음 (composer "추가" 버튼 정상 동작).

## API

현재는 기존 `POST https://feeling-api-aws.sedoli.co.kr/api/diary/analyze`
를 재사용한다. 새 v1 엔드포인트(`/api/v1/journal/analyze`)는 백엔드
배포 후 swap 예정(decision log: Q1).

요청은 `{content, locale}` 그대로 사용하되, **content는 익명화된
텍스트**만 보낸다. 응답은 클라이언트에서 신규 UI 모델로 매핑한다:

| Voice journal UI    | 기존 API 응답에서 매핑                     |
|---------------------|--------------------------------------------|
| dominant_emotion    | `primary_emotion`                          |
| intensity_score     | `emotions[primary_emotion]` / 100          |
| empathy_response    | `comment`                                  |
| suggested_color_hex | `emotionInfoOf(primary_emotion).hex`       |
| color_reasoning     | i18n 정적 문구 (감정별 색의미)             |
| themes              | 빈 배열 (백엔드 신규 엔드포인트 도입 시 채움) |
| emotions            | `EmotionScores` → `[{label, intensity}, …]` |

## Data

- `lib/models/voice_journal.dart`:
  - `AnalyzeRequest { anonymizedText, userIdHash }`
  - `VoiceAnalyzeResponse { dominantEmotion, intensityScore, empathyResponse, suggestedColorHex, colorReasoning, themes, emotions }`
- `DiaryEntry`에 `source` 컬럼 (`'text'` | `'voice'`) 1개만 추가. 기존
  스키마 영향 없음 (DEFAULT 'text').
- 오디오 파일은 만들지 않는다. `speech_to_text`가 live mic stream을
  처리해 텍스트만 추출하므로 audio 보관 / 임시 파일 생성이 모두 불필요.
  (초안에서는 `record` 패키지로 mp4(AAC) 임시 파일 + STT를 동시 사용하려
  했으나 동시 마이크 점유 충돌 위험 + 5.2.1의 platform interface
  mismatch로 빌드 실패 → 단일 패키지로 단순화.)

## 권한

| Platform | Key | Reason |
|----------|-----|--------|
| iOS | `NSMicrophoneUsageDescription` | 일기 음성 녹음 |
| iOS | `NSSpeechRecognitionUsageDescription` | 온디바이스 STT |
| Android | `android.permission.RECORD_AUDIO` | 일기 음성 녹음 |

기존 권한(USE_BIOMETRIC, INTERNET, NSFaceIDUsageDescription 등)은
건드리지 않는다.

## PII 익명화 (MVP — 정규식만)

EditScreen에서 백엔드 호출 직전 다음 패턴을 치환:

- 전화번호 (`010-XXXX-XXXX`, `010XXXXXXXX`, 국번 포함) → `[전화번호]`
- 이메일 → `[이메일]`
- 주민등록번호 (`XXXXXX-XXXXXXX`) → `[주민번호]`

NER 기반 인명/지명 익명화는 다음 plan으로 분리.

**원문은 로컬 sqflite에만 저장**, 전송은 익명화본만.

## user_id_hash

`UserHashService`가 첫 호출 시:
1. `flutter_secure_storage`에서 `voice_journal_user_id` 키 조회.
2. 없으면 UUID v4 발급해 저장.
3. SHA-256 해시 16진 문자열을 반환 (Server에는 원본 UUID 노출 안 됨).

재설치 시 새 ID 발급 = 추적 불가 (의도).

## Non-functional

- 최대 녹음 길이: 3분 (자동 종료, 사용자에게 4초 전 카운트다운).
- STT 언어: 사용자 locale이 ko면 `ko_KR`, 그 외에는 `en_US`(MVP).
- 백엔드 호출 timeout: 10s (`http.post`의 기본 + `.timeout`).
- 익명화 적용 위치는 service 한 곳; UI에서 직접 텍스트를 보내지 않음.

## i18n

새 ARB 키는 `voiceJournal*` prefix:

- `voiceJournalStart`, `voiceJournalStop`, `voiceJournalCancel`
- `voiceJournalMaxDurationReached`, `voiceJournalPermissionDenied`
- `voiceJournalSttFailed`, `voiceJournalAnalyzeButton`, `voiceJournalRetry`
- `voiceJournalResultEmpathyTitle`, `voiceJournalResultThemes`
- `voiceJournalKeepAsEntry`, `voiceJournalBackHome`
- `voiceJournalColorReasoning` (감정별 placeholder 1개)

ko 마스터, en 동기화. `flutter gen-l10n`이 자동 실행됨.
