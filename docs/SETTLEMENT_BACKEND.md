# SMTM(정산표) 백엔드 — 설계 + API 계약 (v1)

> **이 문서가 정산표 서버/클라이언트의 공유 계약서다.** 계약을 바꿔야 하면
> **먼저 이 문서를 고치고** 양쪽에 반영한다. (이 문서 = 정답)
>
> 방명록과 **같은 Worker · 같은 D1**을 쓴다(`api.pure-blanche.com`).
> 인프라/CORS/에러 포맷/배포 절차는 [GUESTBOOK_BACKEND.md](./GUESTBOOK_BACKEND.md)를 따른다.

## 1. 목표

- 정산 프로젝트를 **여러 사람이 링크 하나로 공유**하고, 각자 자기 페이지에서
  "입금했습니다"를 눌러 **같은 원장에 반영**한다.
- 로그인 없음. **공유 코드를 아는 사람 = 참여자**로 본다(소규모 신뢰 그룹 전제).
- 백엔드가 죽어도 사이트의 나머지는 100% 정상. 정산표만 에러 카드를 띄운다.

## 2. 공유·권한 모델

```
프로젝트 생성 → 서버가 공유 코드(code) + 소유자 토큰(ownerToken) 발급
             → 링크 https://pure-blanche.com/#/settlement/<code> 를 참여자에게 공유
```

| 주체 | 할 수 있는 일 |
|------|--------------|
| **코드 소지자**(참여자 전원) | 조회, 지출 추가/수정/삭제, 인원 추가/수정/삭제, 송금 기록, **입금 처리** |
| **소유자**(`ownerToken` 보유, 생성한 브라우저) | 위 전부 + **프로젝트 삭제** |
| **관리자**(`ADMIN_TOKEN`) | 전부 + 프로젝트 삭제 |

### 비밀 프로젝트 (암호 잠금)

여행처럼 참여 인원이 정해진 정산은 **링크만으로는 부족**하다. 생성 시 암호를 걸면
링크를 알아도 암호를 넣어야 열린다.

```
생성(password 포함) → pass_salt/pass_hash 저장 + accessToken 발급
링크로 접근 → 401 password_required → POST /unlock {password} → accessToken
이후 모든 요청 → Authorization: Bearer <accessToken>
```

- 암호는 **원문을 저장하지 않는다**. 프로젝트마다 다른 솔트로 `PBKDF2-SHA256 100,000회`.
- `accessToken = SHA-256(IP_SALT + ":access:" + project_id + ":" + pass_hash)`.
  서버 시크릿이 있어야 만들 수 있고, 암호가 바뀌면 `pass_hash` 가 바뀌어 **예전 열쇠는 저절로 무효**가 된다.
  덕분에 토큰 테이블이 필요 없다.
- 잠긴 프로젝트는 **조회도 편집도** 열쇠가 필요하다(읽기만 열어두면 잠금의 의미가 없다).
  `ownerToken` 과 `ADMIN_TOKEN` 도 열쇠로 통한다.
- 401 응답에는 정산표 **이름만** 함께 준다 — 암호 입력 화면에 "무엇을 여는 중인지" 보여주기 위해서다.
- 암호는 잊으면 복구 수단이 없다(관리자 삭제만 가능). UI에서 그 사실을 안내한다.

- `code`: 8자, 혼동 문자를 뺀 알파벳 `abcdefghjkmnpqrstuvwxyz23456789` 에서 무작위.
  추측 저항이 목적이지 기밀은 아니다. **민감한 금액을 다루는 용도로 홍보하지 않는다.**
- `ownerToken`: 32자 무작위 hex. 서버는 **SHA-256 해시만** 저장(`owner_hash`).
  생성한 브라우저의 localStorage에 보관하며, 잃어버리면 삭제는 관리자만 가능하다.
- 소유자/관리자 인증은 `Authorization: Bearer <토큰>` 한 헤더로 받고,
  `owner_hash` 일치 또는 `ADMIN_TOKEN` 일치면 통과한다.

## 3. API 계약

Base URL은 방명록과 동일(`https://api.pure-blanche.com`, 로컬 `http://localhost:8787`).
에러 응답 형태도 동일: `{ "error": "<코드>", "detail": "<한국어 문구>" }`.

