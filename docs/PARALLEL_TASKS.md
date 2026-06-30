# 병렬 세션 분업 (c1 / c2 / c3)

head 세션이 작업을 3개로 쪼개 병렬 실행한다. 각 세션은 **겹치지 않는 파일만** 건드리므로
같은 작업 트리에서 동시에 돌려도 충돌하지 않는다.

## 파일 소유권 매트릭스

| 세션 | 역할 | 소유(편집/생성) | 절대 건드리지 않음 |
|------|------|----------------|---------------------|
| **c1** | 백엔드 | `backend/**` (신규) | `lib/**`, `pubspec.yaml`, `docs/**`, `CLAUDE.md` |
| **c2** | 프론트엔드 | `lib/pages/guestbook_page.dart`, `lib/services/guestbook_service.dart`(신규), `pubspec.yaml` | `backend/**`, `docs/**`, `CLAUDE.md`, 다른 `lib/` 파일 |
| **c3** | 문서/정리 | `CLAUDE.md`, `docs/APPS.md`(신규), `lib/sections/`(삭제), `lib/widgets/drive_video_player.dart`(삭제) | `backend/**`, `lib/pages/guestbook_page.dart`, `lib/services/**`, `pubspec.yaml`, `main.dart` |

**공통 규칙(모든 세션)**: git commit/push 금지, 배포(`wrangler deploy` 등) 금지 — 작업 트리에 변경만 남기고 끝에 요약 보고. 통합·커밋은 head가 한다.

## 통합 순서 (head, 세션 종료 후)

1. c3가 지운 파일이 빌드를 깨지 않는지 확인(grep imports).
2. `flutter pub get` → `flutter analyze` → `flutter build web`.
3. 사용자가 `backend/README.md` 절차로 Worker 배포 → `api.pure-blanche.com` 동작 확인.
4. 프론트를 실제 API로 한 번 돌려보고(또는 `--dart-define`으로 localhost) E2E 확인.
5. 단일 커밋으로 정리 후 푸시.

---

## 📋 c1 프롬프트 (백엔드) — 아래 전체를 복붙

```
너는 병렬로 도는 3개 세션 중 c1(백엔드 담당)이다. c2(프론트), c3(문서/정리)가 동시에 다른 파일을 작업 중이다.

[먼저 읽기] docs/GUESTBOOK_BACKEND.md 를 정독하라. 그게 API 계약서이고 절대 기준이다. docs/ARCHITECTURE.md도 참고.

[네 소유 — 이 경로만 생성/편집] backend/** (신규 디렉터리)
[절대 건드리지 마라] lib/**, pubspec.yaml, docs/**, CLAUDE.md, 그 외 기존 파일

[목표] Cloudflare Workers + D1 기반 방명록 API를 backend/ 에 완성한다. 코드/설정/배포 README까지. 배포 명령은 사용자 Cloudflare 로그인이 필요하므로 직접 실행하지 말고 README로 안내만 한다.

[만들 파일]
- backend/package.json        (wrangler devDependency + 스크립트: dev/deploy/db:init)
- backend/wrangler.toml        (name=pure-blanche-guestbook, main=src/index.js, compatibility_date="2024-11-06", D1 바인딩 DB, routes 커스텀도메인 api.pure-blanche.com)
- backend/schema.sql           (docs의 4.1 스키마 그대로)
- backend/src/index.js         (ES module fetch 핸들러 — 아래 계약 정확히 구현)
- backend/.gitignore           (node_modules/, .wrangler/, .dev.vars)
- backend/README.md            (배포 절차 docs 6장 요약 + 로컬 테스트법)

[API 계약 핵심 — docs와 동일, 어기지 말 것]
- GET /api/guestbook → 200 {messages:[{id,name,message,created_at}]} (id DESC, 최대 100)
- POST /api/guestbook {name,message} → 201 {message:{...}}
- 에러 {error,detail(한국어)}: 400 invalid_json/empty/name_too_long(>30)/message_too_long(>500), 422 spam(링크), 429 too_fast(30s)/daily_limit(24h 20개), 500 server_error
- GET / 또는 /health → 200 {ok:true,service:"pure-blanche-guestbook"}
- created_at: UTC "YYYY-MM-DD HH:MM:SS" (datetime('now'))
- CORS: 허용 Origin(https://pure-blanche.com, https://www.pure-blanche.com, http://localhost:*, http://127.0.0.1:*) echo, 메서드 GET/POST/OPTIONS, 헤더 Content-Type, OPTIONS→204
- 스팸: name/message에 https?:// 또는 \bwww\.\w 또는 \[url[=\]] 매치 시 422
- rate limit: ip_hash=SHA-256(IP_SALT+":"+CF-Connecting-IP). 원본 IP 저장 금지. 30초 내 재작성 429, 24h 20개 이상 429
- D1 바인딩 이름은 env.DB

[검증] `npx wrangler dev`로 로컬 기동 후(로컬 D1에 schema 주입 포함) GET/POST/에러/CORS를 직접 호출해 계약대로 동작하는지 확인하라. wrangler.toml의 database_id는 사용자가 `wrangler d1 create` 후 채우는 자리이므로 플레이스홀더로 두고 README에 명시.

[금지] git commit/push, wrangler deploy(원격 배포), wrangler login. 사용자 계정이 필요한 건 README 안내로만.

[끝나면] 만든 파일 목록 + 로컬 테스트 결과 + 사용자가 실행할 배포 명령 5줄을 요약 보고하라.
```

