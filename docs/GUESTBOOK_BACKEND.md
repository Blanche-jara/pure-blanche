# 방명록 백엔드 — 설계 + API 계약 (v1)

> **이 문서가 c1(백엔드)과 c2(프론트엔드)의 공유 계약서다.**
> 양쪽은 서로를 보지 않고 이 명세에만 맞춰 독립적으로 구현한다.
> 계약을 바꿔야 하면 **먼저 이 문서를 고치고** 양쪽에 반영한다. (이 문서 = 정답)

## 1. 목표와 제약

- **무료 + 진짜 24/7**: 서버리스(Cloudflare Workers + D1). 꺼질 프로세스가 없다. 노트북 의존 0.
- **Graceful degradation**: 백엔드가 죽어도 **방명록 페이지만** "일시 사용 불가"를 보여주고, 나머지 사이트/서브앱은 100% 정상. (방명록은 이미 별도 `/guestbook` 라우트 + 다른 앱은 이 API를 호출하지 않으므로 구조적으로 보장됨. 프론트는 에러를 삼켜서 사이트를 죽이지 않는 것만 책임진다.)
- **스팸 방어 수준**: "기본" — IP 기반 rate limit + 길이 제한 + 링크 차단. CAPTCHA 없음(사용자 마찰 0).

## 2. 결정된 아키텍처

```
브라우저 (Flutter Web, https://pure-blanche.com, GitHub Pages)
   │  fetch JSON
   ▼
https://api.pure-blanche.com         ← Cloudflare Worker (서버리스, 무료)
   │
   ▼
Cloudflare D1 (SQLite, 무료)         ← 방명록 메시지 영구 저장
```

- 도메인 `pure-blanche.com`은 이미 Cloudflare DNS에 있음 → `api.` 서브도메인을 Worker 커스텀 도메인으로 자동 연결 가능.
- 무료 한도(Workers 10만 req/일, D1 무료 티어)는 방명록 용도로 차고 넘침.

## 3. API 계약 (정확히 이대로)

**Base URL**
- 프로덕션: `https://api.pure-blanche.com`
- 로컬 개발: `http://localhost:8787` (`wrangler dev` 기본 포트)

모든 응답은 `Content-Type: application/json; charset=utf-8`.

### 3.1 `GET /api/guestbook`
최신 메시지 목록(최신순, 최대 100개).

- **200 OK**
  ```json
  {
    "messages": [
      { "id": 12, "name": "방문자", "message": "안녕하세요", "created_at": "2026-06-30 04:11:22" },
      { "id": 11, "name": "Blanche", "message": "방명록에 오신 걸 환영합니다!", "created_at": "2026-04-10 00:00:00" }
    ]
  }
  ```
- `created_at`: **UTC**, 형식 `"YYYY-MM-DD HH:MM:SS"` (SQLite `datetime('now')` 그대로). 프론트가 로컬 날짜로 변환.
- 정렬: `id DESC` (최신이 배열 앞).

### 3.2 `POST /api/guestbook`
새 메시지 작성.

- **요청**: `Content-Type: application/json`
  ```json
  { "name": "방문자", "message": "잘 보고 갑니다" }
  ```
- **201 Created**
  ```json
  { "message": { "id": 13, "name": "방문자", "message": "잘 보고 갑니다", "created_at": "2026-06-30 04:12:00" } }
  ```
- **에러** (모두 동일 형태):
  ```json
  { "error": "<코드>", "detail": "<사용자에게 보여줄 한국어 문구>" }
  ```

| status | error 코드 | 조건 | detail(예시) |
|--------|-----------|------|--------------|
| 400 | `invalid_json` | 본문이 JSON 아님 | 잘못된 요청입니다. |
| 400 | `empty` | name 또는 message 공백 | 이름과 메시지를 모두 입력해주세요. |
| 400 | `name_too_long` | name > 30자 | 이름은 30자 이하로 입력해주세요. |
| 400 | `message_too_long` | message > 500자 | 메시지는 500자 이하로 입력해주세요. |
| 422 | `spam` | 링크 포함 | 링크는 작성할 수 없습니다. |
| 429 | `too_fast` | 같은 IP가 30초 내 재작성 | 잠시 후 다시 시도해주세요. |
| 429 | `daily_limit` | 같은 IP가 24h 내 20개 초과 | 하루 작성 한도를 초과했습니다. |
| 500 | `server_error` | 내부 오류 | 서버 오류가 발생했습니다. |

