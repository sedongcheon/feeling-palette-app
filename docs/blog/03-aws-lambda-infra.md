# NAS에서 AWS Lambda로 — Serverless 감정 분석 인프라 구축기

> **이 글의 대상**: 자바로 EC2/ECS는 만져봤지만 Lambda/SAM은 낯선 분, 사이드 프로젝트 인프라비를 거의 0원으로 만들고 싶은 분
> **읽는 데 걸리는 시간**: 약 10분
> **시리즈**: 감정 팔레트 제작기 (3/4)
> **소스**: github 저장소 링크 (TODO: 발행 시 채우기)

[2편](./02-api-fastapi-gemini.md)에서 만든 FastAPI 서버는 처음에는 집에 있는 Synology NAS 위에서 Docker로 돌고 있었습니다. 잘 돌긴 했지만 운영하면서 점점 피로가 쌓였고, 결국 **AWS Lambda + SAM + GitHub Actions OIDC** 조합으로 옮겼습니다. 이 글은 그 마이그레이션의 처음부터 끝까지입니다.

---

## 1. 왜 NAS에서 옮겼나

NAS 운영에는 다음과 같은 만성 피로가 있었습니다.

- **전력비** — 24/365 켜두는 NAS의 한 달 전기료가 사이드 프로젝트의 의의를 갉아먹습니다.
- **고정 IP / 도메인** — 가정용 인터넷의 IP가 바뀌면 DDNS 갱신, 라우터 포트포워딩, Nginx 설정을 다시 손봐야 합니다.
- **다운타임** — 정전·재부팅 한 번에 서비스 중단. 모니터링도 직접 짜야 합니다.
- **확장성** — 갑자기 트래픽이 늘면 NAS CPU가 그대로 터집니다.

반면 Lambda는:

| 항목 | NAS | AWS Lambda |
|---|---|---|
| 운영 비용 | 전기료 + 시간 | 월 ~$0.05 (Year 1 무료 한도 내) |
| 가용성 | 정전·재부팅 시 다운 | AZ 분산 + 자동 복구 |
| 스케일링 | CPU 한계 = 끝 | 1000+ 동시 호출 자동 |
| 모니터링 | Grafana 직접 구축 | CloudWatch 기본 탑재 |
| 배포 | SSH + docker run | `git push` 한 번 |

---

## 2. 선택한 구성도

전체 흐름을 한 장으로 그리면 이렇습니다.

```
[Flutter 앱]
    │  HTTPS
    ▼
[Route53 / 가비아 DNS] ──┐
                          │
                  [ACM (SSL)]
                          │
                          ▼
            [API Gateway (HTTP API v2)]
                          │  throttling 10rps / burst 20
                          ▼
              [Lambda (Container, arm64)]
              FastAPI + Mangum 어댑터
                          │
                ┌─────────┴─────────┐
                ▼                   ▼
        [Gemini API]        [CloudWatch Logs]
                                    │
                                    ▼
                            [CloudWatch Alarm]
                                    │  에러율 > 5%
                                    ▼
                                [SNS] ──→ Email
```

핵심 포인트:

- **API Gateway HTTP API v2** (REST API 아님) — 같은 기능에 50% 저렴
- **Lambda Container Image** — zip 250MB 한도를 우회하기 위해 컨테이너로
- **arm64 (Graviton2)** — x86_64 대비 20% 저렴, 성능은 동등 이상
- **CloudWatch Composite Alarm** — 에러율 % 기반 (단순 에러 카운트 X)
- **시크릿은 SSM SecureString** — 코드/Git/Lambda 환경변수에 평문 노출 X

---

## 3. Container Image on Lambda

기존 Dockerfile은 NAS용 uvicorn 서버였는데, Lambda용은 별도로 둡니다.