**모든 변경 요청은 성공 시 갱신된 프로젝트 전체(`{ "project": {...} }`)를 돌려준다.**
클라이언트는 응답으로 상태를 통째로 교체하면 되므로, 여러 명이 동시에 눌러도
마지막 응답이 곧 최신 상태다(잃어버린 갱신을 화면에 남기지 않는다).

### 3.1 프로젝트 객체

```json
{
  "id": "1f0c…",
  "code": "k3m8qr2t",
  "name": "2월 강릉 여행",
  "createdAt": "2026-08-13T04:11:22Z",
  "updatedAt": "2026-08-13T06:20:01Z",
  "members":  [{ "id": "…", "name": "블랑쉬" }],
  "expenses": [{
    "id": "…", "title": "1차 삼겹살", "amount": 97000,
    "payerId": "…", "participantIds": ["…","…"],
    "createdAt": "2026-08-13T04:12:00Z"
  }],
  "transfers": [{
    "id": "…", "fromId": "…", "toId": "…", "amount": 50000,
    "memo": "계좌이체", "createdAt": "2026-08-13T05:00:00Z"
  }],
  "locked": false,
  "settledLegs": ["<expenseId>::<debtorId>"]
}
```

- `locked`: 비밀 프로젝트 여부. 잠긴 프로젝트는 열쇠가 있어야 이 객체 자체를 받을 수 있다.

- 모든 시각은 **UTC ISO8601 `…Z`**. 클라이언트가 로컬 시간으로 변환한다.
- 금액은 **원 단위 정수**. 분할 계산은 전부 클라이언트(`engine.dart`)가 하고,
  서버는 원장만 보관한다 — 계산 규칙을 한 곳에만 둔다.
- `members` 순서 = 입력 순서(`sort_order`). 분할 나머지 배분이 이 순서를 따르므로 보존한다.

### 3.2 엔드포인트

| 메서드 | 경로 | 인증 | 본문 | 성공 |
|--------|------|------|------|------|
| POST | `/api/settlement` | — | `{name, members:[string], password?}` | **201** `{project, ownerToken, accessToken}` |
| POST | `/api/settlement/:code/unlock` | — | `{password}` | 200 `{project, accessToken}` / 401 `bad_password` |
| GET | `/api/settlement/:code` | 잠금 시 필요 | — | 200 `{project}` |
| PATCH | `/api/settlement/:code` | — | `{name}` | 200 `{project}` |
| DELETE | `/api/settlement/:code` | 소유자/관리자 | — | 200 `{ok:true, deleted:"<code>"}` |
| POST | `/api/settlement/:code/members` | — | `{name}` | 200 `{project}` |
| PATCH | `/api/settlement/:code/members/:id` | — | `{name}` | 200 `{project}` |
| DELETE | `/api/settlement/:code/members/:id` | — | — | 200 `{project}` |
| POST | `/api/settlement/:code/expenses` | — | `{title, amount, payerId, participantIds}` | 200 `{project}` |
| PATCH | `/api/settlement/:code/expenses/:id` | — | 위와 동일(전체 교체) | 200 `{project}` |
| DELETE | `/api/settlement/:code/expenses/:id` | — | — | 200 `{project}` |
| POST | `/api/settlement/:code/transfers` | — | `{fromId, toId, amount, memo?, applied?, legs?}` | 200 `{project}` |
| DELETE | `/api/settlement/:code/transfers/:id` | — | — | 200 `{project}` |
| PUT | `/api/settlement/:code/legs` | — | `{legs:[{expenseId, debtorId}], settled:bool}` | 200 `{project}` |

- `PUT …/legs` 가 **"입금했습니다"** 다. `settled:false` 면 취소. `legs` 는 1~200개.
- **비밀 프로젝트**면 `/unlock` 을 뺀 모든 경로가 `Authorization: Bearer <accessToken>` 을 요구한다.
  없으면 **401 `password_required`** (+ `name`).
- `PATCH …/expenses/:id` 로 참여자에서 빠진 사람의 입금 처리 기록은 **함께 삭제**된다
  (근거가 사라진 정산 표시를 남기지 않는다). 프론트 `updateExpense` 와 같은 규칙.
