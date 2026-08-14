# Pure Blanche 백엔드

Cloudflare Workers + D1 기반 서버리스 API. **방명록 + 접속통계 + SMTM(정산표)** 가 한 Worker·한 D1을 공유한다.
API 계약의 정답은 [`docs/GUESTBOOK_BACKEND.md`](../docs/GUESTBOOK_BACKEND.md)(방명록·통계)와
[`docs/SETTLEMENT_BACKEND.md`](../docs/SETTLEMENT_BACKEND.md)(SMTM). 이 README는 배포/테스트 절차만 다룬다.

- 프로덕션: `https://api.pure-blanche.com`
- 로컬 개발: `http://localhost:8787`

## 구성

| 파일 | 용도 |
|------|------|
| `package.json` | wrangler devDependency + npm 스크립트 |
| `wrangler.toml` | Worker 이름, D1 바인딩(`DB`), 커스텀 도메인 라우트 |
| `schema.sql` | D1 테이블/인덱스 + 환영 메시지 시드 |
| `src/index.js` | Worker fetch 핸들러 — 방명록·통계 + 라우터 (ES module) |
| `src/common.js` | CORS/JSON 응답/IP 해시/관리자 인증 (index·settlement 공용) |
| `src/settlement.js` | SMTM 라우트 `/api/settlement/**` |
| `smoke_settlement.sh` | SMTM API 인수 기준 48개 검증 스크립트 |
| `migrate_settlement_password.sql` | 비밀 프로젝트 컬럼 추가 (기존 DB 1회) |

## 엔드포인트 요약

| 메서드 | 경로 | 응답 |
|--------|------|------|
| `GET` | `/api/guestbook` | `200 {messages:[{id,name,message,created_at}]}` (id DESC, ≤100) |
| `POST` | `/api/guestbook` | `201 {message:{...}}` / 에러 `{error,detail}` |
| `PATCH` | `/api/guestbook/:id` | 🔒 관리자 — `200 {message:{...}}` (name/message 수정) |
| `DELETE` | `/api/guestbook/:id` | 🔒 관리자 — `200 {ok:true,deleted:id}` |
| `GET`/`POST` | `/api/admin/verify` | 🔒 관리자 비번 확인 — `200 {ok:true}` / `401` |
| `POST` | `/api/hit` | 접속 기록(공개) — `{page}`(11개 슬러그, `smtm` 포함) → `200 {ok:true}` |
| `POST` | `/api/wg/answer` | Word Guesser 정답 보고(공개) — `{variant,answer}` → `200 {ok:true}` |
| `GET` | `/api/stats` | 🔒 관리자 통계 — `{pages:[{page,total,today,unique_today}], wgToday:[{variant,answer,n,users}]}` |
| `GET` | `/` 또는 `/health` | `200 {ok:true,service:"pure-blanche-guestbook"}` |
| (여러) | `/api/settlement/**` | SMTM — 계약: [`docs/SETTLEMENT_BACKEND.md`](../docs/SETTLEMENT_BACKEND.md) 3.2 |
| `OPTIONS` | (전체) | `204` + CORS 헤더 |

🔒 = `Authorization: Bearer <ADMIN_TOKEN>` 헤더 필요. 검증/스팸/rate-limit 규칙과 에러 코드 표는 계약 문서 3~4장 참조.

---

## 1. 로컬 테스트 (`wrangler dev`)

Cloudflare 로그인 없이 로컬 D1로 전체 계약을 검증할 수 있다.

```bash
cd backend
npm install

# 로컬 D1에 스키마 주입 (최초 1회 / schema 변경 시)
npx wrangler d1 execute pure-blanche-guestbook --local --file=./schema.sql
# 또는: npm run db:init:local

# 개발 서버 기동 → http://localhost:8787
npx wrangler dev
# 또는: npm run dev
```

> `wrangler dev`는 로컬 모드에서 `wrangler.toml`의 `database_id` 플레이스홀더를 무시하고
> `.wrangler/`의 로컬 SQLite를 사용하므로, 원격 DB 생성 전에도 테스트가 가능하다.
> 로컬에서는 `IP_SALT` 미설정 시 코드가 `"dev-salt"` fallback을 쓴다(프로덕션은 secret 필수).

호출 예시:

```bash
# 헬스 체크
curl http://localhost:8787/health

# 목록
curl http://localhost:8787/api/guestbook

# 작성
curl -X POST http://localhost:8787/api/guestbook \
  -H "Content-Type: application/json" \
  -d '{"name":"방문자","message":"잘 보고 갑니다"}'

# CORS preflight
curl -i -X OPTIONS http://localhost:8787/api/guestbook \
  -H "Origin: https://pure-blanche.com"
```

---

## 2. 프로덕션 배포 (사용자 실행)

> Cloudflare 계정 로그인이 필요하므로 **사용자가 직접 실행**한다.
> 아래 5단계를 순서대로 진행하면 `api.pure-blanche.com`이 자동 연결된다.