```dockerfile
# Dockerfile.lambda
FROM public.ecr.aws/lambda/python:3.11

COPY requirements.txt ${LAMBDA_TASK_ROOT}/
RUN pip install --no-cache-dir -r ${LAMBDA_TASK_ROOT}/requirements.txt

COPY *.py ${LAMBDA_TASK_ROOT}/

CMD ["lambda_handler.handler"]
```

`lambda_handler.py` 는 단 5줄. **Mangum** 이라는 어댑터가 FastAPI(ASGI)를 Lambda 이벤트로 변환해줍니다.

```python
from mangum import Mangum
from main import app

handler = Mangum(app, lifespan="off")
```

자바로 비유하면 **"Servlet API → Lambda Event 변환기"** 입니다. Spring Cloud Function의 `FunctionAdapter` 와 같은 역할이라고 보면 됩니다. 덕분에 코드 변경 없이 같은 FastAPI 앱이 Lambda에서도 그대로 돕니다.

### arm64 빌드의 함정

로컬이 Apple Silicon이면 자연스럽게 arm64지만, 인텔 Mac이나 GitHub Actions(`ubuntu-latest`)에서는 명시적으로 빌드 플랫폼을 지정해야 합니다.

```bash
docker buildx build \
  --platform linux/arm64 \
  --provenance=false \
  -f Dockerfile.lambda \
  -t feeling-palette-lambda:local .
```

`--provenance=false` 가 빠지면 ECR에 OCI 이미지 인덱스가 올라가서 Lambda가 "이미지를 못 찾는다" 에러를 뱉습니다. 이거 모르고 30분 헤맸습니다.

---

## 4. `template.yaml` (SAM IaC) 핵심 5개 리소스

SAM은 **"AWS 전용으로 가볍게 만든 Terraform"** 이라고 보면 됩니다. CloudFormation YAML 위에 서버리스 단축 문법을 얹은 것이고, AWS CLI에 통합돼 있어 별도 설치가 거의 필요 없습니다.

### (1) Lambda 함수

```yaml
FeelingPaletteFunction:
  Type: AWS::Serverless::Function
  Properties:
    FunctionName: feeling-palette-api
    PackageType: Image
    ImageUri: !Ref ImageUri
    Architectures: [arm64]
    MemorySize: 512
    Timeout: 30
    Environment:
      Variables:
        GEMINI_API_KEY: !Ref GeminiApiKey
    Events:
      Analyze:
        Type: HttpApi
        Properties:
          ApiId: !Ref FeelingPaletteApi
          Path: /api/diary/analyze
          Method: POST
      Catchall:
        Type: HttpApi
        Properties:
          ApiId: !Ref FeelingPaletteApi
          Path: /{proxy+}
          Method: ANY
```

`Catchall` 이벤트로 모든 경로를 한 Lambda에 흘려보내서, FastAPI 라우팅이 그대로 살아 있습니다.

### (2) HTTP API + 요청 제한

```yaml
FeelingPaletteApi:
  Type: AWS::Serverless::HttpApi
  Properties:
    StageName: $default
    DefaultRouteSettings:
      ThrottlingRateLimit: 10       # 초당 평균 10
      ThrottlingBurstLimit: 20      # 순간 최대 20
```

10rps × 60초 × 60분 × 24시간 = **하루 86,400 호출 한도** 입니다. 사이드 프로젝트로는 차고 넘치고, 누군가 폭주시키더라도 비용 폭탄을 막아줍니다.

### (3) 로그 그룹 (보존 기간 7일)

```yaml
FeelingPaletteFunctionLogGroup:
  Type: AWS::Logs::LogGroup
  Properties:
    LogGroupName: !Sub /aws/lambda/${FeelingPaletteFunction}
    RetentionInDays: 7
```

기본은 무한 보관이라, 명시적으로 7일로 자르면 CloudWatch 비용이 0에 수렴합니다.

### (4) SNS 알람 토픽

