# Transporter로 iOS IPA 업로드

`flutter build ipa` 로 만든 IPA를 App Store Connect에 올리는 가장 간단한 방법. Xcode Organizer보다 드래그 앤 드롭이 쉬워서 이 쪽을 권장.

## 사전 조건

- `flutter build ipa --release --dart-define-from-file=.env.json` 빌드 성공
- IPA 위치 확인: `build/ios/ipa/feeling_palette.ipa`
- App Store Connect 앱 레코드가 이미 생성돼 있을 것 (Bundle ID 매칭: `com.feelingpalette.feelingPalette`)
- Apple Developer 계정에 인증서가 Keychain에 있을 것 (→ `docs/IOS_RELEASE_GUIDE.md` STEP ⑦ 참고)

---

## 1. Transporter 설치 및 로그인

1. Mac App Store에서 Transporter 설치 (무료)
   - https://apps.apple.com/us/app/transporter/id1450874784
2. 실행 → Apple ID로 로그인 (App Store Connect와 같은 계정)
   - 2단계 인증 코드 입력 필요

---

## 2. IPA 업로드

1. Finder에서 `build/ios/ipa/feeling_palette.ipa` 찾기
2. Transporter 창으로 **드래그 앤 드롭** (또는 창 내 `+` 버튼 → 파일 선택)
3. 추가된 IPA를 Transporter가 자동 검증 (1~2분)
   - 빨간 ❌ 가 뜨면 경고 클릭해서 상세 확인 → [트러블슈팅](#트러블슈팅) 참고
   - 노란 ⚠️ 는 대부분 경고만 (업로드 가능)
4. **Deliver** 버튼 클릭 → 실제 업로드 시작
5. 업로드 자체는 보통 1~5분, 이후 Apple 서버 측 처리에 10~30분 추가로 필요

---

## 3. App Store Connect에서 빌드 확인

업로드 직후에는 빌드가 아직 안 보일 수 있음. **TestFlight 탭**에서 먼저 확인:

1. https://appstoreconnect.apple.com/apps/6762981925/testflight 접속
2. 빌드가 **"처리 중"** → **"테스트할 준비됨"** 으로 바뀔 때까지 대기 (10~30분)
3. 이메일로 처리 완료 또는 이슈 발견 알림이 옴

### 처리 중 경고/오류 예시

- **ITMS-90683: Missing Purpose String in Info.plist** — 빈번!
  - 앱에서 직접 사용하지 않더라도 의존 SDK가 Photos/Camera/Microphone API를 참조하면 발생
  - `file_picker` 플러그인 사용 시 `NSPhotoLibraryUsageDescription` 필수
  - 해결: `ios/Runner/Info.plist`에 해당 키 추가 → 빌드 번호 +1 → 재빌드 → 재업로드
  - 추가 후보 키: `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSContactsUsageDescription` 등 에러 메시지에 명시된 키
- **Invalid signature** — 인증서 문제. Xcode에서 Signing 재확인
- **Redundant Binary Upload** — 같은 빌드 번호로 재업로드 시. `pubspec.yaml` 빌드 번호 +1 후 재빌드

---

## 4. 버전 페이지에서 빌드 선택

처리 완료 후:

1. https://appstoreconnect.apple.com/apps/6762981925/distribution 로 이동
2. "iOS 앱 버전 1.0 제출 준비 중" 페이지에서 **빌드** 섹션 찾기
3. **"빌드 추가"** 또는 **"+"** 클릭 → 방금 올라온 빌드 선택
4. Export Compliance 질문 답변 (`ITSAppUsesNonExemptEncryption=false` 가 Info.plist에 있어서 자동 처리될 가능성 높음)
5. 저장

---

## 5. 첫 번째 IAP(`remove_ads`)를 버전에 포함

**첫 출시 시에만 해당** — 이미 출시된 앱이면 IAP는 별도 심사.

1. 같은 버전 페이지에서 **앱 내 구입 및 구독** 섹션 찾기
2. `remove_ads` 체크해서 이 버전에 포함
3. 포함 안 하면 IAP 코드가 앱에 있어도 스토어에서 구매 불가

---

## 6. 심사 제출

1. **심사에 추가** 버튼 클릭
2. 수출 규정, 콘텐츠 권한, 광고 식별자(IDFA 사용 여부) 질문 답변
   - Feeling Palette는 AdMob 사용이라 IDFA "예" + 서비스한 광고/광고 기여 체크
3. 제출
4. 심사 기간: 보통 24~48시간, 길면 1주

---

## 트러블슈팅

### "Invalid Bundle" / Bundle ID 불일치
- App Store Connect 앱 레코드의 Bundle ID와 IPA의 `PRODUCT_BUNDLE_IDENTIFIER`가 일치해야 함
- `grep PRODUCT_BUNDLE_IDENTIFIER ios/Runner.xcodeproj/project.pbxproj`로 확인

### "No valid code signing certificates"
- Xcode 열어서 Signing & Capabilities에 Team 선택 → 자동으로 인증서 재생성
- Keychain Access에서 Apple Development / Distribution 인증서 있는지 확인

### "This bundle is invalid. The key CFBundleShortVersionString must be set"
- `pubspec.yaml` 의 `version: 1.0.1+3` 같은 형식 확인 (+ 앞이 CFBundleShortVersionString)

### 업로드했는데 TestFlight에 안 보임
- 10~30분은 기본이고, 드물게 1시간 넘게 걸릴 때도 있음
- 1시간 넘으면 등록한 이메일로 오류 알림 왔는지 확인
- Processing 중 에러가 있으면 App Store Connect 상단 배너로 알림

### 심사 리젝 빈발 사유
- **스크린샷에 광고가 보임** → `SCREENSHOT_MODE=true` 로 찍은 광고 숨김 버전 재업로드
- **App Privacy 누락** → AdMob 쓰는데 IDFA 수집 안 적었을 때. 이 프로젝트는 이미 선언 완료
- **심사용 로그인 계정 미제공** → Feeling Palette는 로그인 선택이라 심사 메모에 "로그인 없이 사용 가능" 이미 명시됨
- **메타데이터-앱 기능 불일치** → 설명에 없는 기능이 앱에 있거나 그 반대

---

## 재빌드가 필요할 때

코드 수정 후 재업로드할 때는 `pubspec.yaml` **빌드 번호(+ 뒤 숫자)를 반드시 올려야** 함. 버전 번호는 그대로 두고 빌드 번호만 +1 해도 OK.

```yaml
version: 1.0.1+4  # 기존 1.0.1+3 에서 빌드 번호 4로 증가
```

그 후:

```bash
flutter build ipa --release --dart-define-from-file=.env.json
# build/ios/ipa/feeling_palette.ipa 재생성
```

같은 빌드 번호로 업로드하면 Transporter가 "A version with build number X already exists" 에러.
