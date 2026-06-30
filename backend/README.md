# Pure Blanche 방명록 백엔드

Cloudflare Workers + D1 기반 서버리스 방명록 API.
API 계약의 정답은 [`docs/GUESTBOOK_BACKEND.md`](../docs/GUESTBOOK_BACKEND.md). 이 README는 배포/테스트 절차만 다룬다.

- 프로덕션: `https://api.pure-blanche.com`
- 로컬 개발: `http://localhost:8787`

## 구성

| 파일 | 용도 |
|------|------|
| `package.json` | wrangler devDependency + npm 스크립트 |
| `wrangler.toml` | Worker 이름, D1 바인딩(`DB`), 커스텀 도메인 라우트 |
| `schema.sql` | D1 테이블/인덱스 + 환영 메시지 시드 |
| `src/index.js` | Worker fetch 핸들러 (ES module) |

## 엔드포인트 요약

| 메서드 | 경로 | 응답 |
|--------|------|------|
| `GET` | `/api/guestbook` | `200 {messages:[{id,name,message,created_at}]}` (id DESC, ≤100) |
| `POST` | `/api/guestbook` | `201 {message:{...}}` / 에러 `{error,detail}` |
| `GET` | `/` 또는 `/health` | `200 {ok:true,service:"pure-blanche-guestbook"}` |
| `OPTIONS` | (전체) | `204` + CORS 헤더 |

검증/스팸/rate-limit 규칙과 에러 코드 표는 계약 문서 3~4장 참조.

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
```

프론트엔드는 `--dart-define=GUESTBOOK_API=...`로 베이스 URL을 주입한다(기본값은 프로덕션).
로컬 통합 테스트: `flutter run -d chrome --dart-define=GUESTBOOK_API=http://localhost:8787`.
