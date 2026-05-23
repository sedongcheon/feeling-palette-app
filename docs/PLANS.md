---
title: Exec-plan workflow
owner: harness-engineer
status: living
last_verified: 2026-05-23
---

# Plans

자명하지 않은 모든 변경은 `docs/exec-plans/active/`에 **exec-plan**으로
시작해서, 머지 후 `docs/exec-plans/completed/`로 옮긴다.

## 왜

- 명시적 plan이 context window에 있어야 에이전트가 thrash하지 않는다.
- plan은 PR 설명, 변경 로그, post-mortem의 원재료가 된다.
- 1 plan = 1 bounded change → rollback이 단순해진다.

## 파일 형태

```markdown
---
slug: <kebab>
title: <imperative>
owner: <agent-id or human>
status: pending-approval | in-progress | blocked | completed
created: YYYY-MM-DD
last_verified: YYYY-MM-DD
related: [other-plan-slugs, link-to-spec]
---

# <NNN> — Title

## Goal
한 단락으로 의도 진술.

## Phases
각 Phase = 체크박스 + verify command (예: `flutter analyze`, `flutter test`).

## Decision log
append-only 표: (날짜, 결정, 이유).

## Risks & open questions
번호 매김; 해결된 것은 `Decided <date>:` 줄로.

## Progress log
`YYYY-MM-DD HH:MM  Phase X — note`

## Success criteria
spec / 사용자 요구를 미러링한 체크리스트.
```

## 번호 매기기

`NNN-slug.md` — `NNN`은 zero-padded 3자리, monotonic 증가.
`planner` 에이전트는 `active/`와 `completed/` 둘 다 읽고 다음 번호를 고른다.

## 워크플로

1. `planner` 에이전트가 `active/` 아래 draft 생성.
2. 사람(또는 더 높은 자율 reviewer)이 승인.
3. `implementer` 에이전트가 plan을 작업하면서 **Progress log**와
   **Decision log**에 append.
4. `ship-pr` 스킬이 review + merge를 끌고 간다.
5. merge 시 plan을 `git mv`로 `completed/`로 옮기고
   [exec-plans/index.md](exec-plans/index.md)에 등록.

## Verify command 예시 (Feeling Palette)

| Phase 유형               | Verify                                                   |
|--------------------------|----------------------------------------------------------|
| 정적 분석                | `flutter analyze`                                        |
| 단위/위젯 테스트         | `flutter test`                                           |
| 빌드 가능 여부 (Android) | `flutter build apk --debug --dart-define-from-file=.env.json` |
| 빌드 가능 여부 (iOS)     | `flutter build ios --debug --no-codesign --dart-define-from-file=.env.json` |
| ARB 동기화 확인          | `flutter gen-l10n` (no diff)                             |
| 실기기 smoke             | `flutter run --dart-define-from-file=.env.json` + 시나리오 실행 |
| 광고/IAP 분기            | 디바이스에서 수동 시나리오 + 스크린샷 첨부               |

## Anti-patterns

- "TODO: fill in later" 섹션.
- 멀티 도메인 plan (쪼갠다).
- verify command 없는 Phase.
- merge 후 `completed/`로 안 옮긴 plan (gardener가 주간으로 잡는다).
- "그냥 빨리 고치자"로 plan 생략 — bug fix도 1줄짜리 plan 권장 (`active/`에).

## 모바일 출시와 연결

`pubspec.yaml`의 `version:` (`X.Y.Z+빌드`) 증가가 동반되는 plan은:

- `Phases`에 "버전 bump" 단계 명시.
- `Success criteria`에 "Play Console 또는 App Store Connect 업로드 성공"
  포함.
- merge 후 `git tag v<X.Y.Z>+<빌드>` 권장.

## 출시 검토 거부 회피

특정 빌드가 스토어 검토를 통과하기 위한 *임시* 가드(예: 앱 잠금 비활성화)는
exec-plan으로 명시적 추적:

- plan 제목: `<NNN>-store-review-<reason>`
- `Decision log`에 가드 추가 이유 + 복구 시점 기재.
- 가드 제거는 별도 plan으로 (`<NNN>-restore-<feature>`).
