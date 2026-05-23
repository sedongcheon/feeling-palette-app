---
title: External references (llms.txt style)
owner: harness-engineer
status: living
last_verified: 2026-05-23
---

# References

이 리포가 의존하는 외부 라이브러리·서비스의 압축 cheatsheet. 각 파일은
`llms.txt` 정신을 따른다 — 에이전트가 라이브러리를 만지는 코드를 쓰기 전
30초 안에 읽을 수 있는 빠른 브리핑.

## Catalog

### 현재 사용 중

| Reference                       | Updated     |
|---------------------------------|-------------|
| [dart](dart.md)                 | 2026-05-23  |
| [flutter](flutter.md)           | 2026-05-23  |
| [http](http.md)                 | 2026-05-23  |
| [provider](provider.md)         | 2026-05-23  |
| [sqflite](sqflite.md)           | 2026-05-23  |
| [firebase](firebase.md)         | 2026-05-23  |
| [in_app_purchase](in_app_purchase.md) | 2026-05-23 |
| [google_mobile_ads](google_mobile_ads.md) | 2026-05-23 |
| [l10n](l10n.md)                 | 2026-05-23  |

### 향후 마이그레이션 (참고)

| Reference                       | Updated     | 도입 plan |
|---------------------------------|-------------|-----------|
| [dio](dio.md)                   | 2026-05-23  | tech-debt: dio-migration |
| [freezed](freezed.md)           | 2026-05-23  | tech-debt: freezed-migration |
| [riverpod](riverpod.md)         | 2026-05-23  | tech-debt: riverpod-migration |

## Hygiene

- 가능한 곳은 자동 생성 (`tool/refresh_references.dart` 도입 시 — Firecrawl
  MCP 사용). 현재는 수동.
- `doc-gardener`는 `last_verified`를 확인하고 60일 이상 되면 refresh 요청.
- 새 외부 라이브러리 도입은 `docs/design-docs/dep-<pkg>.md` 노트 + 여기에
  reference 1개 추가가 의무.
