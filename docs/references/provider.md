---
title: provider + ChangeNotifier — quick reference
owner: harness-engineer
status: living
last_verified: 2026-05-23
upstream: https://pub.dev/packages/provider
---

# provider (현재 state mgmt)

Feeling Palette는 `provider` + `ChangeNotifier` 기반. 향후 `flutter_riverpod`
+ `AsyncNotifier`로 마이그레이션 예정 (tech-debt: riverpod-migration).

## 패턴

```dart
// providers/diary_provider.dart
class DiaryProvider extends ChangeNotifier {
  final DiaryDao _dao;
  DiaryProvider(this._dao);

  List<Diary> _diaries = [];
  List<Diary> get diaries => List.unmodifiable(_diaries);

  bool _loading = false;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _diaries = await _dao.list();
    _loading = false;
    notifyListeners();
  }

  Future<void> create(Diary draft) async {
    final saved = await _dao.insert(draft);
    _diaries = [saved, ..._diaries];
    notifyListeners();
  }
}
```

```dart
// main.dart 또는 app 루트
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => DiaryProvider(DiaryDao())),
    ChangeNotifierProvider(create: (_) => AuthProvider()),
  ],
  child: MyApp(),
);
```

```dart
// 위젯에서
final provider = context.watch<DiaryProvider>();
final diaries = provider.diaries;
final loading = provider.loading;

// 또는 mutation 호출 (rebuild 안 함)
context.read<DiaryProvider>().create(draft);
```

## 규칙

- ChangeNotifier는 *runtime 계층*. service나 DAO를 직접 들고 있되, 외부에는
  immutable view만 노출 (`List.unmodifiable`).
- `notifyListeners()`는 상태 변경 직후 1회. 루프 안에서 호출 금지.
- Widget의 `build()`에서 `read`만 — `watch`는 widget 전체가 rebuild되어야
  할 때만.
- 한 화면이 여러 ChangeNotifier를 쓰면 `Selector` 또는 `Consumer`로 좁힌다.

## 향후 (riverpod)

```dart
// 마이그레이션 시 — 단순 참고
@riverpod
class DiaryController extends _$DiaryController {
  @override
  Future<List<Diary>> build() async => ref.read(diaryDaoProvider).list();
}
```

`AsyncNotifier`는 loading/error 상태가 *값*으로 들어와 `_loading` 같은
flag가 사라진다. 도메인당 1 PR로 점진 마이그.
