# Pure Blanche — Utility Hub Website

Blanche의 유틸리티 집합소 웹사이트. Flutter Web으로 구축.
포트폴리오가 아닌, 직접 만든 도구/프로젝트를 모아 실제로 사용할 수 있는 허브.

## Tech Stack

- **Framework**: Flutter 3.41.6 (Web only)
- **Language**: Dart 3.11.4
- **State**: Provider (jara-holdem), setState (roulette, guestbook)
- **Storage**: SharedPreferences (브라우저 localStorage — 사용자별 독립)
- **Fonts**: Google Fonts (Inter), system-ui (headings), Consolas (code)
- **Design System**: `design/DESIGN.md` 기반 — VoltAgent-inspired dark theme
- **Deployment**: GitHub Pages + GitHub Actions (`.github/workflows/deploy.yml`)
- **Domain**: `pure-blanche.com` (Cloudflare DNS → GitHub Pages)
- **Dependencies**: provider, audioplayers, shared_preferences, intl, web, google_fonts, pointer_interceptor, url_launcher

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
├── CLAUDE.md                  # 이 파일 (하네스)
├── VIDEO_SLOTS.md             # 영상 연대표 데이터 관리 파일
├── design/                    # 디자인 시스템 원본 (DESIGN.md, preview HTML)
├── docs/
│   └── TODO.md                # 작업 로드맵
├── lib/
│   ├── main.dart              # 앱 엔트리, 전체 라우팅 정의
│   ├── theme/
│   │   ├── app_colors.dart        # 디자인 토큰 색상 상수
│   │   └── app_theme.dart         # ThemeData + 타이포그래피
│   ├── pages/
│   │   ├── main_page.dart             # 메인 (히어로 + 3개 네비카드)
│   │   ├── code_projects_page.dart    # 코딩 프로젝트 목록 → 각 앱 실행
│   │   ├── video_projects_page.dart   # 영상 연대표 (풀페이지 스냅 + 타임라인)
│   │   └── guestbook_page.dart        # 방명록/문의 (로컬 state)
│   ├── apps/
│   │   ├── app_wrapper.dart           # 서브앱 공통 래퍼 (뒤로가기 바)
│   │   ├── jara_holdem/               # Jara Holdem Timer (ex-work에서 마이그레이션)
│   │   │   ├── jara_holdem_app.dart       # Provider 감싼 진입 위젯
│   │   │   ├── models/                    # BlindLevel, BreakLevel, TournamentStructure
│   │   │   ├── presets/                   # default_presets.dart
│   │   │   ├── providers/                 # TournamentProvider (상태+타이머)
│   │   │   ├── screens/                   # TimerScreen, SetupScreen, HelpScreen
│   │   │   ├── services/                  # SoundService, StorageService, StructureGenerator/Parser
│   │   │   └── widgets/                   # CountdownDisplay, BlindInfoDisplay, ControlButtons, LevelListEditor
│   │   ├── roulette/
│   │   │   └── roulette_main.dart         # 자마카세 인원뽑기 (localStorage 저장 + 전체삭제)
│   │   └── web_embed/
│   │       └── html_app_page.dart         # HTML 프로젝트 iframe 임베드 위젯
│   ├── widgets/
│   │   ├── nav_bar.dart               # 상단 네비게이션 (메인용)
│   │   ├── page_scaffold.dart         # 서브페이지 공통 레이아웃
│   │   ├── section_header.dart        # 섹션 헤더 + GlowingCard
│   │   ├── youtube_player.dart        # YouTube iframe 임베드 (youtube-nocookie.com)
│   │   └── drive_video_player.dart    # (미사용, YouTube로 전환됨)
│   └── sections/                  # (구버전 싱글페이지용, 정리 대상)
│       ├── hero_section.dart
│       ├── about_section.dart
│       ├── projects_section.dart
│       ├── contact_section.dart
│       └── footer_section.dart
├── assets/
│   └── Blanche_Logo.png           # 메인 페이지 로고 (흰색, 투명 배경)
├── web/
│   ├── index.html                 # Flutter web 엔트리
│   ├── CNAME                      # GitHub Pages 커스텀 도메인 (pure-blanche.com)
│   ├── assets/
│   │   └── Blanche_Animation.mp4  # 인트로 영상 (~9MB)
│   └── apps/
│       ├── jamakase/index.html + BG.mp3   # Jamakase Notify (HTML 프로젝트)
│       ├── birthday/index.html            # 생일 선물 리스트 (HTML 프로젝트)
│       └── video-player.html              # Google Drive preview iframe 래퍼
├── .github/
│   └── workflows/
│       └── deploy.yml             # GitHub Actions: Flutter 빌드 → Pages 배포
└── pubspec.yaml
```

## Routes

| Path | Page | 설명 |
|------|------|------|
| `/` | `MainPage` | 2-page 스냅 스크롤: 히어로 소개 (Page 0) + 3개 네비카드 & 푸터 (Page 1). 첫 접속 시 인트로 영상 재생 (sessionStorage 기반) |
| `/code` | `CodeProjectsPage` | 4개 프로젝트 카드 → 클릭 시 각 앱 실행 |
| `/video` | `VideoProjectsPage` | 영상 연대표 (7개 시대, 풀페이지 스냅) |
| `/guestbook` | `GuestbookPage` | 방명록 입력/표시 (로컬 state) — 현재 공사중 오버레이 |
| `/app/jara-holdem` | `AppWrapper` + `JaraHoldemApp` | 포커 토너먼트 타이머 |
| `/app/roulette` | `AppWrapper` + `RouletteAppEntry` | 자마카세 인원뽑기 룰렛 |
| `/app/jamakase` | `HtmlAppPage` | Jamakase Notify (iframe) |
| `/app/birthday` | `HtmlAppPage` | 생일 선물 리스트 (iframe) |

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
- `lib/sections/`는 구버전 싱글페이지 구조의 잔재 — 정리 대상
- `lib/widgets/drive_video_player.dart`는 미사용 (YouTube로 전환됨) — 정리 대상

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
