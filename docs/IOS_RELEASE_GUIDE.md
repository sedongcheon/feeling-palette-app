# iOS 출시 가이드 (App Store 제출)

Apple Developer 등록 완료 후부터 App Store 심사 제출까지 전체 흐름.
- **Team ID**: `R97CE6VN7C` (WORXPHERE LLC 팀 / 혹은 새 Individual 팀으로 교체 가능)
- **Bundle ID**: `com.feelingpalette.feelingPalette` (언더스코어 X)
- **IAP 상품 ID**: `remove_ads`
- **개발자 지원 메일**: `sedong1000@gmail.com`
- **개인정보 URL**: `https://sedongcheon.github.io/feelingpalette-privacy/`

---

## ✅ 이미 끝난 것

- [x] Apple Developer Program 결제 & 승인
- [x] `Info.plist` 설정 — ATT, AdMob, SKAdNetwork, Export Compliance, CFBundleLocalizations
- [x] `SCREENSHOT_MODE=true` 플래그 (광고/동의 팝업 스킵)
- [x] iOS 스크린샷 8장 (1320×2868, `docs/screenshots/ios/ko/`)
- [x] 메타데이터 초안 (`docs/STORE_METADATA.md`)

---

## STEP ① Apple Developer — Bundle ID 등록

👉 https://developer.apple.com/account/resources/identifiers/list

1. 우측 **`+`** → App IDs → App
2. Description: `Feeling Palette`
3. Bundle ID → **Explicit** → `com.feelingpalette.feelingPalette`
4. Capabilities: ✅ **In-App Purchase** 만 체크
5. Continue → Register

---

## STEP ② App Store Connect — 앱 생성

👉 https://appstoreconnect.apple.com/apps

**내 앱 → `+` → 새로운 앱**

| 필드 | 값 |
|---|---|
| 플랫폼 | iOS |
| 이름 | `감정 팔레트` |
| 기본 언어 | 한국어 |
| Bundle ID | `com.feelingpalette.feelingPalette` |
| SKU | `feelingpalette2026` (임의 고유값) |
| 사용자 액세스 | 전체 액세스 |

---

## STEP ③ 앱 정보 입력

소스: `docs/STORE_METADATA.md`

| 입력란 | 값 |
|---|---|
| 이름 | `감정 팔레트` |
| 부제목 | `내 감정을 색으로 기록하다` |
| 프로모션 텍스트 | STORE_METADATA.md §프로모션 복붙 |
| 설명 | §전체 설명 블록 복붙 |
| 키워드 | `감정일기,일기,AI일기,감정분석,감정기록,하루일기,마음일기,감정,일기앱,심리,캘린더,감정추적` |
| 지원 URL | `https://sedongcheon.github.io/feelingpalette-privacy/` |
| 마케팅 URL | (비워둠) |
| 개인정보 URL | `https://sedongcheon.github.io/feelingpalette-privacy/` |
| 카테고리 | 주: 라이프스타일 / 보조: 건강 및 피트니스 |
| 연령 등급 | 4+ |
| 저작권 | `2026 세도리` |

### 스크린샷 업로드 (6.9" iPhone)
`docs/screenshots/ios/ko/` 에서 순서대로:

1. `01-home-input.png`
2. `02-home-records.png`
3. `03-timeline.png`
4. `04-calendar.png`
5. `05-calendar-detail.png`
6. `06-stats-distribution.png`
7. `07-stats-ai-summary.png`
8. `08-app-lock.png`

---

## STEP ④ App Privacy 선언

좌측 **앱 개인정보보호 → 시작**

| 수집 데이터 | 목적 | 사용자와 연결 |
|---|---|---|
| 이메일 주소 (Google Sign-In) | 앱 기능(백업) | ❌ |
| 사용자 콘텐츠 — 일기 | 앱 기능 | ❌ |
| 식별자 — IDFA (AdMob) | 서드파티 광고 | ✅ (추적) |

> 일기 본문은 "기기에 저장, 서버 저장 X"로 답변.
> AI 분석은 일시적 전송만이므로 "수집 데이터"에 해당 X.

---

## STEP ⑤ IAP `remove_ads` 등록

좌측 **앱 내 구입 및 구독 → In-App Purchases → `+`**

| 필드 | 값 |
|---|---|
| 타입 | **비소모성 (Non-Consumable)** |
| 참조 이름 | `Remove Ads` |
| 제품 ID | **`remove_ads`** (앱 코드와 일치 필수) |
| 가격 | Tier 2 (₩2,500) |
| 표시 이름 (ko) | `광고 제거` |
| 설명 (ko) | `배너·전면 광고를 모두 제거하고 쾌적하게 사용하세요.` |
| 심사용 스크린샷 | `docs/screenshots/ios/ko/02-home-records.png` |

---

## STEP ⑥ 샌드박스 테스터

**사용자 및 액세스 → 샌드박스 → 테스터 → `+`**

- 이메일: **Apple ID로 안 쓴 새 주소** (예: Gmail alias `sedong1000+sandbox@gmail.com`)
- 비밀번호: 별도 설정
- 국가: 대한민국

기기 → 설정 → App Store → 샌드박스 계정으로 로그인 → TestFlight에서 IAP 테스트.