---

## 📋 c2 프롬프트 (프론트엔드) — 아래 전체를 복붙

```
너는 병렬로 도는 3개 세션 중 c2(프론트엔드 담당)이다. c1(백엔드), c3(문서/정리)가 동시에 다른 파일을 작업 중이다.

[먼저 읽기] docs/GUESTBOOK_BACKEND.md 를 정독하라(특히 3장 API 계약, 7장 프론트 요구사항). docs/ARCHITECTURE.md 7장(디자인 토큰)도 참고.

[네 소유 — 이 파일만 편집/생성] lib/pages/guestbook_page.dart, lib/services/guestbook_service.dart(신규), pubspec.yaml
[절대 건드리지 마라] backend/**, docs/**, CLAUDE.md, lib/main.dart, 그 외 lib 파일

[목표] 방명록을 로컬 state → 실제 백엔드 API 연동으로 교체한다. 백엔드가 죽어도 방명록 페이지만 에러 카드로 막히고 앱은 절대 크래시하지 않아야 한다(graceful degradation).

[작업 1] pubspec.yaml 의 dependencies에 http 추가 (예: http: ^1.2.2). `flutter pub get` 실행. 다른 의존성/줄은 건드리지 마라.

[작업 2] lib/services/guestbook_service.dart 생성:
- Base URL: const String.fromEnvironment('GUESTBOOK_API', defaultValue: 'https://api.pure-blanche.com')
- 모델 GuestEntry { int id; String name; String message; DateTime createdAt; } + fromJson + 로컬 'YYYY.MM.DD' getter. created_at은 UTC "YYYY-MM-DD HH:MM:SS"이므로 끝에 'Z' 붙여 파싱 후 toLocal().
- fetchEntries() → List<GuestEntry> (GET /api/guestbook, 10초 타임아웃, utf8 디코드)
- submit({name,message}) → GuestEntry (POST, 201이면 message 파싱, 그 외엔 본문 detail/error를 메시지로 한 예외 throw)
- 네트워크/타임아웃/파싱 오류는 모두 잡아서 사용자용 한국어 메시지를 담은 예외로 변환. 앱을 죽이지 마라.

[작업 3] lib/pages/guestbook_page.dart 재작성:
- "공사중" 오버레이 제거.
- 진입 시 fetchEntries() 호출. 3-상태: 로딩(스피너, signalGreen) / 목록 / 에러 카드(메시지 + '다시 시도' 버튼).
- 작성 폼: 이름(maxLength 30, 1줄) + 메시지(maxLength 500, 4줄) + Submit. 전송 중 버튼 비활성+로딩 표시. 성공 시 새 항목을 리스트 맨 앞에 추가(또는 재조회), 입력창 비움. 실패 시 폼 아래 인라인 에러 + 입력 내용 유지.
- 기존 스타일 유지: AppColors 토큰만 사용, PageScaffold(title:'Guestbook') 래퍼 유지, 기존 _StyledTextField/_SubmitButton 톤 그대로(필요시 maxLength/loading 지원하도록 확장). 하드코딩 색상 금지.
- 빈 목록일 때 '아직 작성된 방명록이 없습니다.' 안내.

[검증] flutter analyze 통과. 백엔드가 아직 없으니 GUESTBOOK_API를 잘못된 URL로 줘서(또는 기본값으로) 에러 카드가 뜨고 앱이 안 죽는지, 다른 페이지로 이동이 정상인지 확인하라. 가능하면 flutter build web 까지.

[참고] 로컬에서 c1 백엔드와 붙여 테스트하려면: flutter run -d chrome --dart-define=GUESTBOOK_API=http://localhost:8787

[금지] git commit/push. main.dart 수정(라우트 이미 존재). pubspec의 http 외 변경.

[끝나면] 바뀐 파일 + analyze 결과 + graceful degradation 확인 결과를 요약 보고하라.
```

