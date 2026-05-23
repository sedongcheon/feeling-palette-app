---
title: sqflite — quick reference
owner: harness-engineer
status: living
last_verified: 2026-05-23
upstream: https://pub.dev/packages/sqflite
---

# sqflite

로컬 SQLite. 모든 일기·요약·인사이트 데이터의 진실(source-of-truth).

## 초기화

```dart
// lib/db/database.dart
class AppDatabase {
  static Database? _db;
  static Future<Database> instance() async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'feeling_palette.db');
    _db = await openDatabase(
      path,
      version: 3, // 마이그레이션 시 bump
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }
  // ...
}
```

## DAO 패턴

```dart
// lib/db/diary_dao.dart
class DiaryDao {
  Future<Diary> insert(Diary draft) async {
    final db = await AppDatabase.instance();
    final id = await db.insert('diary', draft.toMap());
    return draft.copyWith(id: id);
  }

  Future<List<Diary>> list({int limit = 100}) async {
    final db = await AppDatabase.instance();
    final rows = await db.query('diary',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(Diary.fromMap).toList(); // boundary 파싱
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance();
    await db.delete('diary', where: 'id = ?', whereArgs: [id]);
  }
}
```

## 규칙

- **반드시 parameterized**: `where: 'id = ?', whereArgs: [id]`. String 보간 금지 (SQL injection).
- 모든 row → `Model.fromMap`. raw `Map<String, Object?>`을 service에 흘리지 말 것.
- 스키마 변경은 `version` bump + `onUpgrade` 마이그레이션.
- 비가역 변경(`DROP COLUMN`, `DROP TABLE`)은 PR에서 명시적 검토.
- `await db.transaction((txn) async { ... })` — 여러 mutation은 트랜잭션.

## 마이그레이션 예시

```dart
Future<void> _onUpgrade(Database db, int from, int to) async {
  if (from < 2) {
    await db.execute('ALTER TABLE diary ADD COLUMN keywords TEXT');
  }
  if (from < 3) {
    await db.execute('CREATE TABLE weekly_insight (...)');
  }
}
```

## 향후 (drift)

`drift`는 타입 안전 + 마이그레이션 codegen 제공. 도입 시 도메인당 1 PR로
DAO만 교체 (모델 변경 없음). 현재 tech-debt에 등록 안 됨 — 우선순위 낮음.
