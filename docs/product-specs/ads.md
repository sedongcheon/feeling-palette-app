---
title: Ads — product spec
owner: harness-engineer
status: living
last_verified: 2026-05-23
domain: ads
---

# Ads (AdMob)

무료 사용자에게 광고 노출. 프리미엄 사용자에게는 절대 노출 금지.

## User stories

1. 무료 사용자가 타임라인을 스크롤하면 N개 일기마다 inline 광고 1개를 본다.
2. 무료 사용자가 일기 상세 또는 통계로 이동할 때 가끔 interstitial 광고가
   뜬다 (사용자 액션 직후가 아닌, 자연스러운 멈춤 지점에).
3. 프리미엄 사용자는 광고를 보지 않는다.

## Out of scope

- 보상형 광고 (Reward) — 향후 옵션.
- 네이티브 광고 — 현재는 배너/inline + interstitial.

## Acceptance

- AdMob fill rate > 95% (지역에 따라 다름).
- 광고 로드 실패 시 자리차지 박스 없이 자연스럽게 흐름 진행.
- 프리미엄 사용자 화면에 광고 코드 자체가 실행되지 않음 (CPU/네트워크 절약).
- 동의(consent) UMP를 통과한 사용자에게만 personalized ads, 그 외는 NPA.
- 기기 ID 광고 추적 동의는 iOS ATT + Android UMP 둘 다 처리.

## 광고 단위

- 현재 production unit id는 `lib/services/ads_service.dart` 또는
  `.env.json`에서 주입 (확인 필요).
- 테스트 모드는 `kDebugMode`일 때 또는 `--dart-define` flag로 활성화.

## 분기 정책

- iOS·Android 동일하게 활성화 (`docs/design-docs/core-beliefs.md` #8).

## Non-functional

- 광고 SDK는 `main.dart`에서 비동기 초기화 (첫 프레임 안 막음).
- 광고 노출은 타임라인 첫 페이지 로드 후, 사용자가 적어도 1번 스크롤한
  후에만 inline 시작 (입장 직후 흐림 방지).

## 관련

- [docs/ADS_PLAN.md](../ADS_PLAN.md)
- [docs/ADS_TESTING.md](../ADS_TESTING.md)
