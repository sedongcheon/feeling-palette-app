---
name: ship-pr
description: The Ralph Wiggum loop — plan, implement, self-review, parallel agent review (code-reviewer + security-reviewer), CI repair, squash-merge. Top-level driver for any non-trivial change.
status: living
last_verified: 2026-05-23
---

# Skill: ship-pr (Feeling Palette)

사람 없이 inner loop 없이 변경을 end-to-end로 끌고 간다.

## 입력

- 짧은 사용자 요청 또는 기존 exec-plan slug.
- 선택: `--escalate-after <N>` (default 3회 시도/실패 유형).

## 단계

### 1. Plan

이 변경에 대한 plan이 없으면:

- `planner` 에이전트를 사용자 요청 + 관련 product spec
  (`docs/product-specs/<domain>.md`)과 함께 호출.
- 출력: `docs/exec-plans/active/<NNN>-<slug>.md`.
- L2 (default) 자율 수준에서 planner의 draft를 승인된 것으로 간주.

### 2. Implement

plan의 각 Phase에 대해:

- `implementer` 에이전트를 단일 도메인으로 제한해서 호출.
- implementer는 `CLAUDE.md`, `docs/ARCHITECTURE.md`,
  `docs/design-docs/core-beliefs.md`를 읽은 후 변경.
- Phase의 `verify` 명령 실행. 실패 → § 5 참조.

### 3. Self-review

implementer는 `docs/design-docs/self-review-checklist.md`를 걸어 `SELF-REVIEW: PASS`
(또는 `FAIL — <why>`)를 print. `Stop` hook이 강제.

### 4. 병렬 agent review

두 reviewer를 동시에 spawn:

- `code-reviewer` — 정확성, 계층, 테스트, 관측성, Dart idiom.
- `security-reviewer` — 인증, parse-at-boundary, secret, pub advisory.

둘 다 `APPROVE`까지 반복 (최대 N회 escalate threshold).

### 5. CI repair

브랜치 push. CI 실패 시:

- **flake** (재시작하면 pass): `tech-debt-tracker.md`에 기록하고 계속.
- **real failure**: 실패 로그와 함께 `implementer`에게 retry 요청; 최대 N회.
- N회 후 escalate.

### 6. Merge

reviewer 둘 다 approve + CI green일 때:

- plan을 `docs/exec-plans/completed/<NNN>-<slug>.md`로 `git mv`.
- `docs/exec-plans/index.md` 갱신.
- plan title을 commit subject로 squash-merge.
- deferred된 것은 `tech-debt-tracker.md`에 append.

## Feeling Palette 컨텍스트

- 빌드/테스트 명령:
  - `flutter analyze` (정적 분석)
  - `flutter test` (단위/위젯 — 현재 미구현이 많음, tech-debt)
  - `flutter build apk --debug --dart-define-from-file=.env.json` (빌드 가능 여부)
- 출시 운영 중인 빌드(스토어 검토 중)에 영향 있는 PR은 `--escalate-after 1`로
  더 신중하게.
- ARB 변경이 있으면 `flutter gen-l10n` verify 단계 자동 포함.

## Escalation

```
ESCALATE: <one-line summary>
PR: <url-or-branch>
Plan: docs/exec-plans/active/<slug>.md
Blocker: <one paragraph>
Tried: <bullets>
Suggestion: <what the human is being asked to do>
```
