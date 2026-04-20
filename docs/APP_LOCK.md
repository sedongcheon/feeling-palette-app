# 앱 잠금 (PIN + 생체인증) 가이드

앱 실행 및 백그라운드 복귀 시 4자리 PIN 또는 생체인증(지문/FaceID)으로 잠금 해제하는 기능입니다.

---

## 1. 동작 개요

| 상황 | 화면 |
|------|------|
| 첫 실행 (PIN 미설정) | PIN 설정 화면 → PIN 확인 → 생체인증 선택 → 메인 |
| 이후 실행 | 잠금 화면 (생체인증 자동 시도) → 메인 |
| 백그라운드 → 포그라운드 복귀 | 설정된 유예 시간 경과 시 잠금 (기본 30초) |
| PIN 분실 | 잠금 화면의 "비밀번호를 잊으셨나요?" → 전체 데이터 초기화 → PIN 재설정 |

- **잠금 시점**: `AppLifecycleState.paused` 또는 `hidden` 진입 시 타임스탬프 기록 → `resumed` 시 경과 시간이 유예 시간을 넘었으면 `locked` 로 전환. 유예 시간이 0초면 `paused`/`hidden` 즉시 전환.
- **생체인증 중 오동작 방지**: 생체인증 프롬프트가 뜨면 iOS에서 `inactive`가 발생할 수 있음. `_isAuthenticatingBiometric` 플래그로 해당 순간의 lifecycle 이벤트는 무시.
- **유예 시간**: 설정 화면 → "앱 잠금" → "자동 잠금" 에서 `즉시 / 30초 / 1분 / 5분 / 10분` 중 선택. 기본값은 30초 (`AuthService.defaultAutoLockDelaySeconds`).

---

## 2. 주요 파일

### 서비스 / 상태
- `lib/services/auth_service.dart` — PIN 해시/검증, secure storage I/O, 생체인증 capability 체크
- `lib/providers/auth_provider.dart` — `AuthStage` (loading/needsSetup/locked/unlocked), lifecycle 관찰, 데이터 초기화

### 화면
- `lib/screens/pin_setup_screen.dart` — PIN 입력 → 확인 → 생체인증 선택
- `lib/screens/lock_screen.dart` — PIN 입력 + 생체인증 버튼 + "비밀번호를 잊으셨나요?"
- `lib/widgets/pin_pad.dart` — 공용 숫자 패드
- `lib/widgets/app_lock_gate.dart` — 루트 게이트. `AuthStage`에 따라 화면 라우팅

### 진입점
- `lib/main.dart` — `MultiProvider`로 `DiaryProvider` + `AuthProvider` 등록, `home: AppLockGate()`

---

## 3. PIN 저장 / 검증

### 저장 위치
`flutter_secure_storage` (Android: EncryptedSharedPreferences / iOS: Keychain).

저장 키:
- `lock_pin_hash`: SHA-256 해시의 Base64
- `lock_pin_salt`: 16바이트 랜덤 salt의 Base64
- `lock_biometric_enabled`: `'1'` | `'0'`
- `lock_auto_lock_delay_seconds`: 자동 잠금 유예 시간(초) 문자열. 미설정/파싱 실패 시 `AuthService.defaultAutoLockDelaySeconds` (현재 30초).

### 해시 방식
```
digest = SHA256(salt || pin)
for 5000 iterations:
  digest = SHA256(digest || salt)
```
4자리 PIN(10k 조합)은 이론상 약하므로 secure storage(Keychain/Keystore)의 하드웨어 보호가 1차 방어선.

### 분실 시 복구
**불가능.** 잠금 화면 → "비밀번호를 잊으셨나요?" → 확인 → `resetAllData()` 실행:
1. `flutter_secure_storage`의 PIN/salt/생체인증 플래그 삭제
2. `AppDatabase.wipe()` 호출 → SQLite DB 파일 삭제
3. `DiaryProvider.clearCache()` 호출 (AppLockGate에서 자동)
4. `AuthStage.needsSetup`으로 복귀

복구 후 사용자는 새 PIN을 설정하고 빈 상태로 시작.

---

## 4. 생체인증

### 지원 체크
`AuthService.canUseBiometric()`:
- `isDeviceSupported()` (OS 레벨 지원)
- `canCheckBiometrics` (하드웨어 존재)
- `getAvailableBiometrics().isNotEmpty` (등록된 생체 정보 존재)

### 호출 옵션
```dart
LocalAuthentication().authenticate(
  localizedReason: '생체인증으로 잠금을 해제합니다',
  options: const AuthenticationOptions(
    biometricOnly: true,
    stickyAuth: true,
  ),
);
```
- `biometricOnly: true` — 기기 PIN으로 대체 못하게 막음 (앱 PIN이 우선).
- `stickyAuth: true` — 앱이 백그라운드 갔다 돌아와도 인증 재개.

### 설정 변경
현재는 초기 설정 시에만 생체인증 on/off 선택 가능. 설정 화면에서 변경 UI 필요하면 `AuthProvider`에 메서드 추가 후 `AuthService.setBiometricEnabled()` 호출.

---

## 5. 네이티브 설정

### Android
- `android/app/src/main/kotlin/com/feelingpalette/feeling_palette/MainActivity.kt`: `FlutterFragmentActivity` 상속 (local_auth 필수)
- `android/app/src/main/AndroidManifest.xml`: `<uses-permission android:name="android.permission.USE_BIOMETRIC"/>`
- `android/app/build.gradle.kts`: `minSdk = maxOf(flutter.minSdkVersion, 23)` (EncryptedSharedPreferences 요구)

### iOS
- `ios/Runner/Info.plist`:
  ```xml
  <key>NSFaceIDUsageDescription</key>
  <string>앱 잠금 해제에 Face ID를 사용합니다.</string>
  ```

### Flutter 패키지 (`pubspec.yaml`)
```yaml
flutter_secure_storage: ^9.2.2
local_auth: ^2.3.0
crypto: ^3.0.5
```

---

## 6. 커스터마이징

| 변경할 내용 | 위치 |
|-------------|------|
| PIN 자릿수 | `pin_pad.dart`의 `length` 파라미터 + `pin_setup_screen.dart`/`lock_screen.dart`의 `== 4` 비교 |
| 잠금 유예 시간 옵션 추가/변경 | `settings_screen.dart` `_autoLockOptions` 상수 수정 (레이블/초 단위) |
| 해시 stretch 횟수 | `auth_service.dart` `_hashPin`의 `5000` 상수 |
| PIN 변경 기능 | `AuthService.setPin()`은 이미 덮어쓰기 가능. UI만 추가하면 됨 |
| 자동 잠금 시점 (inactive 포함) | `auth_provider.dart` `didChangeAppLifecycleState` 조건에 `inactive` 추가 시 생체인증 프롬프트와 충돌 주의 |

---

## 7. 트러블슈팅

| 증상 | 원인 / 대응 |
|------|-------------|
| iOS에서 생체인증 프롬프트가 안 뜸 | `NSFaceIDUsageDescription` 누락 or 기기에 생체 미등록 |
| Android 빌드 에러 (local_auth) | `MainActivity`가 `FlutterActivity`면 `FlutterFragmentActivity`로 변경 |
| "attempt to write a readonly database" | 플러그인 추가 후 네이티브 캐시 꼬임 → `flutter clean && pod install && flutter run` |
| 잠금이 풀렸는데 데이터가 안 보임 | `resetAllData` 직후 `DiaryProvider.clearCache()` 호출됐는지 확인 (`AppLockGate`에서 자동 처리) |
