---
title: Auth & App Lock — product spec
owner: harness-engineer
status: living
last_verified: 2026-05-23
domain: auth / app_lock
---

# Auth & App Lock

Firebase Auth (Google SSO) + **옵션 PIN 잠금**.
PIN 존재 여부 = 잠금 활성 여부 (별도 flag 키 없음).

## User stories

1. 신규 사용자는 PIN 없이 바로 앱에 진입한다.
2. 사용자는 설정 → "앱 잠금 사용" 토글로 `PinSetupScreen`에 진입해서
   4자리 PIN을 설정한다.
3. 잠금이 활성화된 상태에서 앱을 다시 열면 `LockScreen`이 뜬다.
4. 사용자는 PIN을 잊으면 설정에서 PIN을 초기화할 수 있다 (Google Drive
   백업에서 복원 또는 데이터 손실 감수).

## Out of scope

- 생체 인증 (지문/Face ID) — 향후 옵션.
- 자동 잠금 시간 설정 — 현재는 백그라운드 진입 시 무조건 잠금.

## Acceptance

- 신규 설치 후 첫 진입에서 PIN 입력 화면이 뜨지 않는다 (Play Console 검토
  통과를 위한 설계).
- PIN 설정 후 백그라운드 → 포그라운드 전환 시 `LockScreen`이 뜬다.
- PIN 5회 오입력 시 30초 lockout (현재 구현 여부 확인 필요).

## Data

- secure storage 키 `pin` — 사용자 PIN 4자리.
- **TODO (tech-debt)**: PIN이 평문 저장이면 SHA-256 + salt로 해시화.

## Non-functional

- secure storage 호출 타임아웃:
  - `_init`: 5s
  - `read`: 3s
  - (Samsung 기기 무한 로딩 회피 — `docs/APP_LOCK.md`)

## 관련

- [docs/APP_LOCK.md](../APP_LOCK.md) — 옵션 잠금 설계
- `lib/services/auth_service.dart`
- `lib/providers/auth_provider.dart`
- `lib/screens/{lock,pin_setup}_screen.dart`
