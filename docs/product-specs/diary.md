---
title: Diary — product spec
owner: harness-engineer
status: living
last_verified: 2026-05-23
domain: diary
---

# Diary

Feeling Palette의 **핵심 도메인**. 사용자가 일기를 쓰면 감정 분석이 자동
실행되고, 캘린더/타임라인/통계 화면이 이 데이터를 소비한다.

## User stories

1. 사용자는 홈 화면에서 오늘의 일기를 작성한다 (text input).
2. 작성 직후 또는 저장 시 자동으로 감정 분석이 실행되어 결과가 일기에
   첨부된다.
3. 사용자는 캘린더에서 날짜별 일기 존재 여부와 대표 감정 색상을 본다.
4. 사용자는 타임라인에서 최근 일기를 시간순으로 스크롤한다.
   광고는 N개 일기 간격으로 inline 노출 (프리미엄 제외).
5. 사용자는 특정 일기를 열어 편집하거나 삭제한다.
6. 사용자는 캘린더에서 특정 날짜를 탭하면 그 날의 일기로 이동한다.

## Out of scope (현재)

- 협업/공유.
- 첨부 파일 (이미지, 음성).
- 풍부한 텍스트(rich text) 포맷팅 — plain text만.
- 실시간 sync (현재는 단일 디바이스 + Google Drive 백업).

## Acceptance

- 모든 6개 스토리에 대해 happy path 수동 테스트 시나리오 통과 (현재
  `integration_test`는 미존재 — tech-debt).
- p95 일기 작성 → 저장 응답: 500ms 이내 (로컬 sqflite + 감정 분석은 async).
- p95 감정 분석 응답: 3s (AWS API).
- 타임라인 스크롤 16ms p95 (60fps).

## API

- AWS: `POST https://feeling-api-aws.sedoli.co.kr/api/diary/analyze`
  - Body: `{ "content": <string>, "locale": "ko" | "en" }`
  - Response: `{ "emotion": <string>, "score": <number>, "keywords": [<string>] }`

## Data

- `lib/models/diary.dart`:
  - `id` (int, autoinc)
  - `created_at` (ISO8601 string)
  - `content` (text)
  - `emotion` (string, nullable — 분석 전)
  - `score` (real, nullable)
  - `keywords` (json array string, nullable)
- `lib/db/diary_dao.dart` — sqflite DAO

## Non-functional

- 자동 저장 디바운스: 800ms (목표 — 현재 명시적 "저장" 버튼).
- 삭제는 hard delete (soft delete 미구현 — 향후 30일 휴지통은 spec 확장).
- 타임라인 광고 간격: 5개마다 1개 inline (현재 구현 기준).

## 의존성

- 감정 분석 → `domains/emotion_analysis/`
- 타임라인 광고 → `domains/ads/`
- 프리미엄 게이팅 → `domains/premium/`
- 캘린더/통계 dot color → `domains/diary/` (자체) + UI에서 색 매핑

## Open questions

- (없음 — implementer가 부딪힐 때마다 채운다)
