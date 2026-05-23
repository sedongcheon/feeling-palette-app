---
title: Emotion analysis — product spec
owner: harness-engineer
status: living
last_verified: 2026-05-23
domain: emotion_analysis
---

# Emotion analysis

일기 텍스트를 AWS 백엔드 API에 보내 감정/스코어/키워드를 받는다.
도메인 자체는 *순수 서비스*. UI 노출은 `diary`/`stats` 도메인이 담당.

## User stories

1. 사용자가 일기를 저장하면 자동으로 감정 분석이 실행되어 결과가 일기
   레코드에 저장된다.
2. 분석 실패 시 일기는 분석되지 않은 상태로 보존되고, 사용자는 나중에
   재시도할 수 있다.

## Out of scope

- 클라이언트 사이드 NLP/모델 추론.
- 다중 응답 (감정 1개 + 점수만; 다중 감정 분포는 향후).

## Acceptance

- 200 응답 → emotion/score/keywords가 모델에 저장.
- 4xx/5xx → 일기는 emotion=null로 저장. 사용자에게 silently 알림 없음 (UX
  방해 안 함).
- 타임아웃 8초 — 그 이상은 실패 처리.
- 로케일에 따라 ko / en 분기 (`lib/services/api_locale.dart`).

## API contract

- `POST /api/diary/analyze`
  - Body: `{ "content": <string, max 5000 chars>, "locale": "ko" | "en" }`
  - 200 Response:
    ```json
    {
      "emotion": "joy" | "sadness" | "anger" | "fear" | "neutral" | ...,
      "score": 0.0~1.0,
      "keywords": ["키워드1", "키워드2", ...]
    }
    ```
  - 400: malformed input
  - 401/403: (현재 미사용 — 향후 API key 도입 시)
  - 5xx: 서버 오류

## Non-functional

- p95 응답: 3s.
- 동시 호출 최대 1개 (사용자가 빠르게 여러 일기를 저장해도 큐잉).
- offline → 즉시 실패 + 일기는 emotion=null로 저장.

## 의존성

- API base URL: `lib/constants/api_endpoints.dart` (현재 하드코딩 위치 점검 필요)
- locale 결정: `Localizations.localeOf(context).languageCode`로 추출하고
  서버가 인식하는 ko/en으로 매핑.

## Open questions

- 분석 재시도 UX는 어떻게? 일기 상세 화면에 "재분석" 버튼?
  → 향후 spec 확장.