---

## 📋 c3 프롬프트 (문서 동기화 + 레거시 정리) — 아래 전체를 복붙

```
너는 병렬로 도는 3개 세션 중 c3(문서/정리 담당)이다. c1(백엔드), c2(프론트)가 동시에 backend/와 lib/pages·services·pubspec을 작업 중이다. 그 파일들은 절대 건드리지 마라.

[먼저 읽기] docs/README.md, docs/ARCHITECTURE.md, docs/GUESTBOOK_BACKEND.md, docs/TODO.md 를 정독하라. 이게 새 정답 문서다.

[네 소유 — 이 파일만] CLAUDE.md(편집), docs/APPS.md(신규 생성), lib/sections/(삭제), lib/widgets/drive_video_player.dart(삭제)
[절대 건드리지 마라] backend/**, lib/pages/guestbook_page.dart, lib/services/**, pubspec.yaml, lib/main.dart, docs/의 기존 5개 문서(README/ARCHITECTURE/GUESTBOOK_BACKEND/TODO/PARALLEL_TASKS)

[작업 1] CLAUDE.md 동기화 — 현재 코드/ docs와 어긋난 부분을 고친다:
- "코드 프로젝트 4개" → 실제 10개(라우트/카드 기준, docs/ARCHITECTURE.md 3장 라우트표 반영).
- 라우트 표를 14개 전체로 갱신(jara-holdem/roulette/whos-the-nut/icm-split/safe-link/cannon + jamakase/birthday/word-guesser/word-finder).
- 프로젝트 구조 트리에 backend/ (방명록 API), lib/services/ 추가 언급.
- "방명록: 로컬 state" → "방명록: Cloudflare Workers + D1 백엔드 연동(docs/GUESTBOOK_BACKEND.md)"로.
- 맨 위 또는 적절한 위치에 "상세 명세는 docs/ 참조 (단일 진실 공급원)" 포인터 추가.
- Flutter 버전 등 확실치 않은 수치는 pubspec(sdk: ^3.10.7) 기준으로 보수적으로. 과장 금지. 코드를 직접 확인하고 쓸 것.
- CLAUDE.md의 톤/형식(한국어, 표)은 유지.

[작업 2] docs/APPS.md 신규 작성 — 10개 코드 프로젝트 서브앱 상세 레퍼런스:
- 각 앱: 라우트, 위치(lib/apps/ 또는 web/apps/), 한 줄 목적, 핵심 기능, 사용 기술/패키지, 주요 파일 구조, (있으면) 외부 다운로드/정책 링크.
- 출처는 lib/pages/code_projects_page.dart 카드 데이터 + lib/main.dart 라우트 + 각 앱 디렉터리를 직접 읽어 확인(추측 금지).
- 표 + 앱별 소제목 구조로. docs/ARCHITECTURE.md 6장과 중복은 링크로 처리하고 여기선 더 깊게.

[작업 3] 레거시 삭제 — 단, 안전 확인 먼저:
- `grep -rn "sections/"` 및 각 section 파일명, "drive_video_player" 를 lib/ 전체에서 검색해 import가 없는지 확인. (main.dart은 sections를 import하지 않음 — 재확인.)
- import가 전혀 없으면 lib/sections/ 디렉터리와 lib/widgets/drive_video_player.dart 를 삭제.
- 만약 어딘가 import가 남아있으면 삭제하지 말고 그 사실을 보고만 하라(임의로 다른 파일 수정 금지).

[금지] git commit/push. c1/c2 소유 파일 수정. docs 기존 문서 수정(APPS.md만 신규).

[끝나면] CLAUDE.md 변경 요약 + APPS.md 생성 + 삭제한 파일(또는 삭제 못 한 이유)을 보고하라.
```
