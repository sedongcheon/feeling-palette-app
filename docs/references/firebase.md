---
title: Firebase — quick reference
owner: harness-engineer
status: living
last_verified: 2026-05-23
upstream: https://firebase.flutter.dev
---

# Firebase (Auth, Crashlytics, Analytics, Messaging)

`firebase_options.dart`는 `flutterfire configure` 산출물 — **손편집 금지**.

## 부트스트랩 (`main.dart`)

```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

FlutterError.onError = (details) {
  if (kReleaseMode) FirebaseCrashlytics.instance.recordFlutterFatalError(details);
};
PlatformDispatcher.instance.onError = (error, stack) {
  if (kReleaseMode) FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

debug/profile 빌드는 Crashlytics 미수집.

## Auth (Google Sign-In)

```dart
final user = await FirebaseAuth.instance.signInWithCredential(googleCredential);
```

세션은 SDK가 관리. 토큰은 메모리에만 — `flutter_secure_storage`에 보관 금지
(SDK가 알아서).

## Crashlytics

```dart
try {
  await dangerousCall();
} catch (e, stack) {
  await FirebaseCrashlytics.instance.recordError(
    e, stack,
    reason: 'emotion_analysis.call',
    information: ['locale: $locale'],
  );
  rethrow;
}
```

- `recordError(e, stack, reason: ...)` — non-fatal
- `recordFlutterFatalError(details)` — fatal
- `log(msg)` — breadcrumb (release에서만 의미)
- `setUserIdentifier(uid)` — 사용자 식별 (PII 주의)
- `setCustomKey(key, value)` — 컨텍스트

## Analytics

```dart
await FirebaseAnalytics.instance.logEvent(
  name: 'diary_saved',
  parameters: {'has_emotion': hasEmotion},
);
```

사용자 이벤트 funnel에 사용. PII 금지 (이메일, content 본문 등).

## 권장 이벤트 (Feeling Palette)

| 이벤트                | 파라미터                                  | 트리거                       |
|-----------------------|-------------------------------------------|------------------------------|
| `diary_saved`         | `has_emotion: bool`                       | 일기 저장 성공               |
| `emotion_analyzed`    | `emotion: string`, `latency_ms: int`      | 분석 응답 성공               |
| `iap_purchase_start`  | `product_id: string`                      | 구매 흐름 시작               |
| `iap_purchase_done`   | `product_id: string`                      | 구매 완료                    |
| `ad_loaded`           | `slot: string`                            | 광고 로드 성공               |
| `backup_started`      | -                                         | "지금 백업" 탭               |
| `backup_done`         | `bytes: int`, `latency_ms: int`           | 백업 완료                    |

## 규칙

- `firebase_options.dart` 손편집 금지 (PreToolUse hook으로 차단).
- 로그/이벤트에 `password|token|secret|key|cookie|authorization|pin` 필드 금지.
- 사용자 ID는 Firebase UID 사용 — 이메일 직접 사용 금지.
