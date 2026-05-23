---
title: Design docs index
owner: harness-engineer
status: living
last_verified: 2026-05-23
---

# Design docs

살아있는 아키텍처 결정과 그 결정을 묶는 원칙들. 각 design doc은 frontmatter가
있어 `doc-gardener`가 staleness를 표시할 수 있다.

| Slug                                                | Status | 검증 방법                                |
|-----------------------------------------------------|--------|------------------------------------------|
| [core-beliefs](core-beliefs.md)                     | living | analyzer + 수동 검토 (강제 도구는 tech-debt) |
| [self-review-checklist](self-review-checklist.md)   | living | `Stop` hook으로 강제                     |
| [boundary-parsing](boundary-parsing.md)             | living | 수동 + 향후 check_layers.dart            |

## 저자 규칙

- 모든 문서는 frontmatter: `title`, `owner`, `status`, `last_verified`.
- `status` ∈ `proposed | accepted | living | superseded`.
- `superseded` 문서는 후속 문서로 링크 필수.
- analyzer rule이나 skill을 명명하는 문서는 그 파일의 진실(source-of-truth)과
  일치해야 한다 — `doc-gardener`가 확인.

## 새로운 design doc 작성 절차

1. 결정해야 할 trade-off 또는 원칙을 한 문장으로 요약.
2. 새 파일 `<slug>.md`에 위 frontmatter + 본문 작성.
3. 본문에 다음 섹션:
   - **Why** — 이 결정이 필요한 이유
   - **Decision** — 결정 그 자체
   - **How to apply** — 코드에 어떻게 적용되는지
   - **Anti-patterns** — 이 결정을 어기는 패턴
4. 이 index 표에 한 줄 추가.
5. exec-plan이 이 doc을 참조하면 plan의 `related:` frontmatter에 slug 추가.