- `DELETE …/expenses/:id` 는 해당 지출의 입금 처리 기록도 함께 지운다.
- **송금은 채무 건과 한 몸으로 기록한다.** `POST …/transfers` 의 `legs` 는 이 송금이
  덮는 건들이고 `applied` 는 거기 붙은 금액이다. 서버는 둘을 한 배치로 처리해
  송금 기록과 건 정산이 갈라지지 않게 한다. 어떤 건이 덮이는지는 분할 규칙을 아는
  **클라이언트가 계산**하고(`engine.dart` 의 `coverageOf`), 서버는 정합성만 본다
  (실재하는 건인지, 채무자가 보낸 사람이 맞는지, `applied ≤ amount` 인지).

### 3.3 에러 코드

| status | error | 조건 | detail |
|--------|-------|------|--------|
| 400 | `invalid_json` | 본문이 JSON 아님 | 잘못된 요청입니다. |
| 400 | `empty` | 필수 값 공백 | 필요한 값을 입력해주세요. |
| 400 | `too_long` | 길이 초과(아래 4.2) | 입력이 너무 깁니다. |
| 400 | `bad_amount` | 금액이 1~99,999,999 정수 아님 | 금액이 올바르지 않습니다. |
| 400 | `bad_member` | payer/참여자/송금 대상이 이 프로젝트 인원이 아님 | 인원 정보가 올바르지 않습니다. |
| 400 | `bad_request` | 그 외 형식 오류(빈 참여자, from==to 등) | 요청이 올바르지 않습니다. |
| 400 | `bad_password` | 암호가 4~32자가 아님(생성 시) | 암호는 4~32자로 입력해주세요. |
| 401 | `password_required` | 비밀 프로젝트에 열쇠 없이 접근 | 암호가 필요한 정산표입니다. |
| 401 | `bad_password` | `/unlock` 암호 불일치 | 암호가 올바르지 않습니다. |
| 401 | `unauthorized` | 소유자/관리자 인증 실패 | 권한이 없습니다. |
| 404 | `not_found` | 코드/항목 없음 | 정산표를 찾을 수 없습니다. |
| 409 | `member_in_use` | 지출·송금에 얽힌 인원 삭제 시도 | 지출에 참여한 인원은 삭제할 수 없습니다. |
| 409 | `limit_exceeded` | 프로젝트당 상한 초과(4.2) | 한도를 초과했습니다. |
| 429 | `too_fast` | 같은 IP가 10초 내 프로젝트 재생성 | 잠시 후 다시 시도해주세요. |
| 429 | `daily_limit` | 같은 IP가 24h 내 프로젝트 30개 초과 | 하루 생성 한도를 초과했습니다. |
| 500 | `server_error` | 내부 오류 | 서버 오류가 발생했습니다. |

## 4. 데이터 / 검증

### 4.1 D1 스키마 (`backend/schema.sql` 에 추가)

```sql
CREATE TABLE IF NOT EXISTS settle_projects (
  id         TEXT PRIMARY KEY,
  code       TEXT NOT NULL UNIQUE,
  name       TEXT NOT NULL,
  owner_hash TEXT,                                    -- SHA-256(ownerToken)
  pass_salt  TEXT,                                    -- 비밀 프로젝트: 솔트(hex). NULL이면 공개
  pass_hash  TEXT,                                    -- 비밀 프로젝트: PBKDF2-SHA256(암호, 솔트)
  ip_hash    TEXT,                                    -- 생성자 IP 해시(rate limit용)
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS settle_members (
  id TEXT PRIMARY KEY, project_id TEXT NOT NULL,
  name TEXT NOT NULL, sort_order INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS settle_expenses (
  id TEXT PRIMARY KEY, project_id TEXT NOT NULL,
  title TEXT NOT NULL, amount INTEGER NOT NULL,
  payer_id TEXT NOT NULL, participants TEXT NOT NULL,  -- JSON 배열
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS settle_transfers (
  id TEXT PRIMARY KEY, project_id TEXT NOT NULL,
  from_id TEXT NOT NULL, to_id TEXT NOT NULL,
  amount INTEGER NOT NULL,
  applied INTEGER NOT NULL DEFAULT 0,   -- 특정 채무 건에 붙은 금액
  memo TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS settle_legs (          -- "입금했습니다" 처리 기록
  project_id TEXT NOT NULL, expense_id TEXT NOT NULL, debtor_id TEXT NOT NULL,
  settled_at TEXT NOT NULL DEFAULT (datetime('now')),
  PRIMARY KEY (project_id, expense_id, debtor_id)
);
```

