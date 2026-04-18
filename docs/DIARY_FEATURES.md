# 일기 기능 가이드 (하루 여러 기록 · AI 분석 한도)

하루에 여러 일기를 자유롭게 작성할 수 있고, AI 분석은 **일기별 3회** + **하루 총 10개 기록**까지만 가능합니다.

---

## 1. 동작 개요

### 하루 여러 기록
- 홈 화면 상단 작성 영역에서 "기록 추가" 버튼으로 **새 일기 생성** (편집 아님)
- 기존 일기는 각 카드의 수정 아이콘으로 인라인 편집
- 삭제는 각 카드의 휴지통 아이콘에서 개별적으로
- 기존 데이터(하루 1개 구조)는 **마이그레이션 없이 그대로 유지** — 싱글 엔트리로 표시되고, 그 뒤로 새 기록을 추가하면 복수가 됨

### AI 분석 한도
| 한도 종류 | 값 | 상수 |
|-----------|-----|------|
| 일기별 분석 횟수 | 3회 | `kMaxAnalysisCount` |
| 하루에 분석된 일기 개수 | 10개 | `kMaxDailyAnalyzedEntries` |

- **일기별 3회**: 한 일기에 대해 최대 3번까지 분석 실행 가능. 내용 수정 시, 남은 횟수가 있으면 이전 분석 결과가 초기화되어 재분석 가능.
- **하루 10개**: 오늘 **이미 분석된 일기 수**가 10개에 도달하면, 아직 분석 안 된 새 일기의 분석 버튼이 비활성화. 이미 분석된 일기의 **재분석은 영향 없음** (이미 카운트 1을 차지 중).
- **카운트 리셋**: 자정 넘어가면 `todayEntries`가 새 날짜 기준으로 필터링되어 자동 리셋. DB에 별도 테이블/컬럼 없음 (파생값).
- **삭제 시 카운트 감소**: 분석된 일기를 삭제하면 `todayAnalyzedCount`가 자동 감소 (파생값이므로).

---

## 2. 화면별 동작

### 홈 (`home_screen.dart`)
- 상단: 작성 영역 ("기록 추가" 버튼)
- 하단: "오늘의 기록 N개" 헤더 + `AI 분석 X/10` 배지 (한도 도달 시 빨간색)
- 아래: 오늘 기록 리스트 (`TodayEntryCard` × N, 최신이 위)

### 캘린더 (`calendar_screen.dart`)
- 각 날짜 셀 색상 = 그 날의 **감정 점수 평균** 기준 대표 감정 색
- 2개 이상 기록된 날은 우측 상단에 개수 배지
- 날짜 선택 시 아래에 그 날의 모든 일기를 **최신순**으로 표시

### 통계 (`stats_screen.dart`)
- 모든 집계가 **"일" 단위** (하루 평균 기준)
- 도넛/Top3/월간 요약: 하루를 1개 단위로 카운트, 대표 감정은 그날 분석된 일기들의 평균 기준
- 월간 요약에 "N일 중 · 총 M개 기록" 형태로 개수 병기

### 타임라인 (`timeline_screen.dart`)
- 일기 단위로 개별 나열 (한 날짜에 여러 개면 각각 항목으로)
- 날짜 + 작성 시간 (`6월 5일 월요일 · 오후 3:42`) 표시
- 항목 탭 → `DiaryDetailScreen(entryId: ...)` (id 기반)

---

## 3. 주요 파일

### 모델 / 집계
- `lib/models/diary.dart`
  - `DiaryEntry` — id, date, content, analysisCount 등
  - `kMaxAnalysisCount`, `kMaxDailyAnalyzedEntries` 상수
  - `groupEntriesByDate(entries)` — 날짜별 리스트 맵 (createdAt ASC)
- `lib/constants/emotions.dart`
  - `DayAggregate.fromEntries(date, entries)` — 분석된 일기들의 감정 점수를 평균내서 대표 감정/색 산출

### DB / DAO
- `lib/db/database.dart` — `AppDatabase`, `wipe()` 지원
- `lib/db/diary_dao.dart` — `findById`, `findAllByDate`, `findByMonth`, `findAll`

### Provider
- `lib/providers/diary_provider.dart`
  - `todayEntries` / `monthEntries` / `timelineEntries`
  - `todayAnalyzedCount`, `dailyAnalysisLimitReached` (파생 getter)
  - `createDiary(content)` — 항상 새 entry 생성
  - `updateDiary(id, content)` — 편집
  - `applyAnalysis(id, ...)` — 분석 결과 반영 (+ 방어 가드)
  - `removeDiary(id)`, `clearCache()`
  - `DailyAnalysisLimitException` — provider 단에서 한도 초과 시 throw

