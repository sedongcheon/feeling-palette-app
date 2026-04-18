# Google Drive 백업 셋업 가이드

이 앱의 "Drive에 백업 / 복원" 기능을 활성화하려면 **Google Cloud Console**에서 OAuth 클라이언트 ID 발급과 **앱 설정 파일 수정**이 필요합니다. 한 번만 하면 됩니다.

> 코드 상으로는 이미 모두 구현되어 있고, 아래 셋업이 끝나면 바로 동작합니다.

---

## 1. Google Cloud 프로젝트 / OAuth 동의 화면

1. [Google Cloud Console](https://console.cloud.google.com)에서 새 프로젝트(혹은 기존 프로젝트) 선택.
2. 좌측 메뉴 → **API 및 서비스 → 사용 설정된 API** → **Google Drive API** 사용 설정.
3. 좌측 메뉴 → **API 및 서비스 → OAuth 동의 화면**:
   - 유형: **외부**
   - 앱 이름: `Feeling Palette`
   - 사용자 지원 이메일 / 개발자 연락처 입력
   - 범위(Scopes) 추가: `https://www.googleapis.com/auth/drive.appdata`
   - 테스트 사용자에 본인 Google 계정 등록 (검수 전까지 본인만 로그인 가능)

---

## 2. OAuth 클라이언트 ID 발급

좌측 메뉴 → **사용자 인증 정보 → 사용자 인증 정보 만들기 → OAuth 클라이언트 ID** 두 개를 만듭니다.

### iOS 클라이언트
- 애플리케이션 유형: **iOS**
- 번들 ID: 앱의 Bundle Identifier (Xcode → Runner 타겟에서 확인, 기본 `com.feelingpalette.feelingPalette`)
- 발급 후 표시되는 **클라이언트 ID**(예: `123456-abcd.apps.googleusercontent.com`)와 **iOS URL 스키마**(예: `com.googleusercontent.apps.123456-abcd`)를 메모.

### Android 클라이언트
- 애플리케이션 유형: **Android**
- 패키지 이름: `com.feelingpalette.feeling_palette` (현 프로젝트 값)
- **SHA-1 인증서 지문**:
  - 디버그 키:
    ```bash
    keytool -list -v -keystore ~/.android/debug.keystore \
            -alias androiddebugkey -storepass android -keypass android | grep SHA1
    ```
  - 릴리스 키스토어가 별도로 있다면 그 키의 SHA-1도 등록 (Play 서명 사용 시 Play Console의 앱 서명 키 SHA-1).

> **클라이언트 ID 자체는 Android 코드에 넣지 않습니다.** Google Sign-In Android는 패키지명 + SHA-1로 자동 매칭됩니다.

---

## 3. iOS 설정 파일 수정

`ios/Runner/Info.plist` 하단에 이미 placeholder가 들어 있습니다. 다음 두 값을 발급받은 값으로 교체하세요.

```xml
<key>GIDClientID</key>
<string>YOUR_IOS_CLIENT_ID.apps.googleusercontent.com</string>  <!-- ← iOS 클라이언트 ID -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID</string>  <!-- ← REVERSED_CLIENT_ID -->
    </array>
  </dict>
</array>
```

`YOUR_IOS_CLIENT_ID`는 같은 값입니다 (한 곳은 정방향, 한 곳은 도메인 형태로 변환된 reversed 형태).

수정 후 iOS 빌드 캐시를 한 번 비우는 게 안전합니다:

```bash
cd ios && pod install && cd ..
flutter clean && flutter run
```

---

## 4. Android 설정

별도 코드 변경은 필요 없습니다. 단, **`AndroidManifest.xml`에 `INTERNET` 권한이 이미 추가되어 있어야** 합니다 (이 프로젝트는 추가 완료).

릴리스 APK로 배포할 때는 Google Cloud Console에 **릴리스 키스토어의 SHA-1**을 추가로 등록해야 합니다. 디버그/릴리스 모두 동작시키려면 두 SHA-1을 모두 등록하세요.

---

## 5. 동작 확인

1. 앱 실행 → 홈 → 우측 상단 ☁️ 아이콘 → "백업 / 복원"
2. **Google Drive** 섹션에서 "로그인" 탭
3. Google 계정 선택 후 권한 동의 (Drive의 앱 전용 폴더 액세스)
4. "Drive에 백업" → 자동으로 새 백업 파일 업로드
5. "Drive에서 복원" → 저장된 백업 목록에서 선택해 복원

---

## 동작 방식 / 보안

- 백업 파일은 사용자 Google Drive의 **`appDataFolder`**(앱 전용 숨김 폴더)에 저장됩니다.
  - 사용자의 일반 Drive 화면에는 보이지 않음
  - 다른 앱이 접근 불가
  - 사용자가 `drive.google.com → 설정 → 데이터 관리`에서만 확인/삭제 가능
- 요청 권한: `drive.appdata`만 사용 (전체 Drive 접근 안 함)
- 토큰은 OS의 보안 저장소에 google_sign_in이 자동 관리

---

## 자주 나는 오류

| 증상 | 원인 / 해결 |
|---|---|
| iOS에서 사파리/Chrome으로 튕긴 뒤 로그인이 끝나지 않음 | `Info.plist`의 `CFBundleURLSchemes`에 REVERSED_CLIENT_ID가 정확히 들어갔는지 확인 |
| `PlatformException(sign_in_failed, ..., 10)` (Android) | Google Cloud의 OAuth 클라이언트에 등록된 패키지명 / SHA-1이 실제 빌드와 일치하는지 확인 |
| `403 access_denied` | OAuth 동의 화면이 "테스트" 상태고 본인 계정이 테스트 사용자에 없음 |
| `401 invalid_grant` | 토큰 만료 — 앱에서 한번 로그아웃 후 재로그인 |
