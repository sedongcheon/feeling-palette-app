# 광고 테스트 가이드

Phase 7 체크리스트 — 실기기에서 광고 기능이 전부 정상 작동하는지 확인하는 방법.

---

## 📋 테스트 전 준비

### 1. 디버그 빌드 확인
`lib/constants/ad_ids.dart`가 `kReleaseMode` 스위치로 debug/profile 빌드에서 **구글 테스트 ID**를 반환하는지 확인.

### 2. 실기기 연결
시뮬레이터/에뮬레이터에서도 테스트 광고는 뜨지만, 실제 렌더링·레이아웃·ATT 프롬프트는 실기기에서 확인해야 정확합니다.

### 3. 클린 빌드
```
flutter clean && flutter pub get
cd ios && pod install && cd ..
flutter run
```

---

## ✅ 스모크 테스트 시나리오

### A. SDK 초기화
- [ ] 앱 실행 → 잠금 해제 완료
- [ ] (iOS) **ATT 프롬프트** 표시됨
   - 문구: "맞춤 광고를 제공하기 위해 기기 광고 식별자에 접근합니다..."
   - 허용/거부 모두 테스트 가능
- [ ] (EEA 지역) **UMP 동의 폼** 표시됨 — 한국에선 안 뜸 (정상)
- [ ] 콘솔에 `[Ads] SDK initialized` 로그 출력

### B. 배너
- [ ] **홈 탭** 하단: 배너 ❌ (없어야 함)
- [ ] **캘린더 탭** 하단: Google 테스트 배너 표시
- [ ] **통계 탭** 하단: Google 테스트 배너 표시
- [ ] **타임라인 탭** 하단: Google 테스트 배너 표시
- [ ] 탭 전환 시 배너 정상 표시/숨김
- [ ] **오프라인 상태**에서 배너 자동 접힘 (빈 공간 예약 안 함)

### C. 전면 광고 (2번째 분석마다)
- [ ] 일기 1~2개 작성 → **2번째 AI 분석 완료 직후** 전면 광고 표시
- [ ] 광고 닫기 후 앱 정상 복귀
- [ ] 같은 세션에서 추가 분석 → **세션 캡 1회 도달로 더 안 뜸**
- [ ] 앱 완전 종료 → 재실행 → 카운터 리셋, 다시 2번째 분석에 전면 표시 (쿨다운 3분 이상 지났다면)

### D. 리워드 광고 (한도 언락)
- [ ] **3개 일기 분석** → 배지 "3/3" 빨간색
- [ ] 홈 상단에 **"광고 보고 AI 분석 +1 언락 (남은 시청 5회)"** 버튼 표시
- [ ] 미분석 카드의 분석 버튼도 CTA로 전환
- [ ] 버튼 탭 → Google 테스트 리워드 광고 재생
- [ ] **끝까지 시청 후**: "AI 분석 +1개가 언락되었어요!" 스낵바, 배지 **3/4** 으로 변경
- [ ] 중간 종료: "광고를 끝까지 시청해야 보상을 받을 수 있어요." 스낵바, 배지 변화 **없음**
- [ ] 언락 후 새 일기 분석 가능 (카드 CTA가 일반 분석 버튼으로 복귀)
- [ ] 분석 반복 + 언락 반복 → 배지 "3/4" → "4/5" → "5/6" → … → **"7/8" (최종 상한)**
- [ ] 시청 5회 소진 후 → 버튼 사라짐
- [ ] 앱 재시작 후에도 **언락 상태 유지** (secure storage 영구 저장)

### E. 자정 리셋
- [ ] 11:58 PM에 10/10 분석 + 광고 언락 상태 만들기
- [ ] 12:01 AM까지 대기 (또는 시스템 시간 조정)
- [ ] 홈 탭 진입 → `loadDailyBonus()` 자동 호출 → 오늘 카운트 0/10 으로 리셋
- [ ] 광고 시청 횟수도 0회로 리셋 ("남은 시청 2회")

