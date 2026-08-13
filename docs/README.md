# Pure Blanche — 문서 인덱스

이 디렉터리는 **Pure Blanche** 사이트의 단일 진실 공급원(Single Source of Truth)입니다.
새로운 세션(사람이든 AI 에이전트든)은 이 인덱스부터 읽고 필요한 문서로 진입하세요.

> 루트의 `CLAUDE.md`는 "하네스(빠른 참조)"이고, 이 `docs/`는 "상세 명세"입니다.
> 둘이 충돌하면 **이 `docs/`가 최신/정답**입니다. (CLAUDE.md 동기화는 별도 작업으로 관리)

## 문서 목록

| 문서 | 용도 | 언제 읽나 |
|------|------|-----------|
| [ARCHITECTURE.md](./ARCHITECTURE.md) | 사이트 전체 구조 — 라우팅, 페이지, 서브앱, 디자인 시스템, 빌드/배포 | 프로젝트를 처음 이해할 때, 어떤 작업이든 시작 전 |
| [GUESTBOOK_BACKEND.md](./GUESTBOOK_BACKEND.md) | 방명록 백엔드 설계 + **API 계약(contract)** — Cloudflare Workers + D1 | 방명록 백엔드/프론트 작업 시 (c1·c2 필독) |
| [SETTLEMENT_BACKEND.md](./SETTLEMENT_BACKEND.md) | 정산표 백엔드 설계 + **API 계약** — 같은 Worker·같은 D1, 공유 코드 기반 | 정산표 작업 시 |
| [APPS.md](./APPS.md) | 11개 코드 프로젝트 서브앱 상세 레퍼런스 | 특정 서브앱을 건드릴 때 |
| [TODO.md](./TODO.md) | 작업 로드맵 (현재 진행 상태) | 다음에 뭘 할지 정할 때 |
| [PARALLEL_TASKS.md](./PARALLEL_TASKS.md) | 병렬 세션(c1/c2/c3) 분업 계획 + 프롬프트 | 멀티 세션으로 작업 분배할 때 |

## 다른 컴퓨터에서 이어받기

```bash
git clone https://github.com/Blanche-jara/pure-blanche.git && cd pure-blanche
flutter pub get
flutter run -d chrome                    # 프론트만 — 프로덕션 API(api.pure-blanche.com)를 그대로 쓴다
```

백엔드(방명록·SMTM)를 **로컬 D1**로 함께 돌리려면 터미널 두 개:

```bash
# 터미널 1 — Worker
cd backend && npm install
npx wrangler d1 execute pure-blanche-guestbook --local --file=./schema.sql   # 최초 1회
npx wrangler dev                                                             # → localhost:8787

# 터미널 2 — 앱을 로컬 Worker에 물린다
flutter run -d chrome --dart-define=GUESTBOOK_API=http://localhost:8787
```

검증 수단:

| 명령 | 확인 대상 |
|------|-----------|
| `flutter analyze lib` | 정적 분석 (`lib/` 만 — `apps_src/` 는 별도 패키지라 에러가 난다) |
| `flutter test test/settlement_engine_test.dart` | SMTM 정산 계산 규칙 14개 |
| `bash backend/smoke_settlement.sh` | SMTM API 35개 (로컬 Worker 필요) |
| `API=https://api.pure-blanche.com bash backend/smoke_settlement.sh` | 배포된 API 검증 |
| `flutter test test/settlement_service_integration_test.dart --dart-define=GUESTBOOK_API=http://localhost:8787` | 서비스↔Worker 왕복 |

> `flutter test` 를 통째로 돌리면 `test/widget_test.dart` 가 실패한다 — 기존 부채다([TODO.md](./TODO.md) 참조).

**배포**: `main` 에 푸시하면 GitHub Actions가 프론트를 GitHub Pages로 민다.
백엔드는 별도이며 `backend/README.md` 2장을 따른다. **프론트보다 백엔드를 먼저** 올려야
새 API를 쓰는 화면이 라이브에서 깨지지 않는다.

## 핵심 사실 (TL;DR)

- **무엇**: Flutter Web으로 만든 Blanche의 개인 포트폴리오 + 유틸리티 허브. 도메인 `pure-blanche.com`.
- **배포**: `main` 브랜치 푸시 → GitHub Actions → GitHub Pages (커스텀 도메인은 Cloudflare DNS).
- **구성**: 메인(`/`) + 코드 프로젝트(`/code`, 11개 앱) + 영상 연대표(`/video`) + 방명록(`/guestbook`).
- **현재 작업**: SMTM(`/settlement`) — 모임 정산표. `/code` 카드 노출됨. 자세한 건 [SETTLEMENT_BACKEND.md](./SETTLEMENT_BACKEND.md).
- **설계 원칙**: 백엔드가 죽어도 **그 기능만**(방명록/공유 정산표) 막히고 나머지 사이트/앱은 정상 동작해야 한다 (graceful degradation).