```yaml
AlertTopic:
  Type: AWS::SNS::Topic
  Properties:
    TopicName: feeling-palette-alerts
    Subscription:
      - Protocol: email
        Endpoint: !Ref AlertEmail
```

### (5) 에러율 알람 (Composite expression)

```yaml
ErrorRateAlarm:
  Type: AWS::CloudWatch::Alarm
  Properties:
    Metrics:
      - Id: errorRate
        Expression: IF(invocations > 0, 100 * errors / invocations, 0)
        ReturnData: true
      - Id: errors
        MetricStat: { Metric: { Namespace: AWS/Lambda, MetricName: Errors, ... } }
        ReturnData: false
      - Id: invocations
        MetricStat: { Metric: { Namespace: AWS/Lambda, MetricName: Invocations, ... } }
        ReturnData: false
    Threshold: 5
    ComparisonOperator: GreaterThanThreshold
```

단순 "에러 N건 이상" 이 아니라, **"5분 동안 에러율이 5%를 넘으면"** 으로 잡습니다. 호출이 많은 순간엔 한두 건 에러는 노이즈고, 호출이 적은 순간엔 한 건도 의미 있을 수 있어서 비율이 가장 합리적입니다.

---

## 5. 시크릿 관리의 진화

| 단계 | 보관 위치 | 문제 |
|---|---|---|
| 초기 | `.env` 파일 (로컬) | 깃에 실수로 올라갈 위험 |
| NAS 시기 | Jenkins Credentials | 콘솔 한 곳에 묶임, 백업 어려움 |
| AWS 시기 | **SSM Parameter Store (SecureString, KMS 암호화)** | IAM 권한 + 감사 로그 + 자동 복호화 |

등록은 한 번만:

```bash
aws ssm put-parameter \
  --name /feeling-palette/gemini-api-key \
  --value "AQ.********" \
  --type SecureString \
  --region ap-northeast-2
```

배포할 때 GitHub Actions가 이 값을 읽어 SAM 파라미터로 주입합니다. 코드에도, Git 히스토리에도, Lambda 콘솔의 환경변수 평문 입력에도 키가 노출되지 않습니다.

---

## 6. GitHub Actions + OIDC — 키 없는 배포

가장 큰 보안 개선은 **AWS Access Key를 GitHub Secrets에 저장하지 않는** 것입니다. OIDC federation으로 GitHub Actions가 IAM 역할을 직접 떠맡습니다.

```yaml
permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::****:role/github-actions-feeling-palette
          aws-region: ap-northeast-2

      - name: Login to Amazon ECR
        id: ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build and push Lambda image
        run: |
          IMAGE=${{ steps.ecr.outputs.registry }}/feeling-palette:${{ github.sha }}
          docker buildx build \
            --platform linux/arm64 \
            --provenance=false \
            -f Dockerfile.lambda \
            -t "$IMAGE" \
            --push .
          echo "IMAGE_URI=$IMAGE" >> "$GITHUB_ENV"

      - name: Fetch Gemini API key from SSM
        run: |
          KEY=$(aws ssm get-parameter \
            --name /feeling-palette/gemini-api-key \
            --with-decryption \
            --query 'Parameter.Value' --output text)
          echo "::add-mask::$KEY"
          echo "GEMINI_API_KEY=$KEY" >> "$GITHUB_ENV"

      - name: SAM deploy
        run: |
          sam deploy --template-file template.yaml \
            --stack-name feeling-palette \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides ImageUri=$IMAGE_URI GeminiApiKey=$GEMINI_API_KEY \
            --resolve-s3 --no-confirm-changeset --no-fail-on-empty-changeset

      - name: Smoke test
        run: |
          for i in 1 2 3 4 5; do
            sleep 5
            response=$(curl -sS -X POST "https://feeling-api-aws.sedoli.co.kr/api/diary/analyze" \
              -H 'Content-Type: application/json' \
              -d '{"content":"배포 확인"}' || true)
            echo "$response" | grep -q '"primary_emotion"' && echo "passed" && exit 0
          done
          echo "smoke test failed"; exit 1
```

