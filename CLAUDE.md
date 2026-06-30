# Pure Blanche — Utility Hub Website

Blanche의 유틸리티 집합소 웹사이트. Flutter Web으로 구축.
포트폴리오가 아닌, 직접 만든 도구/프로젝트를 모아 실제로 사용할 수 있는 허브.

> **📚 상세 명세는 `docs/`를 단일 진실 공급원(SSOT)으로 삼는다.** 이 `CLAUDE.md`는
> 빠른 참조용 하네스이며, 충돌 시 `docs/`가 정답이다.
> - `docs/README.md` — 문서 인덱스 (여기부터 읽기)
> - `docs/ARCHITECTURE.md` — 라우팅·페이지·서브앱·디자인·배포 전체 구조
> - `docs/APPS.md` — 코드 프로젝트 10개 서브앱 상세 레퍼런스
> - `docs/GUESTBOOK_BACKEND.md` — 방명록 백엔드 설계 + API 계약
> - `docs/TODO.md` — 작업 로드맵

## Tech Stack

- **Framework**: Flutter Web 전용 (CI는 stable 채널 최신; 개발 머신 기준 3.38.7 stable)
- **Language**: Dart — `environment.sdk: ^3.10.7` (pubspec 기준)
- **State**: Provider (jara-holdem), Riverpod + Hive (icm-split), setState (나머지)
- **Storage**: SharedPreferences / 브라우저 localStorage (사용자별 독립). 방명록만 서버 백엔드 사용
- **Fonts**: Google Fonts (Inter), system-ui (headings), Consolas (code)
- **Design System**: `design/DESIGN.md` 기반 — VoltAgent-inspired dark theme
- **Deployment**: GitHub Pages + GitHub Actions (`.github/workflows/deploy.yml`)
- **Domain**: `pure-blanche.com` (Cloudflare DNS → GitHub Pages)
- **Backend**: 방명록 한정 — Cloudflare Workers + D1 (`api.pure-blanche.com`). 상세: `docs/GUESTBOOK_BACKEND.md`
- **Dependencies**: provider, audioplayers, shared_preferences, intl, web, url_launcher, pointer_interceptor, google_fonts, http, flutter_riverpod, hive/hive_flutter, fl_chart, uuid

## Design Tokens (Quick Ref)

| Role | Color | Hex |
|------|-------|-----|
| Page BG | Abyss Black | `#050507` |
| Card BG | Carbon Surface | `#101010` |
| Accent | Signal Green | `#00d992` |
| Button Text | Mint | `#2fd6a1` |
| Border | Warm Charcoal | `#3d3a39` |
| Primary Text | Snow White | `#f2f2f2` |
| Secondary Text | Parchment | `#b8b3b0` |
| Muted Text | Steel Slate | `#8b949e` |

## Project Structure

