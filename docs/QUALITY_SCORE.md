---
title: Quality score
owner: harness-engineer
status: generated
last_verified: 2026-05-23
generator: (수동 — `tool/score_quality.dart` 도입 예정)
---

# Quality score

> **현재는 수동 산정.** 향후 `tool/score_quality.dart` 도입 시 자동 재생성
> (tech-debt 등록됨).

각 도메인 × 계층에 대해 A/B/C/D 등급을 매긴다. D 셀은 자동으로 tech-debt
티켓을 발행 (도입 시).

## 등급 기준

- **A**: 계층 규약 준수, 테스트 happy + boundary, 구조적 로깅, 의존성 인자 주입.
- **B**: 규약은 대체로 준수하지만 테스트가 부분적이거나 한두 군데
  의존성이 하드코딩됨.
- **C**: 계층 mix-up 있음, 또는 service 안에서 직접 I/O 호출, 테스트 부재.
- **D**: 계층 위반 명시적, `dynamic`/`as Foo` 다수, 또는 단일 파일 500줄+.

## 현재 매트릭스 (2026-05-23, 수동)

| Domain            | types | config | repo | service | runtime | ui |
|-------------------|-------|--------|------|---------|---------|----|
| diary             | B     | C      | B    | B       | C       | B  |
| emotion_analysis  | C     | —      | —    | C       | —       | —  |
| month_summary     | B     | —      | B    | B       | —       | B  |
| weekly_insight    | B     | —      | B    | B       | —       | B  |
| premium           | —     | —      | —    | C       | —       | C  |
| ads               | —     | —      | —    | C       | —       | C  |
| backup            | C     | —      | —    | C       | —       | C  |
| auth / app_lock   | —     | —      | —    | C       | C       | C  |
| consent           | —     | —      | —    | C       | —       | —  |
| stats             | —     | —      | —    | —       | —       | C  |

## 등급 산정 근거 (요약)

- `diary` runtime이 C인 이유: `DiaryProvider`가 sqflite를 직접 호출 (service
  분리가 일부만 됨). target: B → A.
- `premium`이 C인 이유: 단일 service 파일에 IAP 콜백 처리 + UI 상태 + 광고 분기 혼재.
- `ads`가 C인 이유: 광고 매니저가 ChangeNotifier가 아니라 정적 메서드라
  testability 낮음.
- `backup`이 C인 이유: Google Drive API 호출이 boundary 파싱 없이 진행
  (응답 dict 직접 사용).
- `auth/app_lock`이 C인 이유: PIN 평문 저장 (해시 미적용 — 위협 모델 점검 필요),
  service/runtime 미분리.

자세한 사항은 [exec-plans/tech-debt-tracker.md](exec-plans/tech-debt-tracker.md) 참조.

## 갱신 절차

- exec-plan이 한 도메인을 끝낸 후, 마지막 단계에서 이 표를 수동 갱신.
- 향후 `dart run tool/score_quality.dart`로 자동화 (현재 미존재).
