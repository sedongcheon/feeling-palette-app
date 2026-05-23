---
name: firecrawl-refresh
description: Refresh docs/references/*.md by scraping upstream URLs via the Firecrawl skill when last_verified is older than 60 days.
status: living
last_verified: 2026-05-23
---

# Skill: firecrawl-refresh

`docs/references/`를 정직하게 유지한다. `doc-gardener` 에이전트가 reference의
`last_verified`가 60일 넘었을 때 이 skill을 트리거.

## 절차

1. 문서의 frontmatter `upstream:` URL 읽기.
2. `firecrawl` skill 호출 (또는 `mcp__firecrawl__scrape`).
3. 출력을 llms.txt 스타일 cheat sheet로 distill — ~120줄 이내.
4. `last_verified`를 오늘 날짜로 bump.
5. 단일 파일 PR로 commit.

## refresh 거부 조건

- upstream URL이 화이트리스트 외 (silently scope creep 회피).
  현재 화이트리스트:
  - `https://flutter.dev`
  - `https://dart.dev`
  - `https://docs.flutter.dev`
  - `https://pub.dev/packages/*`
  - `https://riverpod.dev`
  - `https://firebase.flutter.dev`
- upstream이 4xx/5xx 반환 — tech-debt 항목 추가.

## Feeling Palette 컨텍스트

- 자주 변하는 것: Firebase SDK (`firebase_*` 패키지), `in_app_purchase` 정책.
- 안정적인 것: Dart 언어 spec, Flutter widget API.

먼저 자주 변하는 것부터 refresh.