### 3.3 `GET /` 또는 `/health`
헬스 체크 → **200** `{ "ok": true, "service": "pure-blanche-guestbook" }`

### 3.4 CORS (모든 응답에 포함)
- `Access-Control-Allow-Origin`: 요청 Origin이 허용 목록이면 그 값 echo, 아니면 `https://pure-blanche.com`.
  - 허용: `https://pure-blanche.com`, `https://www.pure-blanche.com`, `http://localhost:<포트>`, `http://127.0.0.1:<포트>`
- `Access-Control-Allow-Methods: GET, POST, PATCH, DELETE, OPTIONS`
- `Access-Control-Allow-Headers: Content-Type, Authorization`
- `Vary: Origin`
- **Preflight** `OPTIONS` → **204 No Content** + 위 헤더.

### 3.5 관리자 관리 (v1.1)
일반 방문자는 작성만 가능. **모든 글의 수정/삭제는 관리자 전용**이며 `Authorization: Bearer <ADMIN_TOKEN>`로 인증한다(`ADMIN_TOKEN`은 Worker secret). 미설정 시 관리자 기능은 비활성(모든 관리자 요청 401).

- `GET`/`POST` **`/api/admin/verify`** — 비밀번호 확인용. 일치 시 **200** `{ "ok": true }`, 아니면 **401** `{ "error":"unauthorized", "detail":"비밀번호가 올바르지 않습니다." }`.
- `DELETE` **`/api/guestbook/:id`** — 관리자 인증 필요.
  - 성공 **200** `{ "ok": true, "deleted": <id> }` / 없음 **404** `not_found` / 미인증 **401** `unauthorized`.
- `PATCH` **`/api/guestbook/:id`** — 관리자 인증 필요. 본문 `{ "name"?: string, "message"?: string }`(둘 중 하나 이상).
  - 성공 **200** `{ "message": { id,name,message,created_at } }`. 길이 검증은 작성과 동일(이름30/메시지500). 관리자 수정은 **스팸/링크 필터 미적용**(신뢰 주체).
  - 미인증 **401**, 없음 **404**, 본문 비정상 **400** `invalid_json`/`empty`.

토큰 비교는 길이 일치 확인 후 상수시간 비교(`safeEqual`). 진입 UX: 프론트가 **`/#/admin`** 전용 라우트(`GuestbookPage(adminEntry: true)`)에서 비밀번호를 받아 `verify` 통과 시 `sessionStorage`에 토큰 보관, 세션 동안 관리 컨트롤 노출. (해시 라우팅 + `MaterialApp.routes` 정확일치 방식이라 `?admin` 쿼리는 라우트 매칭에 실패 → 전용 라우트를 사용한다.)

### 3.6 접속 통계 + Word Guesser 정답 (v1.2)
코드 프로젝트 페이지 접속량과 Word Guesser "오늘의 정답"을 관리자 탭에서 본다.

- `POST` **`/api/hit`** — 공개. `{ "page": "<슬러그>" }`. 슬러그 화이트리스트(10개): jara-holdem/roulette/whos-the-nut/icm-split/safe-link/cannon/jamakase/birthday/word-guesser/word-finder. 화이트리스트 외 → 400 `bad_page`. `page_views(page, ip_hash, day)` 1행 기록(`day`=KST 날짜). 메인 앱의 `AppWrapper`/`HtmlAppPage` 진입 시 호출.
- `POST` **`/api/wg/answer`** — 공개(Word Guesser 앱이 호출). `{ "variant": "kakao5|kakao7|kordle6|kordle12", "answer": "<단어>" }`. Word Guesser가 후보 1개로 수렴하거나 정답을 맞히면 그 단어를 보고. `wg_answers(variant, answer, ip_hash, day)` 기록. 검증 실패 400.
- `GET` **`/api/stats`** — 🔒 관리자. 응답:
  ```json
  {
    "pages":  [{ "page":"word-guesser", "total":123, "today":7, "unique_today":5 }, ...],
    "wgToday":[{ "variant":"kordle6", "answer":"사람", "n":4, "users":3 }, ...]
  }
  ```
  `total`=누적, `today`=오늘(KST) 접속, `unique_today`=오늘 순방문(distinct ip_hash). `wgToday`=오늘 보고된 정답을 (variant, answer)별 빈도순. "몇 명 오늘 사용"=해당 페이지 `unique_today`, "오늘의 정답"=`wgToday`의 최다 보고 단어.

