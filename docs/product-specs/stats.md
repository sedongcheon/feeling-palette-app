---
title: Stats — product spec
owner: harness-engineer
status: living
last_verified: 2026-05-23
domain: stats
---

# Stats

일기 데이터의 시각화. 월별 감정 분포, 주간 인사이트, 상위 키워드 등.

## User stories

1. 사용자는 통계 탭에서 이번 달의 감정 분포 차트를 본다.
2. 사용자는 주간 인사이트 카드를 통계 화면에서 다시 본다.
3. 사용자는 상위 N개 키워드를 본다 (현재 구현 여부 확인 필요).

## Out of scope

- 데이터 export (CSV, PDF).
- 연간 회고.

## Acceptance

- 데이터 부족 시 빈 상태 메시지 (PRODUCT_SENSE.md의 가이드 준수).
- 차트는 시각 장애 사용자에게도 의미 있는 Semantics 라벨 제공.

## 의존성

- `month_summary`, `weekly_insight`, `diary` 도메인 데이터를 read-only로 소비.
- 자체 service는 없거나 최소화 — 주로 UI + provider 조립.

## Open questions

- 차트 라이브러리: 현재 사용 여부 확인 필요 (`fl_chart`, 또는 자체 CustomPaint).
