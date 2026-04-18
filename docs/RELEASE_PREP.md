# 릴리스 준비 가이드 (Phase 8)

앱을 **Google Play Store**와 **Apple App Store**에 출시하기 위해 필요한 작업을 정리한 체크리스트. 코드는 대부분 준비됐고, 이 단계는 주로 **외부 설정·서명·메타데이터**입니다.

---

## 📦 공통 준비물

### 1. 앱 아이콘 ✅
- `assets/icon/app_icon.png` — 이미 있음
- `flutter_launcher_icons` 설정 `pubspec.yaml`에 구성됨
- 아이콘 재생성 필요 시: `dart run flutter_launcher_icons`

### 2. 앱 이름
- **한국어**: `감정 팔레트`
- **영문**: `Feeling Palette`

### 3. 한 줄 소개 (최대 80자)
> 매일의 감정을 기록하고 AI가 분석해주는 AI 감정일기

### 4. 전체 설명 (최대 4000자) — 예시
```
✨ Feeling Palette — 내 감정을 색으로 기록하다

매일의 감정을 편하게 기록하고,
AI가 분석해주는 나만의 감정일기입니다.

[주요 기능]
• 하루 여러 번 기록 가능 — 아침의 설렘, 저녁의 피로까지
• AI 감정 분석 — 기쁨/슬픔/분노/불안/평온/설렘 6가지 감정 점수로 시각화
• 감정 캘린더 — 한 달간의 감정 흐름을 색으로 확인
• 월간 통계 — 가장 많이 느낀 감정 Top 3, 감정 변화 그래프
• Google Drive 백업 — 안전하게 다른 기기로 이동
• 앱 잠금 — PIN + 생체인증으로 일기를 안전하게

[개인정보 보호]
• 일기 내용은 기기에만 저장됩니다
• AI 분석 시 서버로 전송되지만 저장하지 않습니다
• 자세한 내용: https://sedongcheon.github.io/feelingpalette-privacy/
```

### 5. 스크린샷
- **Play Store**: 최소 2장, 권장 4~8장. 폰용 16:9 또는 9:16
- **App Store**: iPhone 6.7" (1290×2796) 최소 3장 필수. 5.5" optional
- 추천 화면:
  1. 홈 (일기 작성 화면)
  2. AI 분석 결과 카드
  3. 감정 캘린더
  4. 월간 통계
  5. 타임라인

### 6. 연락처 이메일
- `sedong1000@gmail.com`

### 7. 개인정보처리방침 URL ✅
- `https://sedongcheon.github.io/feelingpalette-privacy/`

### 8. 버전 / 빌드 번호
- 현재 `pubspec.yaml`: `version: 1.0.0+1`
- 첫 출시 그대로 OK. 업데이트마다:
  - 버그 수정: `1.0.1+2`
  - 기능 추가: `1.1.0+3`
  - 대형 변경: `2.0.0+4`
  - 빌드 번호(+뒤)는 **항상 증가**, 스토어가 이걸로 중복 업로드 방지

---

## 🤖 Android 릴리스

### 1. 서명 키 생성 (한 번만)
**주의**: 이 키를 잃어버리면 **앱 업데이트를 영원히 못 올림**. 안전하게 백업.

