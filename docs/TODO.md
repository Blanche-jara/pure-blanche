# Pure Blanche — TODO 로드맵

> 현재 상태 기준. 완료 항목은 [ARCHITECTURE.md](./ARCHITECTURE.md)에 사실로 반영됨.
> 최종 갱신: 2026-08-13 (SMTM 배포)

## ✅ 완료

- 기본 구조: 디자인 시스템(`AppColors`/`AppTheme`), `MainPage` 히어로+네비카드, `PageScaffold`.
- 코드 프로젝트: **11개** 앱 통합 (Flutter 7 + HTML/사전빌드 4). 카드/배지/다운로드 링크.
- 영상 연대표: 7개 시대 풀페이지 스냅, 3-phase 인트로, YouTube 임베드, 서브영상 모달.
- 배포 인프라: GitHub Actions → GitHub Pages, 커스텀 도메인 `pure-blanche.com`(Cloudflare DNS).
- **방명록 백엔드**: Cloudflare Workers + D1 (`api.pure-blanche.com`). 관리자 모드(`#/admin`),
  IP·지역 수집(관리자 전용), 접속 통계 + Word Guesser 오늘의 정답.
- **레거시 정리**: `lib/sections/`·`drive_video_player.dart` 삭제됨, `CLAUDE.md` 동기화, `docs/APPS.md` 신설.
- **SMTM(정산표)** — `/settlement`. 균등분할 → 쌍별 상계 → 건별 입금 처리.
  로컬(localStorage) / 공유(D1 + 코드 링크) 2모드. 프로덕션 배포·검증 완료.

## 🔜 SMTM 다음 후보

우선순위 미정. 쓰면서 필요해지면 집는다.

- [ ] 인원 추가/이름변경/삭제 UI — 백엔드·컨트롤러는 이미 있는데 화면이 없다
      (`RemoteSettlementController.addMember/renameMember/removeMember`).
- [ ] 프로젝트 이름 변경 UI — 같은 상황(`controller.rename`).
- [ ] 공유 정산표 자동 새로고침(폴링/포커스 시). 지금은 수동 `새로고침` 버튼뿐.
- [ ] 개별 금액 직접 입력(각자 먹은 만큼). 현재는 균등분할 + 참여자 선택만.
- [ ] 정산 완료 후 요약 공유(이미지/텍스트 내보내기).
- [ ] 지출 항목 카테고리/정렬·검색.

## 🎨 디자인 완성도

- [ ] 영상 연대표 6개 시대(2021 외) 실제 YouTube ID 채우기 (`VIDEO_SLOTS.md`).
- [ ] Hero 영상 자동재생(youtubeId 있을 때).
- [ ] 메인 ↔ 서브페이지 전환 애니메이션.
- [ ] 모바일 영상 페이지 개선.
- [ ] 파비콘 & OG 메타태그, SEO 기본(title/description/OG).
- [ ] 다크/라이트 토글, 로딩 스플래시.

## 🧹 알려진 부채

- [ ] `test/widget_test.dart` 가 깨져 있다 — `main_page.dart`의 `dart:js_interop` 이
      VM 테스트에서 못 쓰여 컴파일 실패. 웹 전용 코드라 `flutter test` 대상에서 빼거나
      웹 테스트로 옮겨야 한다. (SMTM 테스트들은 정상 동작)
- [ ] `apps_src/word-guesser/test/` 도 `flutter analyze` 에서 에러를 낸다(별도 패키지 소스).

## 🔮 향후 (선택)

- [ ] 블로그/글쓰기, 이력서 다운로드, 다국어(KO/EN), PWA.
- [ ] 신규 유틸리티 앱 추가.