```bash
cd backend
npm install

# 1) 브라우저 OAuth 로그인 (1회)
npx wrangler login

# 2) D1 데이터베이스 생성 → 출력된 database_id 를 wrangler.toml 에 붙여넣기
npx wrangler d1 create pure-blanche-guestbook

# 3) 원격 D1에 스키마 주입 (테이블/인덱스 + 환영 메시지)
npx wrangler d1 execute pure-blanche-guestbook --remote --file=./schema.sql

# 4) IP 해시용 secret 설정 (예: openssl rand -hex 16 의 출력값 입력)
npx wrangler secret put IP_SALT

# 4-b) 관리자 비밀번호 secret 설정 (전체 글 수정/삭제 권한 — 강한 랜덤 권장: openssl rand -hex 24)
npx wrangler secret put ADMIN_TOKEN

# 5) 배포 (+ api.pure-blanche.com 커스텀 도메인 자동 생성)
npx wrangler deploy
```

### 주의

- **2단계 후 반드시** `wrangler.toml`의 `database_id = "REPLACE_WITH_D1_DATABASE_ID"` 를
  실제 출력값으로 교체해야 배포가 성공한다.
- 커스텀 도메인은 `routes`의 `custom_domain = true` 덕분에 배포 시 DNS 레코드와
  TLS 인증서가 자동 생성된다(존이 Cloudflare에 있으므로).
- `IP_SALT`는 원본 IP를 저장하지 않기 위한 해시 솔트다. 저장되는 건 `ip_hash`뿐이며
  원본 IP는 어디에도 남지 않는다.

### 배포 후 확인

```bash
curl https://api.pure-blanche.com/health
curl https://api.pure-blanche.com/api/guestbook

# SMTM 라우트 + 테이블이 함께 살아있는지 (없는 코드 조회)
curl https://api.pure-blanche.com/api/settlement/zzzzzzzz
```

마지막 응답은 **`{"error":"not_found",...}`** 여야 한다.

> ⚠️ **`{"error":"server_error"}`(500)가 나오면 스키마가 원격 D1에 안 들어간 것이다.**
> 이 라우트는 응답 전에 `settle_projects` 를 조회하므로, 404가 돌아온다는 건
> 테이블이 존재한다는 증거이기도 하다. 500이면 3단계(`--remote --file=./schema.sql`)를
> 다시 실행하고 아래로 확인한다:
> ```bash
> npx wrangler d1 execute pure-blanche-guestbook --remote \
>   --command "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
> ```
> `settle_projects / settle_members / settle_expenses / settle_transfers / settle_legs`
> 5개가 보여야 한다. `schema.sql` 은 전부 `IF NOT EXISTS` 라 재실행해도
> 방명록 데이터에 영향이 없다.

전체 계약을 한 번에 검증하려면(만든 정산표는 끝에 삭제된다):

```bash
API=https://api.pure-blanche.com bash smoke_settlement.sh   # 48개 항목
```

### SMTM 비밀 프로젝트 마이그레이션 (기존 DB 1회)

암호 잠금(`pass_salt`/`pass_hash`)은 **기존 `settle_projects` 테이블에 자동으로 안 붙는다**
(`CREATE TABLE IF NOT EXISTS` 는 컬럼을 추가하지 않는다):

```bash
npx wrangler d1 execute pure-blanche-guestbook --remote --file=./migrate_settlement_password.sql
```

두 번째 실행은 "duplicate column name" 에러가 난다(정상, 무시).
안 돌리면 비밀 프로젝트 생성이 500으로 실패한다.

프론트엔드는 `--dart-define=GUESTBOOK_API=...`로 베이스 URL을 주입한다(기본값은 프로덕션).
로컬 통합 테스트: `flutter run -d chrome --dart-define=GUESTBOOK_API=http://localhost:8787`.

---

## 3. 관리자 관리 (전체 글 수정/삭제)

- `ADMIN_TOKEN` secret 을 아는 사람만 모든 글을 수정/삭제할 수 있다. 일반 방문자는 작성만 가능.
- **진입**: `https://pure-blanche.com/#/admin` 접속 → 비밀번호 입력 → 그 세션 동안 관리자 모드(각 글에 수정/삭제 버튼).
- 인증 토큰은 브라우저 `sessionStorage`에만 보관되어 탭을 닫으면 사라진다.
- **시크릿 교체**: `npx wrangler secret put ADMIN_TOKEN` 재실행 → 라이브 워커에 즉시 반영(코드 재배포 불필요).
- `ADMIN_TOKEN` 미설정 시 관리자 기능은 완전 비활성(모든 관리자 요청 `401`).
- 관리자 수정(`PATCH`)은 신뢰 주체로 간주하여 링크/스팸 필터를 적용하지 않는다.

### 방명록 IP·지역 수집 (v1.3)
- 작성 시 원본 IP + Cloudflare 지역(국가/지역/도시)을 저장하고, **관리자 목록 조회(Bearer)에서만** 노출한다. 공개 목록엔 안 나감.
- 비관리자는 `/guestbook` 최초 진입 시 이용 약관(도배 시 IP·지역 수집·공개 가능)에 동의해야 이용 가능.
- **기존 DB 마이그레이션(각 1회)** — messages 테이블에 컬럼 추가:
  ```bash
  npx wrangler d1 execute pure-blanche-guestbook --remote --file=./migrate_ip_geo.sql      # ip/country/region/city
  npx wrangler d1 execute pure-blanche-guestbook --remote --file=./migrate_geo_detail.sql  # latitude/longitude/postal/isp
  ```
  (신규 DB는 `schema.sql` 에 이미 포함. 재실행 시 "duplicate column" 에러 → 각 1회만.)
- v1.4: 관리자 카드에 ISP·우편번호 + 🗺️ 지도 링크(위경도 기반 구글맵). 정밀도는 도시/ISP 수준.
