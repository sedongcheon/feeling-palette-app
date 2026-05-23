---
title: Riverpod — quick reference (향후 마이그레이션)
owner: harness-engineer
status: living
last_verified: 2026-05-23
upstream: https://riverpod.dev
---

# flutter_riverpod (향후 도입)

> **현재 미도입.** state는 `provider` + `ChangeNotifier`. tech-debt:
> `riverpod-migration`.

도입 시 `@riverpod` code-gen flavour + `riverpod_generator`.

## 도입 시 패턴

```dart
@riverpod
class DiaryController extends _$DiaryController {
  @override
  Future<List<Diary>> build() async => ref.read(diaryDaoProvider).list();

  Future<void> create(DiaryDraft draft) async {
    final dao = ref.read(diaryDaoProvider);
    final saved = await dao.insert(draft);
    state = AsyncData([saved, ...?state.valueOrNull]);
  }

  Future<void> delete(DiaryId id) async {
    await ref.read(diaryDaoProvider).delete(id);
    state = AsyncData([...?state.valueOrNull?.where((d) => d.id != id)]);
  }
}
```

```dart
@riverpod
DiaryDao diaryDao(DiaryDaoRef ref) => DiaryDao();
```

## 규칙

- Controllers는 `lib/<domain>/providers/` (또는 `domains/<n>/ui/lib/src/controllers/`).
- 로딩이 있는 건 `AsyncNotifier` (not `StateNotifier`).
- 도메인 간 상호 참조 금지 — service/api 통과.
- mutation 후 `ref.invalidate(...)`로 의존하는 provider 재계산.

## ChangeNotifier에서 마이그레이션

도메인당 1 PR로:

1. `pubspec.yaml`에 `flutter_riverpod`, `riverpod_generator`,
   `riverpod_annotation` 추가.
2. `MultiProvider` → `ProviderScope`로 교체.
3. 한 ChangeNotifier를 `AsyncNotifier`로 재작성.
4. 사용 위젯 `context.watch<X>()` → `ref.watch(xProvider)`.
5. 통과 후 다음 도메인.

`diary` 도메인부터 (가장 잘 보이는 경로).

## 위젯에서 사용

```dart
final asyncDiaries = ref.watch(diaryControllerProvider);

asyncDiaries.when(
  data: (diaries) => DiaryList(diaries: diaries),
  loading: () => const DiarySkeleton(),
  error: (e, s) => ErrorView(error: e, onRetry: () => ref.invalidate(diaryControllerProvider)),
);
```

AsyncValue가 loading/error 상태를 *값으로* 들고 있어, 별도 `_loading` flag가
사라진다.