`day`는 모두 KST(UTC+9) 기준(`date('now','+9 hours')`)이라 한국 자정에 "오늘"이 바뀐다.

## 4. 데이터 / 검증 / 스팸 규칙

### 4.1 D1 스키마 (`backend/schema.sql`)
```sql
CREATE TABLE IF NOT EXISTS messages (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT NOT NULL,
  message    TEXT NOT NULL,
  ip_hash    TEXT,
  ip         TEXT,   -- 원본 IP (관리자 전용, v1.3~). 신규 글부터 기록.
  country    TEXT,   -- Cloudflare 지오 (국가 코드)
  region     TEXT,   -- 지역/시도
  city       TEXT,   -- 도시
  latitude   TEXT,   -- 위도(도시 근사, v1.4~) — 지도 링크용
  longitude  TEXT,   -- 경도(도시 근사)
  postal     TEXT,   -- 우편번호
  isp        TEXT,   -- ISP/기관 (cf.asOrganization)
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
-- 기존 DB 마이그레이션(각 1회): migrate_ip_geo.sql(ip/country/region/city) → migrate_geo_detail.sql(latitude/longitude/postal/isp).
CREATE INDEX IF NOT EXISTS idx_messages_id     ON messages(id DESC);
CREATE INDEX IF NOT EXISTS idx_messages_iphash ON messages(ip_hash, created_at);

-- 최초 1회: 환영 메시지(이미 있으면 넣지 않음)
INSERT INTO messages (name, message, created_at)
SELECT 'Blanche', '방명록에 오신 걸 환영합니다!', datetime('now')
WHERE NOT EXISTS (SELECT 1 FROM messages);
```

### 4.2 검증
- `name`: trim 후 1~30자.
- `message`: trim 후 1~500자.
- 저장값은 trim된 원문(이스케이프하지 않음 — 출력은 프론트 `Text` 위젯이라 XSS 무관).

### 4.3 스팸 (기본)
- 링크 차단: name/message가 정규식 `https?://`, `\bwww\.\w`, `\[url[=\]]` 중 하나라도 매치 → `422 spam`.
- **Rate limit (IP 해시 기준)**:
  - 같은 IP 마지막 작성 후 **30초** 미만 → `429 too_fast`.
  - 같은 IP 최근 **24시간** 내 **20개 이상** → `429 daily_limit`.
- **IP 해시**: rate-limit·순방문 계산용 `ip_hash = SHA-256(IP_SALT + ":" + ip)` (Web Crypto). `IP_SALT`는 Worker secret.

### 4.4 IP·지역 수집 + 이용 동의 (v1.3)
방명록 관리 편의를 위해 **작성 시 원본 IP(`CF-Connecting-IP`)와 Cloudflare 지역(`request.cf`의 country/region/city)을 함께 저장**한다.
- **관리자 전용 노출**: `GET /api/guestbook`는 공개 호출 시 `id/name/message/created_at`만, **관리자 Bearer 동반 시에만** `ip/country/region/city`를 추가로 반환한다. 공개 목록엔 절대 포함되지 않는다.
- **이용 동의(프론트)**: 비관리자는 `/guestbook` 최초 진입 시 약관("도배·비방 시 관리자가 IP·지역을 수집·확인하고 공개(박제)할 수 있음")에 **동의(체크)해야** 방명록 이용 가능. 동의는 `localStorage(pb_guestbook_consent)`에 저장(브라우저당 1회).
- 소급 안 됨: 이 기능 이전 글은 ip/지역이 비어 있다(관리자 화면에 "미기록" 표시).
- 지역은 IP 기반이라 대략적이며 `request.cf`는 프로덕션에서만 채워진다(로컬 `wrangler dev`는 비어 있을 수 있음).
- **v1.4**: `request.cf`의 `latitude`/`longitude`/`postalCode`/`asOrganization(ISP)`도 저장. 관리자 카드에 ISP·우편번호 표시 + **🗺️ 지도** 링크(위경도 → 구글맵, 없으면 지역명 검색). 정밀도는 도시/ISP 수준(정확 주소 아님). IPv6 주소는 정상(한국 통신사 다수가 IPv6).

## 5. 백엔드 리포 레이아웃 (c1 담당)

