# 개인정보처리방침 호스팅 가이드

`docs/PRIVACY_POLICY_KO.md`를 **공개 URL**로 올리는 방법 정리. AdMob·Play Console·App Store Connect 심사에 이 URL이 필요합니다.

---

## 옵션 비교

| 옵션 | 소요 시간 | 비용 | 장점 | 단점 |
|------|----------|------|------|------|
| **Notion 공개 페이지** ⭐ | 5분 | 무료 | 가장 쉬움, 수정 즉시 반영 | URL이 길고 Notion 브랜딩 |
| **GitHub Pages** | 15분 | 무료 | 개발자답고 소스 관리 | GitHub 계정 필요 |
| **Google Sites** | 10분 | 무료 | 비개발자 친화 | 커스터마이징 제한 |
| **Vercel** | 10분 | 무료 | 커스텀 도메인 가능 | 계정·CLI 설정 |

---

## ⭐ 옵션 A: Notion (가장 추천)

### 절차
1. Notion 새 페이지 생성
2. 제목: **Feeling Palette 개인정보처리방침**
3. `docs/PRIVACY_POLICY_KO.md` 내용을 복붙 (마크다운 그대로 붙이면 Notion이 자동 변환)
4. 우측 상단 "공유(Share)" → "웹에 게시(Publish to web)" **활성화**
5. "검색 엔진 색인 허용(Search engine indexing)" 활성화 (선택이지만 추천)
6. 생성된 URL 복사 → AdMob/Play/App Store에 등록

### URL 예시
```
https://your-workspace.notion.site/Feeling-Palette-XXXXXXXXXX
```

### 주의
- "편집 허용(Allow editing)"은 **꺼둠** (열람만 가능)
- 이후 정책 수정 시 Notion 페이지에서 직접 수정 → URL은 유지됨

---

## 옵션 B: GitHub Pages

### 절차
1. GitHub에서 새 repo 생성 (예: `feeling-palette-privacy`, **Public**)
2. `index.md` 파일 추가 후 `PRIVACY_POLICY_KO.md` 내용 복사
3. Repo 설정 → Pages → Source: `main` branch, `/ (root)`
4. 몇 분 후 URL 생성: `https://<your-username>.github.io/feeling-palette-privacy/`
5. 테마: Jekyll 기본 테마 자동 적용 (깔끔함)

### 장점
- 마크다운 그대로 렌더링
- Git으로 변경 이력 관리
- 개인 도메인 연결 가능

### 다국어(영문) 페이지 추가

이미 한국어 페이지를 GitHub Pages에 호스팅 중이라면 영문판은 **하위 경로** 방식이 가장 간단:

1. 같은 repo에 `en/index.md` 파일 추가
2. `docs/PRIVACY_POLICY_EN.md` 내용을 그대로 붙여넣기
3. 커밋·푸시하면 몇 분 안에 빌드 → URL 자동 생성
   ```
   https://sedongcheon.github.io/feelingpalette-privacy/en/
   ```
4. 한국어 `index.md` 상단에 영문 페이지 링크 1줄 추가 (선택):
   ```markdown
   > [English version](./en/)
   ```
5. 영문 `en/index.md` 상단에도 한국어 페이지 링크:
   ```markdown
   > [한국어 버전](../)
   ```

### 등록 (영문 페이지)

| 위치 | URL |
|------|-----|
| App Store Connect → English (US) locale → Privacy Policy URL | `https://sedongcheon.github.io/feelingpalette-privacy/en/` |
| Play Console → English store listing → Privacy policy | (위와 동일) |
| AdMob 대시보드 | 한국어 페이지만 등록해도 OK (광고 정책은 locale-specific 요구 없음) |

> Apple은 각 locale마다 별도 URL 등록 가능. Google Play는 단일 URL이지만 영문 페이지가 있으면 영문 시장 심사·이용자 신뢰에 유리.

---

## 옵션 C: Google Sites

### 절차
1. <https://sites.google.com> 접속
2. 새 사이트 만들기 → 빈 사이트 선택
3. 페이지 제목: **Feeling Palette Privacy Policy**
4. 마크다운 내용을 Google Docs에 먼저 붙여 서식 정리 → 사이트에 복사
5. 우측 상단 "게시(Publish)" → 웹 주소 지정 → 공개 설정
6. URL: `https://sites.google.com/view/your-site-name`

---

## 등록해야 할 곳

```
1. AdMob 대시보드 → 앱 설정 → 개인정보처리방침 URL 입력
2. Google Play Console → 앱 콘텐츠 → 개인정보처리방침 URL 입력
3. App Store Connect → 앱 정보 → 개인정보처리방침 URL 입력
4. (iOS) Info.plist의 UMP 관련 메타데이터에도 참조 가능
```

---

## 체크리스트

- [ ] 옵션 중 하나 선택
- [ ] 페이지 게시 완료
- [ ] **브라우저 시크릿 모드**에서 URL 접속 → 정상 표시 확인 (로그인 없이 열려야 함)
- [ ] 메일 링크 (`sedong1000@gmail.com`) 클릭하면 메일 앱 열리는지 확인
- [ ] AdMob 대시보드에 URL 등록 → 광고 게재 정책 경고 사라지는지 확인

---

## 정책 수정 시

추후 수정 필요하면:
1. `docs/PRIVACY_POLICY_KO.md`와 `docs/PRIVACY_POLICY_EN.md` **동시 수정** (parity 유지, git에 이력)
2. 호스팅된 페이지(Notion/GitHub/Google)의 ko + en **양쪽 모두** 갱신
3. 본문 상단의 "**최종 수정일 / Last updated**" 날짜 갱신
4. 큰 변경(새 데이터 수집 등)은 앱 내 고지 및 사전 안내 필요

### parity 체크 항목
- 발효일 / Effective date
- 수집 정보 / Data we collect
- 제3자 서비스 / Third-party services
- 연락처 / Contact
- 아동 연령 기준 (KO: 만 14세, EN: 13/16/14 다중 기준)
