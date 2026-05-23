---
slug: bootstrap-harness
title: harness engineering 형식 도입 (1단계 — 문서/에이전트만)
owner: harness-engineer
status: completed
created: 2026-05-23
last_verified: 2026-05-23
related: [../PLANS.md, ../../ARCHITECTURE.md]
---

# 000 — Bootstrap harness (docs + agents)

## Goal

Feeling Palette에 harness engineering 워크플로를 *문서와 에이전트 레벨*에서
도입한다. 코드 구조 변경은 본 plan 범위 밖. 출시 운영(앱스토어 +9 / Play +10
검토 중)에 영향 없이, 다음 기능 개발부터는 plan→implement→self-review→
agent-review→merge 루프를 따른다.

## Phases

- [x] **A. 핵심 docs 작성** — ARCHITECTURE, DESIGN, FLUTTER, RELIABILITY,
  SECURITY, PRODUCT_SENSE, PLANS, QUALITY_SCORE. Verify: `ls docs/*.md`.
- [x] **B. design-docs 작성** — index, core-beliefs, boundary-parsing,
  self-review-checklist. Verify: `ls docs/design-docs/*.md`.
- [x] **C. exec-plans 스켈레톤** — index, tech-debt-tracker, active/, completed/.
  Verify: `ls -R docs/exec-plans/`.
- [x] **D. product-specs 작성** — index + 각 도메인(diary, emotion_analysis,
  premium, ads, backup, weekly_insight, month_summary, auth-app-lock).
  Verify: `ls docs/product-specs/*.md`.
- [x] **E. references 작성** — dart, flutter, freezed, riverpod, dio, http,
  sqflite, in_app_purchase, google_mobile_ads, firebase, l10n. Verify: `ls docs/references/*.md`.
- [x] **F. .claude/agents 작성** — planner, implementer, code-reviewer,
  security-reviewer, taste-linter, bug-reproducer, doc-gardener,
  tech-debt-collector. Verify: `ls .claude/agents/*.md`.
- [x] **G. .claude/skills 작성** — drive-app, ship-pr, firecrawl-refresh,
  query-crashlytics, run-build. Verify: `ls .claude/skills/*.md`.
- [x] **H. .claude/settings.json + hooks** — pre-block-generated.sh,
  post-flutter-analyze.sh, stop-self-review.sh, prompt-steer-reminder.sh.
  기존 settings.local.json은 보존 (allow 목록 머지). Verify: `ls .claude/hooks/*.sh && bash -n .claude/hooks/*.sh`.
- [x] **I. CLAUDE.md 재작성** — 운영 내용 보존, knowledge tree로 재구성,
  새 docs로 링크. Verify: `wc -l CLAUDE.md` (80-120줄 목표).
- [x] **J. 동작 점검** — `flutter analyze` clean 확인 (행동 변경 없음).
  Verify: `flutter analyze` → "No issues found! (ran in 3.7s)" (2026-05-23).

## Decision log

| Date       | Decision                                                                                        | Reason |
|------------|-------------------------------------------------------------------------------------------------|--------|
| 2026-05-23 | 단일 패키지 유지, melos/모노레포 전환은 미래 작업                                               | 출시 운영 중 리스크 회피. tech-debt에 등록. |
| 2026-05-23 | observability stack(Victoria*, Tempo) 도입 X — Firebase Crashlytics + Analytics + AWS CloudWatch로 대체 | 모바일 앱 + 단일 API 백엔드에 자체 스택은 과함. |
| 2026-05-23 | shelf/victoria-stack references 제외, riverpod/freezed/dio는 *향후 마이그레이션* 컨텍스트로 등록 | 현재 stack(`http`, `provider`, `ChangeNotifier`, 수동 fromMap) 반영. |
| 2026-05-23 | 기존 `.claude/settings.local.json`의 allow 목록은 그대로 유지, hooks만 신규 추가                | 사용자 워크플로(playwright MCP, IAP 디버그 curl 등) 보존. |
| 2026-05-23 | `tool/check_layers.dart`, `tool/check_one_domain.dart`는 향후 작업 — tech-debt 등록             | melos 없이 단일 패키지에서 작동하도록 변형 필요. |

## Risks & open questions

1. ~~기존 `CLAUDE.md`의 출시 운영 메모(빌드, IAP, 플랫폼 gotchas)를 어디로 옮길지?~~
   **Decided 2026-05-23**: 새 CLAUDE.md에 "운영 노트" 섹션으로 보존 + docs/RELEASE_PREP.md 링크.
2. self-review hook이 너무 공격적이면 일상 대화를 막을 수 있음.
   **Decided 2026-05-23**: 매 turn이 아니라 *코드 변경이 있는 turn*에만 적용
   (transcript에 `Write`/`Edit` tool 사용이 있을 때만 enforce). 다만 단순화를
   위해 일단은 모든 Stop에 enforce, 너무 많이 막히면 완화 (tech-debt 등록).
3. `flutter analyze`가 현재 clean하지 않을 수 있음 — bootstrap 마지막에 확인.

## Progress log

- 2026-05-23 08:30  Phase A — 8개 핵심 docs 완료.
- 2026-05-23 08:44  Phase B — design-docs 4개 완료.
- 2026-05-23 08:45  Phase C — exec-plans 스켈레톤 + 본 plan 작성.
- 2026-05-23 08:47  Phase D — product-specs 9개 완료 (index + 8 도메인).
- 2026-05-23 08:51  Phase E — references 13개 완료 (현재 + 향후 마이그레이션).
- 2026-05-23 08:53  Phase F — .claude/agents 8개 완료.
- 2026-05-23 08:55  Phase G — .claude/skills 5개 완료.
- 2026-05-23 08:56  Phase H — hooks 4개 + settings.json 완료. 기존 settings.local.json 보존.
- 2026-05-23 08:57  Phase I — CLAUDE.md 재작성 완료 (98줄, knowledge tree + 운영 노트 보존).
- 2026-05-23 09:00  Phase J — flutter analyze clean. 모든 Phase 완료.

## Success criteria

- [x] `docs/` 아래 harness 구조 미러링 완료 (ARCHITECTURE, DESIGN, FLUTTER, RELIABILITY, SECURITY, PRODUCT_SENSE, PLANS, QUALITY_SCORE + design-docs/{4} + exec-plans/{index, tech-debt-tracker, active/000} + product-specs/{index + 8 domains} + references/{13}).
- [x] `.claude/agents/`에 8개 (planner, implementer, code-reviewer, security-reviewer, taste-linter, bug-reproducer, doc-gardener, tech-debt-collector).
- [x] `.claude/skills/`에 5개 (ship-pr, drive-app, run-build, query-crashlytics, firecrawl-refresh).
- [x] `.claude/hooks/`에 4개 스크립트 (pre-block-generated, post-flutter-analyze, stop-self-review, prompt-steer-reminder).
- [x] 기존 `settings.local.json` allow 목록 보존 — 새 `settings.json`은 hooks만 정의.
- [x] `flutter analyze` clean (No issues found! 3.7s).
- [x] 출시 중인 빌드(+9 / +10) 영향 없음 — 코드 한 줄도 안 건드림.
- [x] 다음 기능 개발부터 plan-first 루프를 따를 수 있는 상태. 다음 step: `planner` 에이전트를 첫 feature plan에 사용.

이 plan은 모든 Phase가 완료되어 `completed/`로 이동 준비됨 — 다음 turn에서
사용자가 확인 후 `git mv docs/exec-plans/active/000-bootstrap-harness.md docs/exec-plans/completed/`.