```
backend/
├── package.json        # wrangler devDependency + 스크립트
├── wrangler.toml       # Worker 이름, D1 바인딩(DB), 커스텀 도메인 라우트
├── schema.sql          # 위 4.1
├── src/index.js        # Worker (ES module, fetch 핸들러)
├── .gitignore          # node_modules/, .wrangler/, .dev.vars
└── README.md           # 배포 절차(아래 6장 요약)
```

`wrangler.toml` 필수 요소:
```toml
name = "pure-blanche-guestbook"
main = "src/index.js"
compatibility_date = "2024-11-06"

routes = [
  { pattern = "api.pure-blanche.com", custom_domain = true }
]

[[d1_databases]]
binding = "DB"
database_name = "pure-blanche-guestbook"
database_id = "<wrangler d1 create 출력값으로 채움>"
```

## 6. 배포 절차 (사용자가 실행 — c1은 명령어와 README를 준비)

> 이 단계는 사용자의 Cloudflare 계정 로그인이 필요하므로 **에이전트가 직접 실행하지 않는다.**
> c1은 코드/설정/README를 완성하고, 아래 명령을 사용자에게 안내한다.

```bash
cd backend
npm install
npx wrangler login                                   # 브라우저 OAuth (1회)
npx wrangler d1 create pure-blanche-guestbook        # 출력된 database_id를 wrangler.toml에 붙여넣기
npx wrangler d1 execute pure-blanche-guestbook --remote --file=./schema.sql   # 원격 DB에 테이블 생성
npx wrangler secret put IP_SALT                       # 아무 랜덤 문자열 입력(예: openssl rand -hex 16)
npx wrangler deploy                                   # 배포 + api.pure-blanche.com 자동 연결
```

- 커스텀 도메인은 `routes`의 `custom_domain = true` 덕분에 배포 시 DNS 레코드+인증서가 자동 생성됨(존이 Cloudflare에 있으므로).
- 로컬 테스트: `npx wrangler dev` → `http://localhost:8787` + 로컬 D1(`--local`로 schema 먼저 주입).

## 7. 프론트엔드 통합 요구사항 (c2 담당)

- `http` 패키지 추가(`pubspec.yaml`).
- 신설 `lib/services/guestbook_service.dart`:
  - Base URL은 `String.fromEnvironment('GUESTBOOK_API', defaultValue: 'https://api.pure-blanche.com')`.
    - 로컬 개발 시: `flutter run -d chrome --dart-define=GUESTBOOK_API=http://localhost:8787`.
  - `fetchEntries()` → `List<GuestEntry>`, `submit(name, message)` → `GuestEntry`.
  - 모든 네트워크 오류/타임아웃(10s)을 잡아 사용자용 한국어 메시지를 던진다. **앱을 크래시시키지 않는다.**
  - `created_at`(UTC "YYYY-MM-DD HH:MM:SS")를 파싱해 로컬 `YYYY.MM.DD`로 표시.
- `lib/pages/guestbook_page.dart` 재작성:
  - "공사중" 오버레이 **제거**.
  - 진입 시 목록 로드 → 로딩 스피너 / 목록 / **에러 카드(재시도 버튼)** 3-상태.
  - 작성: 전송 중 버튼 비활성+로딩, 성공 시 새 항목을 리스트 맨 앞에 추가(또는 재조회), 실패 시 인라인 에러 + 입력 내용 유지.
  - 이름 30자 / 메시지 500자 입력 제한(백엔드와 동일).
  - 기존 디자인 토큰(`AppColors`)과 위젯 스타일 유지.

## 8. 인수 기준 (양쪽 공통 체크리스트)

**백엔드 (c1)**
- [ ] `wrangler dev`로 로컬 기동, `GET /api/guestbook` → `{messages:[...]}` (환영 메시지 1개 포함).
- [ ] `POST` 정상 → 201 + 생성 객체. 빈 값/초장문/링크/연속작성 → 각 4xx 코드 정확히.
- [ ] CORS 프리플라이트(OPTIONS) 204 + 헤더. 허용 Origin echo.
- [ ] 원본 IP 미저장(ip_hash만). README에 배포 명령 완비.

**프론트 (c2)**
- [ ] `flutter analyze` 통과. 빌드 성공.
- [ ] API 응답 → 목록 렌더. 작성 → 즉시 반영.
- [ ] **백엔드 down 시뮬레이션**(잘못된 URL): 방명록만 에러 카드, 다른 페이지/앱 정상. 콘솔 예외로 앱이 죽지 않음.
- [ ] 공사중 오버레이 사라짐. 글자수 제한 동작.
