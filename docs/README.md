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
| [APPS.md](./APPS.md) | 10개 코드 프로젝트 서브앱 상세 레퍼런스 | 특정 서브앱을 건드릴 때 |
| [TODO.md](./TODO.md) | 작업 로드맵 (현재 진행 상태) | 다음에 뭘 할지 정할 때 |
| [PARALLEL_TASKS.md](./PARALLEL_TASKS.md) | 병렬 세션(c1/c2/c3) 분업 계획 + 프롬프트 | 멀티 세션으로 작업 분배할 때 |

## 핵심 사실 (TL;DR)

- **무엇**: Flutter Web으로 만든 Blanche의 개인 포트폴리오 + 유틸리티 허브. 도메인 `pure-blanche.com`.
- **배포**: `main` 브랜치 푸시 → GitHub Actions → GitHub Pages (커스텀 도메인은 Cloudflare DNS).
- **구성**: 메인(`/`) + 코드 프로젝트(`/code`, 10개 앱) + 영상 연대표(`/video`) + 방명록(`/guestbook`).
- **현재 작업**: 방명록 백엔드 신설 (Cloudflare Workers + D1). 자세한 건 [GUESTBOOK_BACKEND.md](./GUESTBOOK_BACKEND.md).
- **설계 원칙**: 백엔드가 죽어도 **방명록만** 막히고 나머지 사이트/앱은 정상 동작해야 한다 (graceful degradation).
