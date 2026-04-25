# AWS 인프라 사용 내역

Feeling Palette 앱이 사용하는 AWS 서비스 정리. 자체 운영 서버는 Anthropic Claude API 키 보호 + AI 호출 프록시 용도로만 사용. 사용자 데이터는 모두 클라이언트 SQLite + Google Drive(사용자 본인 계정)에 저장하므로 서버에 저장되지 않음.

---

## 도메인 / 엔드포인트

- **커스텀 도메인**: `https://feeling-api-aws.sedoli.co.kr`
- **CNAME 대상**: `d-2gc7ye9t7b.execute-api.ap-northeast-2.amazonaws.com`
- **리전**: `ap-northeast-2` (서울)

---

## 사용 중인 AWS 서비스

### 1. Amazon API Gateway
- **확인 방법**: DNS CNAME이 `*.execute-api.*.amazonaws.com` 형태
- **타입**: REST API (Custom Domain 매핑)
- **용도**: 클라이언트 → AWS Lambda 함수 진입점

### 2. AWS Lambda (추정)
- API Gateway 뒤에 일반적으로 사용되는 백엔드
- Anthropic Claude API를 서버리스로 호출하기 위한 프록시 함수
- API 키(`ANTHROPIC_API_KEY` 등)를 Lambda 환경변수에 저장 → 클라이언트에는 노출 안 됨
- 클라이언트가 보유한 `.env.json`의 `API_TOKEN`은 자체 발급한 인증 토큰일 가능성

### 3. AWS Certificate Manager (ACM)
- 커스텀 도메인 HTTPS 인증서
- 무료 자동 갱신

### 4. 도메인 / DNS
- `sedoli.co.kr` 도메인 보유 (가비아 등 한국 도메인 등록업체로 추정)
- **Route 53 사용 여부 확인 필요** — 등록업체 자체 DNS 또는 Route 53 둘 다 가능

### 5. CloudWatch Logs (자동)
- Lambda 사용 시 자동 활성화
- 함수 실행 로그 보관

### 6. IAM (자동)
- Lambda 실행 역할
- API Gateway → Lambda 호출 권한

---

## 호출되는 API 엔드포인트

| 메서드 | 경로 | 클라이언트 호출 위치 |
|---|---|---|
| `POST` | `/api/diary/analyze` | `lib/services/emotion_analyzer.dart` — 일기 감정 분석 |
| `POST` | `/api/month/summarize` | `lib/services/month_summary_service.dart` — 월간 AI 요약 |
| `POST` | `/api/insights/weekly` | `lib/services/weekly_insight_service.dart` — 주간 감정 인사이트 |

---

## 사용하지 않는 AWS 서비스

| 서비스 | 사용 안 하는 이유 |
|---|---|
| **EC2 / ECS / Fargate** | 서버리스(API Gateway + Lambda)만 사용. 상시 가동 인스턴스 없음 |
| **S3** | 사용자 파일 저장 안 함. 일기 데이터는 기기 SQLite + Google Drive(개인 앱 폴더) |
| **RDS / DynamoDB / Aurora** | 서버 측 DB 없음. 모든 사용자 데이터 클라이언트 보관 |
| **Amazon Cognito** | 자체 인증 사용 안 함. 앱 잠금은 PIN/생체인증(로컬), Google Sign-In은 Google 직접 호출 |
| **CloudFront** | API Gateway 자체로 커버됨. 정적 자산 CDN 불필요 |
| **SES / SNS** | 이메일/푸시 알림 없음 |
| **EventBridge / SQS** | 비동기 큐 작업 없음 |

---

## 클라이언트가 직접 호출하는 외부 API (AWS 무관)

- **Google Drive API**: 사용자 본인 계정으로 일기 백업/복원 (`googleapis`, `extension_google_sign_in_as_googleapis_auth`)
- **Apple StoreKit**: iOS 인앱결제 (`in_app_purchase`)
- **Google Play Billing**: Android 인앱결제 (`in_app_purchase`)
- **Google AdMob**: 광고 (`google_mobile_ads`)
- **Google UMP (User Messaging Platform)**: GDPR/CCPA 동의 (`google_mobile_ads` 내장)

---

## 데이터 흐름

```
[사용자 기기]
    │
    ├─ SQLite (일기, 분석 결과, 월간 요약, 주간 인사이트)
    ├─ flutter_secure_storage (PIN 해시, 설정)
    │
    ├─ HTTPS POST → API Gateway (sedoli.co.kr) → Lambda → Anthropic Claude API
    │   (일기 텍스트 전송 → AI 분석 결과 수신, 서버에 저장 안 됨)
    │
    ├─ HTTPS → Google Drive API (사용자 OAuth)
    │   (백업 파일을 사용자 본인 Drive 앱 폴더에 저장)
    │
    └─ Apple/Google 결제·광고 SDK
```

---

## 보안 / 비용 메모

- AI API 키는 **AWS Lambda 환경변수**에 저장돼 있어 클라이언트에 노출되지 않음
- 클라이언트의 `API_TOKEN`(`.env.json`)은 자체 발급한 호출 인증 토큰 — Lambda에서 검증해 무단 호출 차단
- 비용 구조: API Gateway 호출 수 + Lambda 실행 시간 + Anthropic API 사용료
- ECS / RDS 같은 상시 가동 리소스 없음 → 사용량 비례 과금 (대부분 프리티어 가능 수준)

---

## 확인되지 않은 항목 (운영 환경 직접 확인 필요)

- 정확한 Lambda 함수 이름 / 런타임 (Python? Node.js?)
- API Gateway 사용량 플랜 / API Key 정책
- Anthropic API 호출 중계 외 다른 통합 (캐싱, 로깅 분석 등)
- WAF / Shield 등 보안 서비스 적용 여부
- Route 53 사용 여부 (도메인 등록업체에서 직접 CNAME 설정했을 수도)

위 내용은 클라이언트 코드와 DNS 추적만으로 파악한 결과입니다. AWS 콘솔에서 직접 확인하면 더 정확한 인프라 구성을 파악할 수 있습니다.
