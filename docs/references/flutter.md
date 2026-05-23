---
title: Flutter — quick reference
owner: harness-engineer
status: living
last_verified: 2026-05-23
upstream: https://flutter.dev
---

# Flutter (stable)

`lib/` 전체 + `apps/app`(미래).

## Build & run

```
flutter pub get
flutter run --dart-define-from-file=.env.json
flutter run -d <device-id> --dart-define-from-file=.env.json
flutter build apk --release --dart-define-from-file=.env.json
flutter build appbundle --release --dart-define-from-file=.env.json
flutter build ipa --release --dart-define-from-file=.env.json
flutter test
flutter analyze
flutter gen-l10n
flutter devices
flutter clean
```

API 키·민감값은 **반드시** `--dart-define-from-file=.env.json`로 주입. 하드코딩 금지.

## 프로젝트 레이아웃 (현재)

```
lib/
  main.dart              # entry — Firebase, Crashlytics, IAP, Ads 부트스트랩
  firebase_options.dart  # generated — 손편집 금지
  constants/             # config 계층
  models/                # types 계층
  db/                    # repo 계층 (sqflite)
  services/              # service 계층 (business rules)
  providers/             # runtime 계층 (ChangeNotifier)
  screens/               # ui 계층 (full-screen widgets)
  widgets/               # ui 계층 (reusable widgets)
  l10n/                  # ARB + generated AppLocalizations
test/                    # 단위/위젯 테스트 (현재 빈 디렉토리 — tech-debt)
```

## 컨벤션

- 위젯 클래스는 모두 `final` + `const` 생성자 (필드 타입이 허용하는 한).
- `MaterialApp` (현재) 또는 `MaterialApp.router` (go_router 마이그레이션 후).
- `ProviderScope` (riverpod 마이그레이션 후) 또는 `MultiProvider` (현재).
- 비즈니스 위젯은 `screens/`, `widgets/`에 — `apps/app`(미래)는 라우트 조립만.

## 자주 쓰는 idiom

```dart
// const everywhere
const SizedBox(height: 16),
const Icon(Icons.favorite),

// builder for variable children
ListView.builder(
  itemCount: diaries.length,
  itemBuilder: (context, i) => DiaryCard(diary: diaries[i]),
);

// localization
final l = AppLocalizations.of(context)!;
Text(l.diaryEmptyState);
```

## 금지

- `print()` / `debugPrint()` 비-test 소스에서.
- 위젯 안에서 `await http.get(...)` 직접 호출 — provider/notifier 통과.
- `setState` cross-route 상태 공유.
- 색상만으로 의미 전달 (접근성).
