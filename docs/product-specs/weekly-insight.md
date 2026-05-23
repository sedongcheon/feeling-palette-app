---
title: Weekly insight — product spec
owner: harness-engineer
status: living
last_verified: 2026-05-23
domain: weekly_insight
---

# Weekly insight

지난 한 주의 일기를 분석해서 짧은 인사이트 카드를 생성한다 — 평소보다
긍정/부정 키워드, 가장 자주 등장한 단어, 한 줄 코멘트.

## User stories

1. 매주 월요일 첫 앱 진입 시 지난 주 인사이트 카드를 본다.
2. 통계 화면의 "주간" 탭에서 과거 주간 인사이트를 다시 본다.

## Out of scope

- 푸시 알림으로 인사이트 발송 (향후 옵션).
- 친구와 공유.

## Acceptance

- 7일 이상의 데이터가 있는 사용자에게 카드가 표시된다.
- 데이터 부족 시 카드는 자리 차지 없이 숨김.
- 카드는 sqflite에 캐시되어 같은 주를 다시 보여줄 때 재계산 안 함.

## Data

- `lib/models/weekly_insight.dart`
- `lib/db/weekly_insight_dao.dart`

## Non-functional

- 카드 생성은 백그라운드에서 (UI 블로킹 X).
- 톤은 [PRODUCT_SENSE.md](../PRODUCT_SENSE.md)의 *진단조 금지* 가이드 준수.

## Open questions

- 카드 표시 빈도 — 매주 vs 데이터 충분할 때만. 현재는 후자.