전부 `IF NOT EXISTS` 라 기존 원격 DB에 `schema.sql` 을 다시 실행해도 안전하다
(방명록 테이블/데이터는 건드리지 않는다).

> ⚠️ **`pass_salt`/`pass_hash` 는 기존 DB에 자동으로 안 생긴다.** `CREATE TABLE IF NOT EXISTS`
> 는 이미 있는 테이블에 컬럼을 추가하지 않는다. 이미 `settle_projects` 가 만들어진 DB에는
> **한 번** 마이그레이션을 돌린다:
> ```bash
> npx wrangler d1 execute pure-blanche-guestbook --remote \
>   --file=./migrate_settlement_password.sql
> ```
> 두 번째 실행은 "duplicate column name" 에러가 난다(정상).
> `settle_transfers.applied` 도 마찬가지라 `migrate_transfer_applied.sql` 을 한 번 더 돌린다.

### 4.2 검증 · 상한

| 항목 | 규칙 |
|------|------|
| 프로젝트 이름 | trim 후 1~40자 |
| 인원 이름 | trim 후 1~12자 |
| 인원 수 | 생성 시 2~30명, 이후 최대 30명 |
| 지출 항목명 | trim 후 1~30자 |
| 금액 | 1 ~ 99,999,999 정수 |
| 참여자 | 1명 이상, 전원이 이 프로젝트 인원 |
| 송금 메모 | 0~30자 |
| 암호(비밀 프로젝트) | 4~32자 |
| 프로젝트당 지출 | 최대 500건 |
| 프로젝트당 송금 | 최대 500건 |

### 4.3 Rate limit (IP 해시 기준, 방명록과 같은 `IP_SALT`)

- 프로젝트 **생성**: 10초 내 재생성 → `too_fast`, 24h 내 30개 초과 → `daily_limit`.
- 그 외 편집: 제한 없음(코드를 알아야 하고, 상한이 4.2로 걸려 있다).

## 5. 프론트엔드 통합

- `lib/services/settlement_service.dart` — 위 계약의 HTTP 클라이언트.
  Base URL은 방명록과 같은 `String.fromEnvironment('GUESTBOOK_API', …)`.
  모든 오류를 `SettlementException`(한국어 메시지)으로 변환하고 앱을 죽이지 않는다.
- `lib/apps/settlement/store.dart` — 서버 모드에서는 각 변경이 API 호출 →
  응답 프로젝트로 상태 교체. **로컬 모드(localStorage)는 그대로 남겨** 백엔드가
  죽었거나 코드 없이 혼자 쓸 때의 대비책으로 쓴다.
- 라우팅: `#/settlement` = 내 브라우저의 로컬 프로젝트 목록,
  `#/settlement/<code>` = 서버 프로젝트(공유 링크).

## 6. 배포

방명록과 같은 Worker라 별도 배포 파이프라인이 없다. 스키마만 한 번 더 밀어주면 된다.

```bash
cd backend
npx wrangler d1 execute pure-blanche-guestbook --remote --file=./schema.sql
npx wrangler deploy
```

로컬: `npx wrangler d1 execute pure-blanche-guestbook --local --file=./schema.sql && npx wrangler dev`

## 7. 인수 기준

- [ ] `POST /api/settlement` → 201 + `code`/`ownerToken`. 같은 IP 연속 생성 시 429.
- [ ] `GET /api/settlement/:code` → 생성한 그대로의 프로젝트. 없는 코드는 404.
- [ ] 지출 추가/수정/삭제, 인원 추가/수정/삭제, 송금 추가/삭제가 각각 최신 `{project}` 반환.
- [ ] `PUT …/legs` 로 입금 처리/취소가 반영되고, 지출 수정 시 사라진 참여자의 기록이 정리됨.
- [ ] 지출에 얽힌 인원 삭제 → 409 `member_in_use`.
- [ ] 소유자 토큰 없이 `DELETE /api/settlement/:code` → 401.
- [ ] 방명록 API(`/api/guestbook`, `/api/stats`)가 그대로 동작.