```
pure-blanche/
├── CLAUDE.md                  # 이 파일 (하네스/빠른 참조)
├── VIDEO_SLOTS.md             # 영상 연대표 데이터 관리 파일
├── design/                    # 디자인 시스템 원본 (DESIGN.md, preview HTML)
├── docs/                      # 상세 명세 (SSOT): README/ARCHITECTURE/APPS/GUESTBOOK_BACKEND/TODO/PARALLEL_TASKS
├── backend/                   # 방명록 API — Cloudflare Worker + D1 (docs/GUESTBOOK_BACKEND.md)
├── lib/
│   ├── main.dart              # 앱 엔트리, 전체 라우팅 정의 (14개 라우트)
│   ├── theme/
│   │   ├── app_colors.dart        # 디자인 토큰 색상 상수
│   │   └── app_theme.dart         # ThemeData + 타이포그래피
│   ├── pages/
│   │   ├── main_page.dart             # 메인 (히어로 + 3개 네비카드)
│   │   ├── code_projects_page.dart    # 코드 프로젝트 10개 카드 → 각 앱 실행
│   │   ├── video_projects_page.dart   # 영상 연대표 (풀페이지 스냅 + 타임라인)
│   │   └── guestbook_page.dart        # 방명록 (백엔드 연동)
│   ├── services/                  # 프론트 서비스 레이어 (guestbook_service.dart 등 — 방명록 API 호출)
│   ├── apps/                  # 서브앱 (Flutter 6개 + 래퍼). 앱별 상세는 docs/APPS.md
│   │   ├── app_wrapper.dart           # 서브앱 공통 래퍼 (뒤로가기 바)
│   │   ├── jara_holdem/               # Jara Holdem Timer
│   │   ├── whos_the_nut/              # Who's the Nut? (핸드 평가/너트/사이드팟)
│   │   ├── icm_split/                 # ICM Split (Riverpod + Hive + fl_chart)
│   │   ├── roulette/                  # 자마카세 인원뽑기 룰렛
│   │   ├── safe_link/                 # It's Safe Link (lz-string redirector)
│   │   ├── cannon/                    # THE CANNON (주사위 추첨)
│   │   └── web_embed/
│   │       └── html_app_page.dart         # HTML/사전빌드 프로젝트 iframe 임베드 위젯
│   └── widgets/
│       ├── nav_bar.dart               # 상단 네비게이션 (메인용)
│       ├── page_scaffold.dart         # 서브페이지 공통 레이아웃
│       ├── section_header.dart        # 섹션 헤더 + GlowingCard
│       └── youtube_player.dart        # YouTube iframe 임베드 (youtube-nocookie.com)
├── assets/
│   └── Blanche_Logo.png           # 메인 페이지 로고 (흰색, 투명 배경)
├── web/
│   ├── index.html                 # Flutter web 엔트리
│   ├── CNAME                      # GitHub Pages 커스텀 도메인 (pure-blanche.com)
│   ├── assets/
│   │   └── Blanche_Animation.mp4  # 인트로 영상 (~9MB)
│   └── apps/                       # HTML/사전빌드 프로젝트 (iframe 임베드 대상)
│       ├── jamakase/index.html + BG.mp3   # Jamakase Notify
│       ├── birthday/index.html            # 자라 생일 선물 리스트
│       ├── word-guesser/                  # 사전빌드 Flutter Web (한글 워들 솔버)
│       ├── word-finder/                   # 사전빌드 Flutter Web (꼬맨틀 헬퍼 + 임베딩 데이터)
│       ├── whos-the-nut/                  # 개인정보처리방침 · 패치노트 HTML
│       └── video-player.html              # Google Drive preview iframe 래퍼
├── .github/
│   └── workflows/
│       └── deploy.yml             # GitHub Actions: Flutter 빌드 → Pages 배포
└── pubspec.yaml
```

## Routes

전체 14개 named route (`lib/main.dart`). 코드 프로젝트는 10개(`/app/*`). 앱별 상세는 `docs/APPS.md`.

| Path | Page | 설명 |
|------|------|------|
| `/` | `MainPage` | 2-page 스냅 스크롤: 히어로 소개 (Page 0) + 3개 네비카드 & 푸터 (Page 1). 첫 접속 시 인트로 영상 재생 (sessionStorage 기반) |
| `/code` | `CodeProjectsPage` | 코드 프로젝트 10개 카드 → 클릭 시 각 앱 실행 |
| `/video` | `VideoProjectsPage` | 영상 연대표 (7개 시대, 풀페이지 스냅) |
| `/guestbook` | `GuestbookPage` | 방명록 — Cloudflare Workers + D1 백엔드 연동 (`docs/GUESTBOOK_BACKEND.md`) |
| `/app/jara-holdem` | `AppWrapper` + `JaraHoldemApp` | 포커 토너먼트 타이머 (Flutter) |
| `/app/roulette` | `AppWrapper` + `RouletteAppEntry` | 자마카세 인원뽑기 룰렛 (Flutter) |
| `/app/whos-the-nut` | `AppWrapper` + `WhosTheNutApp` | 너트 핸드 평가기 (Flutter) |
| `/app/icm-split` | `AppWrapper` + `IcmSplitApp` | ICM 분배 계산기 (Flutter, Riverpod) |
| `/app/safe-link` | `AppWrapper` + `SafeLinkApp` | URL 안전 리다이렉트 (Flutter) |
| `/app/cannon` | `AppWrapper` + `CannonApp` | 주사위 추첨기 THE CANNON (Flutter) |
| `/app/jamakase` | `HtmlAppPage` | Jamakase Notify (HTML iframe) |
| `/app/birthday` | `HtmlAppPage` | 자라 생일 선물 리스트 (HTML iframe) |
| `/app/word-guesser` | `HtmlAppPage` | 한글 워들 솔버 (사전빌드 Flutter Web iframe) |
| `/app/word-finder` | `HtmlAppPage` | 꼬맨틀(Semantle) 헬퍼 (사전빌드 Flutter Web iframe) |

