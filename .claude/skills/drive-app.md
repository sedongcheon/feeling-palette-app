---
name: drive-app
description: Drive the running Feeling Palette app from an agent — navigate, snapshot widget tree, take screenshots, capture logs. Uses xcrun simctl / adb screencap; integration_test + patrol when MCP unavailable.
status: living
last_verified: 2026-05-23
---

# Skill: drive-app (Feeling Palette)

Flutter 앱이 실제로 무엇을 하는지 *볼* 필요가 있을 때 — 버그 재현, UX 변경
검증, PR용 스크린샷 캡처, 새 시나리오 스크립팅.

## 사전 조건

- `.env.json` 존재 (API key 등).
- Android: `adb` 사용 가능, 디바이스 연결됨.
  ```bash
  export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH"
  adb devices
  ```
- iOS: Xcode 설치, simulator 부팅 가능 또는 실기기 등록.

## 세 가지 타깃 모드

### A. Android (실기기 또는 emulator)

```bash
# 디바이스 확인
flutter devices

# 실행
flutter run -d <device-id> --dart-define-from-file=.env.json

# 스크린샷 (실기기)
adb -s <device-id> shell screencap -p /sdcard/screen.png
adb -s <device-id> pull /sdcard/screen.png ./screen.png

# 로그 tail
adb -s <device-id> logcat -s flutter
```

### B. iOS simulator

```bash
# 부팅된 sim 확인
xcrun simctl list devices booted

# 실행
flutter run -d <sim-id> --dart-define-from-file=.env.json

# 스크린샷
xcrun simctl io booted screenshot /tmp/sim-screen.png
sips -g pixelWidth -g pixelHeight /tmp/sim-screen.png

# 로그 tail
xcrun simctl spawn booted log stream --predicate 'process == "Runner"'
```

### C. iOS 실기기 (실기기 IAP/광고 테스트용)

```bash
flutter run -d <device-id> --dart-define-from-file=.env.json
# 스크린샷은 사용자가 직접 (시뮬레이터 한정 자동화 가능, 실기기는 수동)
```

## 사용자 vs 에이전트 분담

[feedback_screenshot_capture 메모리]: 사용자가 메뉴 이동, Claude가
`xcrun simctl io` / `adb screencap`으로 직접 캡처.

- **Claude가**: 스크린샷 명령 실행, 로그 분석, integration_test 작성.
- **사용자가**: 시뮬레이터/디바이스의 메뉴 탭/스와이프 (자동화하지 말 것 —
  의도하지 않은 상태로 가기 쉬움).

## 매 run마다 캡처할 것

사용자가 "무엇을 봤어?"라고 물으면 다음을 포함:

1. 이동한 라우트 (예: `/timeline`, `/settings`, `/stats`).
2. 1-3 문장으로 가시 상태 요약.
3. `flutter logs` 또는 logcat의 에러.
4. 스크린샷 경로.

## 보고

step이 실패했을 때 **무지성 재시도 금지**. 다음을 먼저 확인:

- API 호출이 실패했나? → `curl` 직접 호출로 백엔드 확인.
- Crashlytics에 새 issue 있나? → Firebase Console.
- ARB 누락? → 영문/한글 빈 문자열 노출.

대부분의 "버튼이 안 먹어요" 보고는 클라이언트 버그가 아니라 서버 4xx/5xx.

## 향후 (integration_test)

`integration_test/` 인프라가 도입되면 (tech-debt):

```bash
flutter test integration_test/<story>_test.dart -d <device-id>
```

각 파일은 `docs/product-specs/<domain>.md`의 한 user story에 대응.
role+name `Semantics` finder 사용, widget-type-only finder 회피.

iOS 권한 다이얼로그, native picker, push notification은 `patrol` 필요
(`docs/references/patrol.md` 도입 시).
