# 광고 제거 IAP 스토어 등록 가이드

앱 코드는 완성됐지만 **스토어에 상품을 등록**해야 실제로 구매 가능합니다. Android·iOS 각각 등록 절차.

---

## 상품 정보 (양 스토어 공통)

| 항목 | 값 |
|------|-----|
| 상품 ID | `remove_ads` |
| 타입 | 비소모성 (Non-consumable) |
| 가격 | **₩2,500** |
| 이름 | 광고 제거 |
| 설명 | 배너·전면 광고를 모두 제거하고 쾌적하게 사용하세요. |

---

## Android — Google Play Console

### 1. 상품 생성
1. Play Console → 내 앱 → Feeling Palette
2. 좌측 메뉴 → **수익 창출 → 제품 → 인앱 제품**
3. **새 상품 만들기**
4. 상품 ID: `remove_ads`
5. 이름: `광고 제거`
6. 설명: 위 표 참고
7. 가격: `₩1,000` (KR 기준가). 다른 국가도 자동 환산되지만 원하면 수동 조정

### 2. 선행 조건
- **앱이 최소 1회 업로드**되어 있어야 인앱 제품 등록 가능 (내부 테스트 트랙도 OK)
- 앱 패키지명이 Play Console에 등록된 것과 일치: `com.feelingpalette.feeling_palette`

### 3. 테스트 준비
1. Play Console → 설정 → **라이선스 테스트 계정**에 본인 Gmail 추가
2. 테스트 계정에서 앱 설치
3. 테스트 구매 시 실제 결제 안 됨 (테스트 카드로 처리)

---

## iOS — App Store Connect

### 1. 앱 등록
1. App Store Connect → 내 앱 → Feeling Palette 등록 (없으면)
2. Bundle ID: `com.feelingpalette.feeling_palette`

### 2. 상품 생성
1. 앱 페이지 → **인앱 구입 및 구독 → In-App Purchases**
2. **+** 버튼 → **비소모성(Non-Consumable)** 선택
3. 참조 이름: `Remove Ads`
4. 제품 ID: `remove_ads`
5. 가격: **Tier 2 (₩2,500 / $1.99)** 선택
6. 현지화 정보:
   - 표시 이름: `광고 제거`
   - 설명: 위 표 참고
7. 스크린샷 첨부 (App Store Connect가 검수용으로 요구)

### 3. 테스트 준비
1. App Store Connect → **사용자 및 액세스 → 샌드박스 테스터** 추가
2. 테스트 기기에서 설정 → App Store → 샌드박스 계정으로 로그인
3. TestFlight 빌드에서 구매 시 실제 결제 안 됨

---

## 테스트 시나리오

### 구매 플로우
- [ ] 설정 → "₩2,500에 구매하기" 탭
- [ ] 스토어 결제 시트 뜸 → 승인
- [ ] 구매 완료 후 "구매 완료" 상태 표시
- [ ] 캘린더/통계/타임라인 탭 → **배너 사라짐**
- [ ] 일기 2개 분석해도 **전면 광고 안 뜸**
- [ ] 3개 분석 후 한도 도달 → **리워드 광고는 여전히 표시** (의도된 동작)

### 복원 플로우
- [ ] 같은 계정으로 앱 재설치
- [ ] 자동으로 복원 (앱 시작 시 `restorePurchases()` 실행)
- [ ] 또는 설정 → "구매 복원" 탭 → "구매 내역이 복원되었어요" 토스트
- [ ] 광고 다시 사라지는지 확인

### 결제 취소 플로우
- [ ] 구매 진행 중 "취소" 탭 → 원래 화면 복귀, 버튼 활성 상태 유지
- [ ] 앱 재시작 후에도 광고 정상 표시

---

## 주의 사항

### Play Console 심사
- 앱을 "결제 가능한" 상태로 만들려면 최소 **비공개 내부 테스트 트랙**에 한 번은 배포해야 함
- 정식 출시 전까지 상품은 "활성" 상태여도 테스터만 볼 수 있음

### 가격 변경
- 스토어 콘솔에서 가격 변경 시 **앱 업데이트 없이** 반영됨 (코드엔 가격 하드코딩 안 함)
- 새 가격은 `PremiumService.priceLabel`로 자동 표시됨

### 환불
- Google Play: 구매 후 2시간 내 자동 환불, 이후는 구매자가 Play Store에서 요청
- App Store: Apple에 문의 환불 요청
- **환불되면** 다음번 restorePurchases 호출 시 `isPremium = false`로 돌아가며 광고 재개
  - 현재 구현: restorePurchases 후 premium 기록이 없으면 `_isPremium`을 유지 중 (지금 버전은 복원에서 못 찾아도 local flag 유지 — 악용 여지. 추후 서버 검증 추가 권장)

### 서버 검증 (미구현, 후속)
현재는 스토어 응답을 신뢰하는 클라이언트 검증만. 보안을 높이려면:
1. 구매 후 영수증을 자체 서버로 전송
2. 서버가 Apple/Google API로 영수증 유효성 검증
3. 서버가 OK 응답하면 프리미엄 활성화

솔로 개발·소액 상품이면 지금 구현으로 충분.

---

## 코드 상의 연동 지점

- `lib/services/premium_service.dart` — IAP 상태 관리
- `lib/screens/settings_screen.dart` — 구매 UI (홈 우상단 ⚙ 아이콘 → 설정)
- `lib/widgets/app_lock_gate.dart` — 앱 실행 시 `PremiumService.initialize()` 호출
- `lib/services/ads_service.dart` — `setAdFree(true)` 시 배너·전면 숨김 (리워드는 유지)