---

## STEP ⑦ 빌드 업로드 (Xcode Archive)

### 사전 확인
```bash
# pubspec.yaml의 version 확인 (예: 1.0.0+1 → 2026.4.1 같은 패턴)
# .env.json에 시크릿들 들어있는지 확인 (GEMINI_API_KEY 등)
```

### 빌드
```bash
cd /Users/cheonsedong/Documents/appProject/feelingPaletteFlutter

# Flutter ipa 빌드 (release)
flutter build ipa --release --dart-define-from-file=.env.json

# 결과: build/ios/archive/Runner.xcarchive
```

### Xcode에서 업로드
```bash
# Xcode로 archive 열기
open build/ios/archive/Runner.xcarchive
```

또는 Xcode 직접 실행:
1. `ios/Runner.xcworkspace` 열기
2. 상단 기기 선택 → **Any iOS Device (arm64)**
3. 메뉴 **Product → Archive**
4. Organizer 창 → **Distribute App → App Store Connect → Upload**
5. Signing: Automatically manage signing
6. Upload → 처리 대기 (10~30분)

### 업로드 후
- App Store Connect → 앱 → **TestFlight** 탭에 빌드 등장
- "처리 중" → "테스트할 준비됨" 으로 바뀜
- Compliance 질문이 떴다면 `ITSAppUsesNonExemptEncryption=false` 덕분에 자동 처리됨

---

## STEP ⑧ TestFlight 내부 테스트

1. TestFlight → **내부 테스트** → `+` 그룹 만들기
2. 본인 Apple ID를 테스터로 추가
3. 기기의 **TestFlight 앱**에서 Feeling Palette 설치
4. 스모크 테스트:
   - [ ] PIN 설정 & 잠금 해제
   - [ ] 일기 작성 → AI 분석
   - [ ] 캘린더·타임라인·통계
   - [ ] 월간 AI 요약
   - [ ] Google Drive 백업·복원
   - [ ] **광고 표시 (샌드박스 아닌 일반 계정으로)**
   - [ ] **IAP 구매 (샌드박스 계정으로)** — ₩0 처리
   - [ ] 구매 복원

---

## STEP ⑨ 심사 제출

1. App Store Connect → 앱 → **배포** 탭
2. 빌드 선택 (TestFlight에서 처리 완료된 것)
3. **App Review 정보**:
   - 연락처: 이름, 전화, 이메일
   - **데모 계정**: 필요 없음 (앱 잠금이 있지만 사용자가 직접 설정)
   - 메모: 있으면 특이사항. 예:
     ```
     - 기본 기능은 로그인 없이 사용 가능합니다.
     - Google Drive 백업은 선택 기능입니다.
     - AI 분석은 Google Gemini API를 사용합니다.
     - 앱 잠금은 사용자가 설정에서 직접 활성화합니다.
     ```
4. **릴리즈 방식**: 수동 또는 심사 통과 즉시
5. **심사에 제출**

> 심사 기간: 보통 24~48시간, 길면 1주. 리젝 사유 대부분은 "메타데이터 불일치" 또는 "광고 노출 스크린샷".

---

## 🚨 자주 막히는 것

### Provisioning Profile 에러
- Xcode → Signing & Capabilities → Team 선택 확인
- "Automatically manage signing" 체크

### Bundle ID 불일치
- `ios/Runner.xcodeproj/project.pbxproj` → `PRODUCT_BUNDLE_IDENTIFIER`가 `com.feelingpalette.feelingPalette`인지

### IAP 상품이 앱에 안 뜸
- App Store Connect에 상품이 **"대기중"** 상태 이상인지
- **앱이 최소 1회 업로드** 돼 있어야 상품 로드 가능
- Bundle ID 매칭 확인

### 심사 리젝: "광고 포함 스크린샷"
- 스크린샷 모드(`SCREENSHOT_MODE=true`)로 찍은 이미지 사용 (광고 숨김 상태)

### `App Privacy` 누락으로 리젝
- 데이터 수집 있는 항목 하나라도 빼먹으면 리젝. IDFA (AdMob) 필수.

---

## 📋 전체 체크리스트

**Apple Developer**
- [ ] Bundle ID 등록 (`com.feelingpalette.feelingPalette`)
- [ ] In-App Purchase capability 체크

**App Store Connect**
- [ ] 앱 생성
- [ ] 메타데이터 입력 (이름/부제/설명/키워드)
- [ ] 스크린샷 8장 업로드
- [ ] 카테고리 / 연령등급 / 저작권
- [ ] 지원 URL / 개인정보 URL
- [ ] App Privacy 선언
- [ ] IAP `remove_ads` 등록
- [ ] 샌드박스 테스터 추가

**빌드 & 테스트**
- [ ] `flutter build ipa --release --dart-define-from-file=.env.json`
- [ ] Xcode Archive → App Store Connect 업로드
- [ ] TestFlight 처리 대기
- [ ] 내부 테스터 추가, 기기에서 TestFlight 설치
- [ ] 광고 / IAP / Drive 스모크 테스트

**심사**
- [ ] 심사 정보 입력
- [ ] 제출
- [ ] 통과 후 릴리즈
