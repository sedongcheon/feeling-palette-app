---
title: Product specs index
owner: harness-engineer
status: living
last_verified: 2026-05-23
---

# Product specs

도메인별 제품 스펙. 각 스펙은 그 도메인에 대한 **에이전트의 제품 브리프**다 —
사용자가 무엇을 하는지, 왜 하는지, 성공이 어떻게 생겼는지, 무엇이 범위 밖인지.
implementer agent는 exec-plan을 열기 전 이 스펙을 읽는다.

| Domain             | Spec                                                | Status  |
|--------------------|-----------------------------------------------------|---------|
| diary              | [diary.md](diary.md)                                | living  |
| emotion_analysis   | [emotion-analysis.md](emotion-analysis.md)          | living  |
| month_summary      | [month-summary.md](month-summary.md)                | living  |
| weekly_insight     | [weekly-insight.md](weekly-insight.md)              | living  |
| premium (IAP)      | [premium.md](premium.md)                            | living  |
| ads                | [ads.md](ads.md)                                    | living  |
| backup             | [backup.md](backup.md)                              | living  |
| auth / app_lock    | [auth-app-lock.md](auth-app-lock.md)                | living  |
| stats              | [stats.md](stats.md)                                | living  |

## 저자 규칙

- 스펙은 agent가 명확화 질문 없이 합리적인 구현을 만들 수 있는지로 판단된다.
- 모든 스펙은 frontmatter 보유. `last_verified`는 doc이 다시 읽혔고 여전히
  참이라고 믿어질 때마다 갱신.
- 새 도메인은 이 디렉토리에 스펙 없이 머지 불가.