### F. 데이터 초기화 연동
- [ ] 잠금 화면에서 "비밀번호를 잊으셨나요?" → 초기화
- [ ] 재설정 완료 후 홈 진입 → 모든 카운트 0 / 배지 0/10
- [ ] secure storage의 `bonus_YYYY-MM-DD` 키가 유지돼도 캐시는 리셋됨 (`clearCache()`)

### G. Ad-Free 시나리오 (Phase 9 미리보기)
현재 `AdsService.setAdFree(true)`를 수동 호출 못 하지만, 코드로 검증 가능:
- [ ] Dart DevTools나 임시 코드로 `AdsService.instance.setAdFree(true)` 호출
- [ ] 배너 전부 사라짐
- [ ] 전면 광고 안 뜸
- [ ] 리워드 광고는 여전히 작동 (의도)

---

## 🛠️ 문제 해결 팁

### 실기기에서 배너가 안 뜸
1. 콘솔 로그 확인: `Interstitial failed:` `Banner failed:` 있으면 원인 파악
2. 네트워크 연결 확인
3. `ConsentService` 에서 `canRequestAds() = false` 리턴할 가능성 있음 (UMP 거부)
4. 5~10초 대기 (초기 로드 지연)

### 리워드 광고가 "준비 안 됨"
- 처음 앱 실행 직후엔 프리로드가 안 끝났을 수 있음
- 몇 초 대기 후 재시도
- 로그에 `[Ads] Rewarded failed:` 있으면 네트워크/광고 재고 문제

### ATT 프롬프트가 안 뜸
- iOS 14 이상 기기여야 함
- 한 번 "거부" 눌렀다면 재표시 안 됨 (iOS 정책)
- 설정 → 개인 정보 보호 및 보안 → 추적 → Feeling Palette ON/OFF 확인
- 또는 앱 삭제 후 재설치

### 전면 광고가 자꾸 나옴 / 안 나옴
- `ads_service.dart` 에서 `kInterstitialEveryNAnalyses` (5) / `kInterstitialSessionCap` (2) / `kInterstitialCooldown` (4분) 확인
- 세션 카운터는 앱 재시작 시 리셋됨

### 테스트 디바이스 ID 얻기
실기기에서 처음 광고를 요청하면 콘솔에 다음과 같은 안내가 나옵니다:
```
I/Ads: Use RequestConfiguration.Builder.setTestDeviceIds(Arrays.asList("XXXXXXXX..."))
to get test ads on this device.
```
이 ID를 `lib/constants/ad_ids.dart` 의 `AdIds.testDeviceIds` 배열에 넣으면, 실제 ad unit ID를 써도 **테스트 광고**만 뜹니다 — 실수 클릭으로 계정 정지되는 일 방지에 유용.

---

## 📊 운영 모니터링 (릴리스 후)

- **AdMob 대시보드** (apps.admob.com) — 노출, 클릭, eCPM, fill rate
- **Firebase Crashlytics** (설정 시) — 광고 로드 실패 크래시
- **Play Console / App Store Connect 리뷰** — "광고 너무 많음" 키워드 감시
- **실기기 체감 테스트** — 매 2주 정도 직접 써보면서 UX 이슈 확인

---

## 🚩 릴리스 전 최종 체크

- [ ] `lib/constants/ad_ids.dart` 의 **release IDs**가 AdMob에서 발급받은 실제 ID와 일치
- [ ] `AndroidManifest.xml` 의 **APPLICATION_ID** 가 Android 실제 App ID
- [ ] `Info.plist` 의 **GADApplicationIdentifier** 가 iOS 실제 App ID
- [ ] 개인정보처리방침 URL 스토어 메타데이터에 등록
- [ ] iOS ATT 문구 한국어 확인 (`NSUserTrackingUsageDescription`)
- [ ] Play Console **데이터 안전** 섹션에 광고 식별자 수집 표시
- [ ] 최소 1대 실기기에서 **릴리스 빌드** 테스트 후 심사 제출