핵심 단계:

1. **OIDC 인증** — `id-token: write` 권한으로 GitHub이 발급한 토큰을 AWS에 제출
2. **ECR 로그인 → buildx → push** — `:latest` + `:sha` 태그를 동시에 (롤백용)
3. **SSM에서 시크릿 복호화** — `::add-mask::` 로 로그에서 마스킹
4. **`sam deploy`** — CloudFormation 차이만 적용 (변경 없으면 통과)
5. **Smoke test** — 실제 도메인에 5회 재시도 호출 후 응답 확인

OIDC trust policy 설정 한 번만 까다롭고, 그 이후는 키 갱신·로테이션 걱정이 없습니다.

---

## 7. 비용 정리 — 한 달 약 100원

월 1,000건 호출 기준입니다.

| 항목 | 비용 |
|---|---|
| Lambda compute (512MB × 2초 × 1,000) | $0 (Year 1 무료 400K GB-s) |
| Lambda 요청 (1,000) | $0 (Year 1 무료 1M) |
| API Gateway HTTP API | $0 (12개월 무료 1M) |
| ECR storage (~500MB) | ~$0.05 |
| CloudWatch Logs (5GB 무료) | $0 |
| SSM SecureString | $0 |
| ACM 인증서 | $0 |
| **AWS 합계** | **~$0.05** |
| Gemini API (분석 1,000회 + 요약 30회) | ~$0.02 |
| **총합** | **약 100원** |

스타벅스 라떼가 6,500원이라 치면, 한 잔 값으로 **약 5년 4개월** 돌릴 수 있는 셈입니다. NAS 전기료가 더 비쌌습니다.

---

## 8. 미리 알았으면 좋았을 것 두 가지

**(1) `--provenance=false` 는 처음부터 붙이자.**
앞서 언급한 그 함정. 빌드/푸시까지 잘 되는데 Lambda 콘솔에서 `Image not found` 만 뜨면 `docker buildx imagetools inspect <이미지>` 로 manifest 형태부터 확인하세요. OCI image index 가 보이면 `--provenance=false` 누락이 원인입니다. Lambda는 단일 manifest 만 받습니다.

**(2) OIDC trust policy 디버깅은 무조건 CloudTrail 부터.**
GitHub Actions가 `AssumeRoleWithWebIdentity` 를 호출할 때 trust policy 의 `sub` 조건이 한 글자라도 어긋나면 통째로 거부됩니다(repo 이름, 브랜치 이름, `:ref:refs/heads/`/`:environment:` 같은 prefix까지 정확해야 함). 워크플로 로그는 단순히 `Could not assume role` 만 알려주니, AWS CloudTrail 의 `AssumeRoleWithWebIdentity` 이벤트에서 실제 거부 사유를 봐야 빠르게 잡을 수 있습니다.

---

## 마치며

이걸로 **백엔드 / 인프라 / 자동 배포 / 모니터링** 까지 한 묶음이 끝났습니다. 마지막 4편은 한 발짝 떨어져서, **"이 모든 걸 굴리려면 외부 콘솔 5~6개를 어떻게 셋업해야 하는가"** 를 한 번에 정리합니다. Gemini, GCP, Play Console, AdMob, Apple Developer, AWS — 각 콘솔에서 무엇을 받아 어디에 넣는지 지도를 그려볼 거예요.

---

### 🎨 감정 팔레트 제작기 시리즈

- [1편: AI 감정일기 앱 제작기 (Flutter)](./01-app-making-story.md)
- [2편: 감정 분석 API (FastAPI + Gemini)](./02-api-fastapi-gemini.md)
- **3편: AWS Lambda 인프라 (NAS → Serverless 마이그레이션)** ← 현재 글
- 4편: 앱 등록 & 외부 콘솔 셋업 총정리
