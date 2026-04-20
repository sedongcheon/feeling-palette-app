# 감정 팔레트 제작기 — 블로그 시리즈

자바 백엔드 개발자가 사이드 프로젝트로 만든 **감정 팔레트(Feeling Palette)** 의 출시까지를 4편으로 나눠 정리한 시리즈입니다. 티스토리 / velog 동시 발행을 가정하고 마크다운으로 작성했습니다.

## 4편 목차

| 번호 | 파일 | 주제 | 주 대상 |
|---|---|---|---|
| 1 | [01-app-making-story.md](./01-app-making-story.md) | Flutter 앱 제작기 | 모바일이 처음인 자바 개발자 |
| 2 | [02-api-fastapi-gemini.md](./02-api-fastapi-gemini.md) | FastAPI + Gemini API | Spring Boot 익숙한 분 |
| 3 | [03-aws-lambda-infra.md](./03-aws-lambda-infra.md) | AWS Lambda + SAM + GitHub Actions OIDC | EC2/ECS는 해봤지만 Lambda 처음 |
| 4 | [04-store-release-checklist.md](./04-store-release-checklist.md) | 앱 등록 & 외부 콘솔 셋업 | 출시 처음 해보는 분 |

## 발행 전 체크리스트

### 1. 이미지 상태

대부분의 이미지는 이미 `../screenshots/android/` 의 기존 스크린샷을 재사용합니다.

| 글 | 사용 이미지 | 출처 |
|---|---|---|
| 1편 | `01-home-ai-result.jpg` | `docs/screenshots/android/` ✅ 있음 |
| 1편 | `02-calendar.jpg` / `03-stats-donut.jpg` / `05-timeline.jpg` | `docs/screenshots/android/` ✅ 있음 |
| 1편 | `04-stats-monthly-ai.jpg` | `docs/screenshots/android/` ✅ 있음 |
| 4편 | `04-console-map.svg` | `docs/blog/images/` ✅ SVG로 그려둠 |

**티스토리/velog 발행 시**: 마크다운 상대 경로(`../screenshots/...`) 대신 각 플랫폼에 이미지를 업로드한 후 발급되는 URL로 치환해주세요.

### 2. SVG → PNG 변환 (티스토리에서 SVG 업로드 안 될 때)
티스토리/velog 모두 보통 SVG를 그대로 업로드하면 이미지로 인식하지만, 안 보이면 PNG로 변환해서 올리세요.

```bash
# rsvg-convert (Homebrew: brew install librsvg)
rsvg-convert -w 1200 docs/blog/images/04-console-map.svg \
  -o docs/blog/images/04-console-map.png

# 또는 macOS Preview에서: SVG 열기 → File → Export → PNG
```

### 3. 시크릿 마스킹 한 번 더 점검
- AdMob 실 ID (`ca-app-pub-` 로 시작): 본문 코드 예시는 `XXXXXXXXXXXXXXXX` 로 치환됨 — OK
- Gemini API 키 (`AQ.Ab8...`): `AQ.********` 로 마스킹됨 — OK
- AWS account ID: `****` 로 마스킹됨 — OK
- 운영 이메일: 본문에 노출 안 됨 — OK
- API 도메인 `feeling-api-aws.sedoli.co.kr`: 공개 도메인이라 그대로 둠 (가리고 싶으면 직접 치환)

### 4. 시리즈 내 링크
각 글의 마지막 "감정 팔레트 제작기 시리즈" 블록에는 형제 글 4개 링크가 들어 있습니다. **티스토리/velog에 발행한 뒤** 이 링크를 실제 게시글 URL로 치환해주세요.

### 5. github 저장소 링크
각 글 메타 블록의 `github 저장소 링크 (TODO: 발행 시 채우기)` 부분도 마찬가지로 발행 시점에 실제 URL로 치환.

## 발행 순서 권장

1. **티스토리** 에 1~4편 순서대로 발행 (각 글 발행 후 URL 확보)
2. **velog** 에도 같은 순서로 발행 (티스토리 URL은 시리즈 내비에 포함시키지 않거나, 캐노니컬 링크로 표기)
3. 4편 모두 발행 후, 각 글의 시리즈 내비 4개 링크를 실제 URL로 일괄 수정

## 분량 참고

| 글 | 글자 수 (코드 포함) | 비고 |
|---|---|---|
| 1편 | ~6,800자 | 코드 5블록 + 표 1개 |
| 2편 | ~9,000자 | 코드 7블록 + 표 3개 (가장 김) |
| 3편 | ~10,000자 | 코드 6블록 + 표 3개 + ASCII 다이어그램 |
| 4편 | ~7,500자 | 표 6개 + 체크리스트 30+ |

본문 한국어만 따지면 각 글당 2,500~3,500자 수준이고, 코드/표/체크리스트가 더해진 결과입니다. 너무 길게 느껴지면 코드 블록을 GitHub 링크로 빼거나, 글 1개를 2개로 분할하는 방식으로 줄일 수 있습니다.
