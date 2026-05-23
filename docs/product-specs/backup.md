---
title: Backup — product spec
owner: harness-engineer
status: living
last_verified: 2026-05-23
domain: backup
---

# Backup

사용자가 Google Drive로 일기 데이터를 백업하고, 새 기기에서 복원한다.
앱은 single-device-local (sqflite) + cloud snapshot 모델.

## User stories

1. 사용자는 설정 → 백업 화면에서 "지금 백업" 버튼으로 sqflite DB를
   Google Drive의 앱 전용 폴더에 업로드한다.
2. 사용자는 같은 화면에서 마지막 백업 시각을 본다.
3. 사용자는 새 기기에서 같은 Google 계정으로 로그인 후 "복원" 버튼을 누르면
   클라우드 백업을 다운로드해서 로컬 DB를 덮어쓴다.
4. (선택 — 향후) 자동 백업 (주 1회 백그라운드).

## Out of scope

- iCloud 백업 (Android만 Drive; iOS는 Drive 사용 가능하나 Apple 친화는 아님).
- 백업 암호화 (현재는 Google 계정 보안에 의존).
- selective restore (특정 일기만).

## Acceptance

- 백업 후 같은 계정으로 새 기기에서 정확히 복원된다.
- 복원 시 기존 로컬 데이터는 *덮어씌워짐* — 사용자에게 명시적 확인.
- 백업 실패는 명확한 에러 메시지 (네트워크, 권한, 용량 등).

## API

- Google Drive REST API v3 (앱 전용 폴더 `appDataFolder`).
- 인증은 Google Sign-In + scope `https://www.googleapis.com/auth/drive.appdata`.

## Data

- 업로드: sqflite DB 파일 1개 + 메타데이터 JSON 1개.
- 메타데이터: `{ "version": <app-version>, "timestamp": <ISO>, "device": <model> }`

## Non-functional

- 백업 크기는 일기 수에 비례 (보통 < 1MB).
- 업로드/다운로드 타임아웃 30s.

## 관련

- [docs/GOOGLE_DRIVE_SETUP.md](../GOOGLE_DRIVE_SETUP.md)
- `lib/services/backup_service.dart`, `lib/services/drive_backup_service.dart`
