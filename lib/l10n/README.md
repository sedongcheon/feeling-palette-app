# l10n — Feeling Palette 다국어

ARB 파일 (`app_ko.arb`, `app_en.arb`)에서 키를 추가/수정하고
`flutter gen-l10n` (또는 `flutter pub get`)으로 `app_localizations*.dart`를 재생성.

## 키 네이밍 규칙

- **camelCase** — ARB 키는 점·하이픈·언더스코어 불가
- **prefix로 카테고리 구분**

| 카테고리 | 접두사 | 예시 |
|---------|------|------|
| 앱 전역 | `app*` | `appTitle` |
| 감정 라벨 | `emotion*` | `emotionLabel(type)` (ICU select) |
| 공통 버튼/액션 | `common*` | `commonOk`, `commonCancel`, `commonSave` |
| 에러 메시지 | `error*` | `errorNetwork`, `errorUnknown` |
| 화면별 | `{screen}*` | `settingsTitle`, `backupCreateButton`, `homeEmptyHint` |
| 위젯별 | `{widget}*` | `todayEntryHint`, `weeklyInsightTitle` |

## 플레이스홀더

```json
"diaryCount": "{count, plural, =0{기록 없음} =1{1개 기록} other{{count}개 기록}}",
"@diaryCount": {
  "placeholders": { "count": { "type": "int" } }
}
```

ICU `plural`, `select` 모두 지원. enum은 `type.name`을 문자열로 전달.

## 호출 패턴

```dart
import '../l10n/app_localizations.dart';

final loc = AppLocalizations.of(context);
Text(loc.settingsTitle);
Text(loc.emotionLabel(EmotionType.joy.name));
```

자주 쓰는 헬퍼:
- `emotionLabel(context, EmotionType)` — `lib/constants/emotions.dart`

## 새 키 추가 절차

1. `app_ko.arb`에 키 추가 (description 포함)
2. `app_en.arb`에 동일 키 영문 추가
3. `flutter gen-l10n` 실행
4. 코드에서 `loc.newKey` 사용