```bash
# ~/upload-keystore.jks 생성
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
- 비밀번호 2개(키스토어·키) 생성 → 1Password 등 안전한 곳에 저장
- `.jks` 파일도 여러 곳 백업

### 2. 서명 설정
루트에 `android/key.properties` (Git에 커밋 금지):
```properties
storePassword=<keystore-password>
keyPassword=<key-password>
keyAlias=upload
storeFile=/Users/cheonsedong/upload-keystore.jks
```

`android/app/build.gradle.kts`에 서명 설정 추가 (상세는 Flutter 공식 문서 참조).

### 3. `.gitignore`에 추가
```
android/key.properties
*.jks
```

### 4. 릴리스 AAB 빌드
```bash
flutter build appbundle --release
```
→ `build/app/outputs/bundle/release/app-release.aab`

### 5. Play Console 설정
1. [play.google.com/console](https://play.google.com/console) → 새 앱 만들기
2. 앱 이름, 언어, 앱/게임 여부, 무료/유료
3. **앱 콘텐츠** 섹션 전체 채우기:
   - 개인정보처리방침 URL
   - 광고 포함 여부: **예 (AdMob)**
   - 앱 액세스: 비밀번호 있음(잠금) → 테스트 계정 정보 제공
   - 콘텐츠 등급 설문
   - **타겟 고객 및 콘텐츠**: 14세 이상 선택
   - **데이터 보안 섹션**: 아래 §Data Safety 참고
4. **스토어 등록정보** — 스크린샷, 설명, 아이콘
5. **앱 번들 업로드** (내부 테스트 → 비공개 → 공개 프로덕션 순)

### 6. Data Safety 선언 (Play Console)
| 질문 | 답변 |
|------|------|
| 개인정보를 수집/공유? | **예** |
| 데이터 전송은 암호화? | **예** (HTTPS) |
| 사용자가 데이터 삭제 요청? | **예** (앱 내 삭제 + 데이터 초기화) |

수집 데이터 카테고리:
- **개인정보** → 이메일 주소 (Google Drive 백업 선택 시)
- **기기 식별자 또는 기타 ID** → 광고 식별자 (AdMob)
- **앱 활동** → 앱 내 검색/기록 (로컬만)
- **사용자 콘텐츠** → 텍스트 (일기 — 로컬 저장, AI 분석 위해 임시 전송)

공유 여부: **예, 다음 제3자에게** Google AdMob

---

## 🍎 iOS 릴리스

### 1. Apple Developer 등록 (연 $99, 약 ₩130,000)
- <https://developer.apple.com/programs/>
- 개인 이름 or DBA(사업자) 등록

### 2. App Store Connect 앱 등록
1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → 내 앱 → **+**
2. 플랫폼: iOS
3. 이름: Feeling Palette
4. 기본 언어: 한국어
5. Bundle ID: `com.feelingpalette.feeling_palette`
6. SKU: 고유 식별자 (예: `feeling-palette-ios`)

### 3. 앱 정보 입력
- 개인정보처리방침 URL ← GitHub Pages URL
- 앱 카테고리: **라이프스타일** 또는 **건강 및 피트니스**
- 콘텐츠 권한 정보 (연령 등급)

### 4. App Privacy 선언
Play Console의 Data Safety와 유사. 수집 데이터 각 항목별로:
- **Contact Info** → Email (Drive 백업 시)
- **Identifiers** → Device ID (광고)
- **User Content** → Diary entries (local + AI analysis request)

### 5. Xcode에서 아카이브 + 업로드
```bash
flutter build ipa --release
```
→ `build/ios/ipa/feeling_palette.ipa`

또는 Xcode 열어서 Product → Archive → Distribute to App Store Connect.

### 6. TestFlight 내부 테스트
- 빌드 업로드 후 TestFlight에 자동 등록
- 본인 계정으로 테스트 → 문제 없으면 심사 제출

### 7. 심사 제출
- 스크린샷 5.5" + 6.7" (필수)
- 앱 설명 / 키워드 / 지원 URL
- 심사 기간: 보통 1~3일

---

## 🔐 마지막 보안 체크

출시 전 `git status`로 확인:
- [ ] `.env.json` 커밋 안 됨 (이미 `.gitignore`에 있음)
- [ ] `android/key.properties` 커밋 안 됨
- [ ] `*.jks` 파일 커밋 안 됨
- [ ] AdMob 실 ID가 코드에 있는 건 OK (시크릿 아님)

---

## 📱 테스트 플로우 (TestFlight / 내부 테스트)

정식 출시 전에 최소 한 번은:
- [ ] 실기기에서 릴리스 빌드 설치
- [ ] **광고가 실 ID로 제대로 뜨는지** (테스트 광고 아닌 실제 광고)
- [ ] **IAP 실결제 테스트** (샌드박스 계정으로 ₩1,000 광고 제거)
- [ ] Google Drive 백업/복원 한 사이클
- [ ] 앱 잠금 + 데이터 초기화 플로우
- [ ] 카탈로그 지워도 재설치 후 "구매 복원" 동작

---

## 🚀 릴리스 명령 한눈에

```bash
# Android AAB
flutter build appbundle --release
# → Play Console 업로드

# iOS IPA
flutter build ipa --release
# → Xcode → Distribute → App Store Connect

# 빌드 번호 올릴 때
# pubspec.yaml의 `version: 1.0.1+2` 수정 후 재빌드
```

---

## 📝 릴리스 후 할 일

1. **AdMob 대시보드 → 앱 설정 → 앱 스토어 세부정보 추가** — 출시된 스토어 URL 연결
2. 개인정보처리방침 URL이 스토어 리스팅에서 자동 참조됨
3. 2~3주 운영 후 AdMob 대시보드에서 eCPM · fill rate 확인
4. 사용자 리뷰 모니터링 → 피드백 반영
