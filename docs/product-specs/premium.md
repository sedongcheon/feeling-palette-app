---
title: Premium (IAP) — product spec
owner: harness-engineer
status: living
last_verified: 2026-05-23
domain: premium
---

# Premium (In-App Purchase)

사용자가 한 번 결제하면 광고 제거 + (향후) 프리미엄 인사이트 잠금 해제.
Google Play Billing / Apple StoreKit 둘 다 활성화.

## User stories

1. 사용자는 설정 또는 광고에 노출된 진입점에서 프리미엄 구매를 한다.
2. 구매 후 광고가 즉시 사라진다.
3. 사용자는 기기 변경/재설치 후 "구매 복원"으로 프리미엄 상태를 되찾는다.

## Out of scope

- 구독 (subscription) — 현재는 일회성 구매(non-consumable).
- 환불 처리는 스토어에 위임 (자체 UI 없음).

## Acceptance

- 구매 흐름 시작 → 완료까지 70%+ funnel (`Firebase Analytics`로 측정).
- 구매 직후 광고가 동일 세션에서 사라진다.
- 복원 흐름은 설정 화면에서 항상 접근 가능.
- iOS/Android 동일 활성화 (`docs/design-docs/core-beliefs.md` #8).

## 제품 ID

- (현재 product id는 `docs/IAP_SETUP.md` 참조 — 여기서는 link만)

## Non-functional

- 구매 검증은 클라이언트에서 신뢰 + 서버 검증 추가는 향후 작업 (tech-debt).
- 구매 상태는 secure storage 또는 sqflite에 캐시 (오프라인에서도 광고 제거 유지).

## Open questions

- 가격 책정: 현재는 단일 가격 (`docs/IAP_SETUP.md` 확인). 지역별 가격 differ는
  스토어가 자동 처리.
- 환불 후 권한 회수 정책: 현재 미적용. 사용자 불만 발생 시 검토.

## 관련

- [docs/IAP_SETUP.md](../IAP_SETUP.md) — 스토어 설정 가이드
- [docs/RELEASE_PREP.md](../RELEASE_PREP.md) — 출시 체크리스트