### 위젯
- `lib/widgets/today_entry_card.dart` — 각 일기 카드 (view/edit/analyze/delete 자체 관리)
- `lib/widgets/diary_detail_card.dart` — 읽기 전용 상세 카드 (날짜 + 시간 포함)
- `lib/widgets/emotion_result_card.dart` — 감정 분석 결과 표시
- `lib/widgets/weekly_line_chart.dart` — `DayAggregate` 리스트를 선 그래프로

---

## 4. 데이터 모델

### DB 스키마 (`diary_entries`)
```sql
CREATE TABLE diary_entries (
  id TEXT PRIMARY KEY NOT NULL,
  date TEXT NOT NULL,               -- YYYY-MM-DD
  content TEXT NOT NULL,
  primary_emotion TEXT NOT NULL,
  emotions_json TEXT NOT NULL,
  ai_comment TEXT NOT NULL DEFAULT '',
  color TEXT NOT NULL DEFAULT '#9CA3AF',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  analysis_count INTEGER NOT NULL DEFAULT 0
);
```
- `date`에 **UNIQUE 제약 없음** — 같은 날짜의 여러 row 허용
- `id`가 PK — `findById`, `applyAnalysis`, `updateDiary`, `removeDiary` 모두 id 기반

### DayAggregate 계산
```
분석된 일기만 필터 (aiComment.isNotEmpty)
N = 분석된 개수
각 감정 t에 대해:
  avg(t) = sum(emotions.scoreOf(t)) / N
primary = argmax(averaged)
color = emotionInfoOf(primary).hex
```

---

## 5. 주요 흐름

### 새 일기 저장
1. 홈 작성 영역에 입력 후 "기록 추가" 클릭
2. `DiaryProvider.createDiary(content)` — 새 id 생성, DB insert
3. `_todayEntries`, `_monthEntries`, `_timelineEntries` 캐시 업데이트
4. UI 리렌더 (리스트에 새 카드 추가)

### 기존 일기 분석
1. 카드의 "AI 감정 분석" 버튼 클릭
2. `entry.canAnalyze && !dailyBlocked` 체크 (UI 레벨)
3. `EmotionAnalyzer.analyze(content)` → API 호출
4. `DiaryProvider.applyAnalysis(...)` — `analysisCount++`, `aiComment`/`emotions`/`color` 저장
5. `DailyAnalysisLimitException` 발생 시 스낵바로 안내

### 기존 일기 수정 → 재분석
1. 카드의 수정 아이콘 → 인라인 텍스트필드 편집
2. "저장" → `DiaryProvider.updateDiary(id, content)`
3. 내용 변경 + 남은 분석 횟수 있음 → 기존 분석 결과(`aiComment`, `emotions`, `color`) **자동 초기화** → 다시 분석 버튼 노출
4. 내용 변경 + 3회 다 씀 → 기존 분석 결과 유지, 스낵바로 안내 (`analysisLocked: true`)

---

## 6. 커스터마이징

| 변경 내용 | 위치 |
|-----------|------|
| 일기별 분석 횟수 | `diary.dart` `kMaxAnalysisCount` |
| 하루 분석 한도 | `diary.dart` `kMaxDailyAnalyzedEntries` |
| 캘린더 대표 감정 계산 방식 | `emotions.dart` `DayAggregate.fromEntries` |
| 타임라인 날짜/시간 포맷 | `timeline_screen.dart` `_formatDateTime()` |
| 분석 호출량 기준(엔트리 수 → 호출 수)으로 전환 | Provider의 `todayAnalyzedCount`를 `sum(analysisCount)`로 교체 |

---

## 7. 엣지 케이스 / 주의

- **기존 데이터 호환**: 하루 1개로 작성된 옛 데이터는 리스트에 1개짜리로 표시. 그 위에 새 기록 추가하면 자연스럽게 복수화.
- **백업 / 복원**: `BackupService`는 `id` 기준 upsert라 복수 엔트리 호환됨. 별도 수정 불필요.
- **AI 서버 인증**: 현재 `EmotionAnalyzer`는 `Authorization` 헤더 없이 호출. 서버 쪽에서 401을 주면 분석 버튼이 에러 다이얼로그로 이어짐. 서버 인증을 다시 붙이면 `emotion_analyzer.dart`의 `headers`에 토큰 추가 필요 (토큰은 하드코딩 금지 — `String.fromEnvironment` + `--dart-define-from-file` 사용).
- **카운트 저장 방식**: "오늘 분석 개수"는 **DB/스토리지에 따로 저장하지 않음**. `todayEntries.where((e) => e.analysisCount > 0).length`로 매번 계산. 따라서 자정/삭제 등 모든 상태 변화가 자동 반영되지만, `loadTodayEntries()`가 안 불리면 값이 stale해질 수 있음 (홈 탭 진입 시 자동 호출됨).
