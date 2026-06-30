# Pure Blanche — TODO 로드맵

> 현재 상태 기준. 완료 항목은 [ARCHITECTURE.md](./ARCHITECTURE.md)에 사실로 반영됨.

## ✅ 완료

- 기본 구조: 디자인 시스템(`AppColors`/`AppTheme`), 14개 라우트, `MainPage` 히어로+네비카드, `PageScaffold`.
- 코드 프로젝트: **10개** 앱 통합 (Flutter 6 + HTML/사전빌드 4). 카드/배지/다운로드 링크.
- 영상 연대표: 7개 시대 풀페이지 스냅, 3-phase 인트로, YouTube 임베드, 서브영상 모달.
- 배포 인프라: GitHub Actions → GitHub Pages, 커스텀 도메인 `pure-blanche.com`(Cloudflare DNS) **연결됨**.

## 🚧 진행 중 — 방명록 백엔드 (Cloudflare Workers + D1)

명세: [GUESTBOOK_BACKEND.md](./GUESTBOOK_BACKEND.md). 병렬 분업: [PARALLEL_TASKS.md](./PARALLEL_TASKS.md).

- [ ] **c1** 백엔드: `backend/` Worker + D1 + schema + 배포 README.
- [ ] **c2** 프론트: `guestbook_service.dart` + `guestbook_page.dart` 재작성 + `http` 의존성.
- [ ] **사용자** 배포: `wrangler login → d1 create → schema → secret → deploy`.
- [ ] **head** 통합: `flutter analyze`, API base URL 확인, 커밋/푸시.

## 📌 정리 (레거시) — c3

- [ ] `CLAUDE.md`를 현재 코드에 동기화 (프로젝트 10개, 라우트, 버전, 방명록 백엔드, docs 포인터).
- [ ] `lib/sections/` 삭제 (import 없는지 grep 확인 후).
- [ ] `lib/widgets/drive_video_player.dart` 삭제 (YouTube로 대체됨).
- [ ] `docs/APPS.md` 신설 — 10개 서브앱 상세 레퍼런스.

## 🎨 디자인 완성도 (이후)

- [ ] 영상 연대표 6개 시대(2021 외) 실제 YouTube ID 채우기 (`VIDEO_SLOTS.md`).
- [ ] Hero 영상 자동재생(youtubeId 있을 때).
- [ ] 메인 ↔ 서브페이지 전환 애니메이션.
- [ ] 모바일 영상 페이지 개선.
- [ ] 파비콘 & OG 메타태그, SEO 기본(title/description/OG).
- [ ] 다크/라이트 토글, 로딩 스플래시.

## 🔮 향후 (선택)

- [ ] 방명록 관리(삭제/숨김) 기능, 필요 시 Turnstile 추가.
- [ ] 블로그/글쓰기, 이력서 다운로드, 다국어(KO/EN), PWA.
- [ ] 신규 유틸리티 앱 추가.