## Key Data Files

| 파일 | 용도 |
|------|------|
| `VIDEO_SLOTS.md` | 영상 연대표 데이터. 연도별 메인/서브 영상 목록 + youtubeId. 영상 업데이트 요청 시 이 파일 참조하여 `video_projects_page.dart`의 `_eras` 배열에 반영. |
| `design/DESIGN.md` | 전체 디자인 시스템 (색상, 타이포, 컴포넌트, 레이아웃 원칙). 새 UI 만들 때 반드시 참조. |

## Commands

```bash
flutter run -d chrome        # 로컬 개발 서버
flutter build web             # 프로덕션 빌드 → build/web/
```

## Conventions

- 색상은 반드시 `AppColors` 상수 사용 (하드코딩 금지)
- 호버 인터랙션: 200~300ms AnimatedContainer, border → signalGreen 전환
- 반응형 기준: 768px (모바일/데스크톱), 600px (카드 그리드 컬럼 수)
- Flutter 서브앱은 `AppWrapper`로 감싸서 뒤로가기 바 통일
- HTML 프로젝트는 `HtmlAppPage`로 iframe 임베드
- 서브앱 간 Provider 전달: `Navigator.push` 시 `ChangeNotifierProvider.value`로 전달 (jara-holdem SetupScreen 참고)
- 영상 임베드: YouTube `youtube-nocookie.com/embed/{ID}` iframe 사용
- 영상 썸네일: `img.youtube.com/vi/{ID}/mqdefault.jpg`
- 사전빌드 Flutter Web 앱(word-guesser/word-finder)은 `web/apps/<name>/`에 산출물을 두고 `HtmlAppPage`로 임베드

## Main Page Architecture

- 2-page 스냅: `PageView` vertical (Page 0: 히어로, Page 1: 카드+푸터)
- 인트로 영상: `sessionStorage` 기반 첫 접속 판별. HTML `<video>` 요소로 자동재생 (muted)
- 인트로 흐름: 영상 재생 → 800ms 페이드아웃 → 메인 화면 1000ms 페이드인
- ESC 키로 영상 스킵 가능. 영상 중 마우스/키보드 입력 차단 (`IgnorePointer` + `Focus`)

## Video Page Architecture

- 풀페이지 스냅: `PageView` vertical + `NeverScrollableScrollPhysics` + `Listener`로 스크롤 가로채기
- 스크롤 쿨다운: 800ms 락 (한 번 스크롤 = 한 챕터 전환)
- 인트로 애니메이션: 2.8초 3-phase (연대표 중앙 등장 → 좌측 슬라이드 → 콘텐츠 페이드인)
- 서브 영상 스트립: 가로 스크롤 + ← → 화살표 페이지네이션
- 서브 영상 팝업: `showDialog` (barrierDismissible: true) — 바깥 클릭으로 닫기 가능
- 메인 영상 iframe 스크롤: `pointer_interceptor`로 iframe 이벤트 가로채기
- 데이터 관리: `VIDEO_SLOTS.md` → `_eras` 배열 수동 동기화
