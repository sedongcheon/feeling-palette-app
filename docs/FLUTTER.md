---
title: Flutter conventions
owner: harness-engineer
status: living
last_verified: 2026-05-23
---

# Flutter

Feeling Palette는 Flutter stable, Dart 3.x로 빌드되는 모바일 앱 (Android·iOS).
웹/데스크톱은 빌드는 가능하지만 출시 타깃이 아님.

## Stack

| 영역             | 현재                              | 향후 마이그레이션 방향                |
|------------------|-----------------------------------|---------------------------------------|
| Routing          | `Navigator 1.0` (push/pop)        | `go_router` (deep link, redirect)     |
| 상태 관리        | `provider` + `ChangeNotifier`     | `flutter_riverpod` (AsyncNotifier)    |
| HTTP             | `http` 패키지                     | `dio` (interceptor, 타임아웃 일원화)  |
| Codegen          | 없음 (수동 fromMap/toMap)         | `build_runner` + `freezed` + `json_serializable` |
| 로컬 DB          | `sqflite` (직접 SQL)              | `drift` (타입 안전)                   |
| Secure storage   | `flutter_secure_storage` (5s/3s 타임아웃, Samsung issue) | 동일 |
| 광고             | `google_mobile_ads`                | 동일 |
| IAP              | `in_app_purchase`                  | 동일 |
| 푸시·크래시      | `firebase_messaging`, `firebase_crashlytics` | 동일 |
| 다국어           | `flutter_localizations` + ARB (`flutter gen-l10n`) | 동일 |
| 테스트           | `flutter_test`                     | + `integration_test`, `patrol` (필요 시) |

## 모듈 형태 (per domain — 목표)

```
lib/
  models/<name>.dart            # types (immutable)
  constants/<name>_config.dart  # config
  db/<name>_dao.dart            # repo
  services/<name>_service.dart  # service (의존성을 인자로)
  providers/<name>_provider.dart # runtime (ChangeNotifier/AsyncNotifier)
  screens/<name>_screen.dart    # ui — 단일 화면
  widgets/<name>_*.dart         # ui — 재사용 위젯
```

## 규칙

1. UI(`screens/`, `widgets/`)는 `service` 또는 `repo`를 **직접 import 금지**.
   provider/notifier를 통해서만 접근.
2. cross-widget 상태는 ChangeNotifier(현재) / Riverpod AsyncNotifier(향후)로
   관리. `setState`는 한 위젯 안의 로컬 상태에만.
3. 위젯이 `await http.get(...)` / `await dio.get(...)`을 직접 호출 금지 —
   항상 provider/notifier를 거친다. 캐싱·재시도·에러 상태는 거기서 관리.
4. 모든 async 위젯은 **loading**과 **error** 상태를 표시한다. spinner만으로
   끝내지 말고 — 빈 상태 메시지, retry 액션 포함.
5. 인증/잠금 gate는 `Navigator.pushReplacement` 또는 (향후) `go_router`의
   `redirect`로. `build()` 안에서 `if (user == null) Navigator.push(...)` 금지.
6. 모든 위젯은 happy-path 위젯 테스트 1개 + boundary 테스트 1개 이상.
7. `const` 생성자를 가능한 모든 곳에. analyzer가 권장.

## 다국어 (l10n)

- 템플릿: `lib/l10n/app_ko.arb` (ko가 마스터)
- 보조: `lib/l10n/app_en.arb`
- `l10n.yaml`이 설정, `flutter gen-l10n` 또는 `flutter run/build`로
  `AppLocalizations` 재생성.
- 새 키 추가 후 build 한 번 돌려서 코드 생성 확인.
- API에 전달할 locale은 `lib/services/api_locale.dart` 헬퍼 사용 — 백엔드가
  `ko` / `en`만 인식.

## 접근성

- 모든 인터랙티브 위젯에 `Semantics` 라벨.
- 색만으로 신호를 주지 않는다 — 아이콘/텍스트 병기.
- Focus 순서는 의도된 흐름을 따른다.

## 성능

- 페이지 전환 → 첫 콘텐츠 표시: **300ms** p95 (mid-tier Android).
- 프레임 예산: 60fps 기준 평균 **16ms**.
- 가능한 모든 곳에 `const` 생성자.
- 큰 리스트는 `ListView.builder` (전체 빌드 금지).
- 광고·IAP·Firebase 초기화는 `main.dart`에서 비동기로, 첫 프레임을 막지 않게.

## 플랫폼 특이사항

- **Android 15 / SDK 35**: edge-to-edge 필수. `SystemUiOverlayStyle`에서
  statusBar/navigationBar 색상 필드는 비워둠 (deprecated 회피).
- **iOS**: `flutter build ipa` 전 Xcode에서 Team 한 번 지정 (인증서 생성).
- **Samsung Android**: secure storage 무한 로딩 회피용
  `_init: 5s`, `read: 3s` 타임아웃 — `lib/services/auth_service.dart`.

## 빌드 명령

```
flutter pub get
flutter run --dart-define-from-file=.env.json
flutter build apk --release --dart-define-from-file=.env.json
flutter build appbundle --release --dart-define-from-file=.env.json
flutter build ipa --release --dart-define-from-file=.env.json
flutter gen-l10n
flutter analyze
flutter test
```

API 키·민감 값은 **반드시** `.env.json` (gitignored). 하드코딩 금지.
