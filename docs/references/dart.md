---
title: Dart — quick reference
owner: harness-engineer
status: living
last_verified: 2026-05-23
upstream: https://dart.dev
---

# Dart 3.x

Feeling Palette는 Flutter stable이 묶는 Dart 버전을 따른다 (`pubspec.yaml`의
`environment: sdk:` 참조).

## 패턴

- `class X { ... }` — 일반 객체.
- `sealed class` + pattern matching → `Result<T, E>`, ADT.
- `extension type` — branded id의 zero-cost wrapper (Dart 3.3+).
- `Future<T>` — async; `Stream<T>` — events.
- `Isolate.spawn` — CPU 바운드 분리 (현재 미사용).
- `dart format` — One True Formatter (논쟁 없음).

## 자주 쓰는 idiom

```dart
// nullable + null-aware
final emotion = diary.emotion ?? 'neutral';
final score = diary.score ?? 0.0;

// pattern matching (Dart 3+)
final message = switch (status) {
  PurchaseStatus.pending => '결제 진행 중',
  PurchaseStatus.purchased => '구매 완료',
  PurchaseStatus.error => '오류',
  PurchaseStatus.restored => '복원됨',
  PurchaseStatus.canceled => '취소',
};

// collection if/for
final items = [
  if (isPremium) const PremiumBanner(),
  for (final diary in diaries) DiaryCard(diary: diary),
];
```

## 금지 패턴

- `dynamic` 변수 (즉시 type narrow 안 하는 경우).
- `as Foo` (가드 없음) — boundary 한 곳만.
- `print()` / `debugPrint()` 비-test에서.
- `// ignore: ...` analyzer 회피 (정말 필요하면 PR 본문에 사유 명시).
