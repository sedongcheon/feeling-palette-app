---
title: Month summary — product spec
owner: harness-engineer
status: living
last_verified: 2026-05-23
domain: month_summary
---

# Month summary

달이 끝나면 그 달의 일기를 모아 한 줄짜리 요약/대표 감정을 생성한다.
캘린더의 월별 헤더와 통계 화면에서 소비.

## User stories

1. 사용자는 통계 화면에서 월별 한 줄 요약과 대표 감정 분포를 본다.
2. 새 달의 첫 일기 작성 시 또는 명시적 갱신 시 요약이 (재)생성된다.

## Out of scope

- 주간/연간 요약 (별도 도메인 `weekly_insight`).
- 외부 공유.

## Acceptance

- 한 달 이상의 일기가 있는 사용자는 통계 화면에서 월별 요약을 본다.
- 요약은 캐시되어 매번 API 호출하지 않는다 (sqflite 저장).

## Data

- `lib/models/month_summary.dart`
- `lib/db/month_summary_dao.dart`

## Non-functional

- 캐시 미스 시 백엔드 API 호출 (현재 엔드포인트 확인 필요 — `docs/AWS_INFRA.md`).

## Open questions

- 갱신 트리거가 명확치 않음 — 사용자가 같은 달의 일기를 수정/삭제하면
  요약이 stale해질 수 있음. 향후 invalidation 룰 정의 필요.
