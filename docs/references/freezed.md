---
title: freezed — quick reference (향후 도입)
owner: harness-engineer
status: living
last_verified: 2026-05-23
upstream: https://pub.dev/packages/freezed
---

# freezed + json_serializable (향후 마이그레이션)

> **현재 미도입.** boundary 파싱은 수동 `fromMap`/`fromJson`으로 처리 중.
> tech-debt: `freezed-migration`.

## 도입 시 패턴

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'emotion_analysis.freezed.dart';
part 'emotion_analysis.g.dart';

@freezed
class EmotionAnalysis with _$EmotionAnalysis {
  const factory EmotionAnalysis({
    required String emotion,
    required double score,
    required List<String> keywords,
  }) = _EmotionAnalysis;

  factory EmotionAnalysis.fromJson(Map<String, dynamic> json) =>
      _$EmotionAnalysisFromJson(json);
}
```

annotation 변경 후:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Branded id (Dart 3.3+)

```dart
extension type DiaryId(int value) {
  factory DiaryId.parse(int raw) {
    if (raw <= 0) throw FormatException('invalid DiaryId: $raw');
    return DiaryId(raw);
  }
}
```

`extension type`은 zero-cost wrapper — 컴파일 타임 type-safe, 런타임 비용 X.

## 규칙

- 같은 shape는 하나의 스키마. 복사 금지.
- `*.g.dart` / `*.freezed.dart` 손편집 금지 (PreToolUse hook).
- 에러 컨텍스트가 필요하면 `tryParse` variant + `Result<T, E>`.

## 도입 절차 (도메인당 1 PR)

1. `pubspec.yaml`에 `freezed`, `freezed_annotation`, `json_annotation`,
   `build_runner`, `json_serializable` 추가.
2. 하나의 도메인 model을 freezed로 재작성.
3. `dart run build_runner build` 1회.
4. service/repo에서 수동 `fromMap`/`fromJson` 호출을 새 factory로 교체.
5. 테스트 통과 → merge → 다음 도메인.

전체 도메인 끝나면 `analysis_options.yaml`에 `strict-casts: true`,
`strict-inference: true` 추가.
