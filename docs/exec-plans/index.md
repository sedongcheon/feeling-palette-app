---
title: Exec-plans index
owner: harness-engineer
status: living
last_verified: 2026-05-23
---

# Exec-plans

이 index는 모든 plan(활성 + 과거)의 카탈로그다. 워크플로, 파일 형태,
저자 규칙은 [../PLANS.md](../PLANS.md)에 있다.

## Active

_(없음. 다음 plan은 002-rewarded-ad-safety-net 후보로 tech-debt에 등록됨.)_

## Completed

| # | Slug | Closed | Outcome |
|---|------|--------|---------|
| 000 | [bootstrap-harness](active/000-bootstrap-harness.md) | 2026-05-23 | harness engineering 1단계 도입 완료 (docs/agents/hooks). 코드 미수정, flutter analyze clean. |
| 001 | [rewarded-ad-stuck-state](active/001-rewarded-ad-stuck-state.md) | 2026-05-23 | Phase A+B 적용 — RewardedOutcome enum + 메시지 분리. Phase C/D는 회귀 발견 후 revert (plan 002 분리). v1.0.3+17. iPhone 실기기 보상 시청 확인. |

(_000, 001은 active/ 디렉토리에 있음 — 머지 commit 후 git mv로 completed/로 이동._)

## Hygiene

- 14일 이상 `in-progress`이고 Progress-log 추가가 없는 plan은 `doc-gardener`가
  flag (signature: `stale-active-plan`).
- 머지된 PR에 연결된 plan이 `completed/`로 이동 안 됐다면 flag
  (signature: `unfiled-plan`).
- Plan 번호는 monotonic. `planner` 에이전트가 두 디렉토리를 다 읽고
  다음 번호를 고른다.
