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
1. `docs/PRIVACY_POLICY_KO.md` 먼저 수정 (git에 이력 남김)
2. 호스팅된 페이지(Notion/GitHub/Google)에도 동일 내용 반영
3. 본문 상단의 "**최종 수정일**" 날짜 갱신
4. 큰 변경(새 데이터 수집 등)은 앱 내 고지 및 사전 안내 필요
