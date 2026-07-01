# Pure Blanche — 아키텍처 레퍼런스

> 이 문서는 **현재 코드 기준**의 사실만 담는다. 계획/희망사항은 [TODO.md](./TODO.md)로.
> 코드와 이 문서가 다르면 코드가 정답이며, 발견 즉시 이 문서를 고친다.

## 1. 정체성

Flutter Web 단일 페이지 앱(SPA)으로 만든 **Blanche의 개인 포트폴리오 + 실사용 유틸리티 허브**.
포트폴리오(코드 프로젝트 쇼케이스 + 영상 연대표)와 실제로 쓰는 도구 모음이 한 사이트에 합쳐져 있다.

- 도메인: `pure-blanche.com` (Cloudflare DNS → GitHub Pages)
- 단일 `MaterialApp` + named routes 기반. 백엔드 없음(현재). 모든 데이터는 정적 또는 브라우저 localStorage.

## 2. 기술 스택

| 항목 | 값 |
|------|-----|
| 프레임워크 | Flutter (Web 전용) |
| 언어 | Dart, `environment.sdk: ^3.10.7` (pubspec 기준) |
| 로컬 Flutter | 3.38.7 stable (개발 머신 기준 — 참고용, CI는 stable 채널 최신) |
| 상태관리 | Provider(jara-holdem), Riverpod+Hive(icm-split), setState(나머지) |
| 저장소 | SharedPreferences / 브라우저 localStorage (사용자별 독립), 서버 DB 없음 |
| 폰트 | Google Fonts(Inter), system-ui(Segoe UI 헤딩), Consolas(코드) |
| 배포 | GitHub Pages + GitHub Actions (`.github/workflows/deploy.yml`) |

**주요 의존성** (`pubspec.yaml`): `provider`, `audioplayers`, `shared_preferences`, `intl`, `web`, `url_launcher`, `pointer_interceptor`, `google_fonts`, `flutter_riverpod`, `hive`/`hive_flutter`, `fl_chart`, `uuid`.

## 3. 라우팅 (`lib/main.dart`)

`MaterialApp.routes`로 정의된 14개 named route. `debugShowCheckedModeBanner: false`, `theme: AppTheme.dark`, `initialRoute: '/'`.

| Path | 위젯 | 설명 |
|------|------|------|
| `/` | `MainPage` | 2-page 세로 스냅: 히어로 + 3 네비카드. 첫 방문 시 인트로 영상 |
| `/code` | `CodeProjectsPage` | 코드 프로젝트 10개 카드 |
| `/video` | `VideoProjectsPage` | 영상 연대표 (7개 시대 풀페이지 스냅) |
| `/guestbook` | `GuestbookPage` | 방명록 (Cloudflare Workers+D1 연동) |
| `/admin` | `GuestbookPage(adminEntry:true)` | 숨김 관리자 진입 (비밀번호 → 방명록 관리/접속 통계 탭) |
| `/app/jara-holdem` | `AppWrapper`+`JaraHoldemApp` | 포커 토너먼트 타이머 (Flutter) |
| `/app/roulette` | `AppWrapper`+`RouletteAppEntry` | 자마카세 인원뽑기 룰렛 (Flutter) |
| `/app/whos-the-nut` | `AppWrapper`+`WhosTheNutApp` | 너트 핸드 평가기 (Flutter) |
| `/app/icm-split` | `AppWrapper`+`IcmSplitApp` | ICM 분배 계산기 (Flutter, Riverpod) |
| `/app/safe-link` | `AppWrapper`+`SafeLinkApp` | URL 안전 리다이렉트 (Flutter) |
| `/app/cannon` | `AppWrapper`+`CannonApp` | 주사위 추첨기 THE CANNON (Flutter) |
| `/app/jamakase` | `HtmlAppPage` | Jamakase Notify (HTML iframe) |
| `/app/birthday` | `HtmlAppPage` | 자라 생일 선물 리스트 (HTML iframe) |
| `/app/word-guesser` | `HtmlAppPage` | 한글 워들 솔버 (사전빌드된 Flutter Web을 iframe) |
| `/app/word-finder` | `HtmlAppPage` | Semantle 헬퍼 (사전빌드된 Flutter Web을 iframe) |

- **Flutter 인앱 실행**: `AppWrapper`로 감싸 상단 뒤로가기 바 통일.
- **HTML/사전빌드 임베드**: `HtmlAppPage` → `web/apps/<name>/`의 정적 산출물을 iframe/HtmlElementView로 로드.

## 4. 디렉터리 구조

```
pure-blanche/
├── CLAUDE.md                  # 하네스(빠른 참조) — docs/와 동기화 유지
├── VIDEO_SLOTS.md             # 영상 연대표 데이터 원본
├── design/DESIGN.md           # 디자인 시스템 원본
├── docs/                      # ← 이 문서 세트 (상세 명세)
├── lib/
│   ├── main.dart              # 엔트리 + 라우팅
│   ├── theme/                 # app_colors.dart, app_theme.dart
│   ├── pages/                 # main / code_projects / video_projects / guestbook
│   ├── apps/                  # 서브앱 6개(Flutter) + app_wrapper + web_embed
│   ├── widgets/               # nav_bar, page_scaffold, section_header, youtube_player ...
│   └── services/              # guestbook_service.dart, stats_service.dart
├── backend/                   # Cloudflare Worker + D1 (방명록 + 접속통계/WG정답 API)
├── apps_src/                  # 사전빌드 임베드 앱 소스 (word-guesser) — apps_src/README.md
├── web/
│   ├── index.html, CNAME      # CNAME = pure-blanche.com
│   └── apps/                  # jamakase / birthday / word-guesser / word-finder / whos-the-nut(정책) ...
├── .github/workflows/deploy.yml
└── pubspec.yaml
```

## 5. 페이지별 아키텍처

### 5.1 MainPage (`lib/pages/main_page.dart`)
- 세로 2-page `PageView` 스냅 (Page0 히어로 / Page1 카드+푸터). 800ms 스크롤 락.
- **인트로 영상**: `sessionStorage`의 `intro_played`로 첫 방문 판별 → HTML5 `<video>`(`assets/Blanche_Animation.mp4`) muted 자동재생 → 페이드 전환. ESC/탭으로 스킵.
- 반응형 기준 768px.

### 5.2 CodeProjectsPage (`lib/pages/code_projects_page.dart`)
- Wrap 그리드(데스크톱 2열 / 모바일 1열, 기준 600px), 카드 10개.
- 카드: 아이콘+타입배지, 제목, 폴더명(Consolas), 설명, 기능 4줄, 기술 태그, (선택)다운로드 버튼/정책·패치노트 링크.
- 클릭 → `Navigator.pushNamed(route)`. 호버 시 border→signalGreen + 글로우.
- 앱별 상세는 [APPS.md](./APPS.md) 참조.

### 5.3 VideoProjectsPage (`lib/pages/video_projects_page.dart`, 최대 파일)
- `const _eras` 배열(7개 시대: 2016/2018/2019/2021/2023/2025/2026)을 세로 풀페이지 스냅.
- 데스크톱: 좌측 타임라인 사이드바 / 모바일: 좌측 점 인디케이터.
- 2.8초 3-phase 인트로 애니메이션. 800ms 스크롤 락.
- 메인 영상 + 서브 영상 스트립(← → 페이지네이션) + 서브 클릭 시 팝업 모달.
- **현재 실제 영상이 채워진 시대는 2021(청년 작가) 하나뿐** (메인 1 + 서브 16). 나머지는 placeholder.
- 데이터는 `VIDEO_SLOTS.md`와 수동 동기화. YouTube `youtube-nocookie.com/embed/{ID}` 임베드.

### 5.4 GuestbookPage (`lib/pages/guestbook_page.dart`)
- **Cloudflare Workers + D1 백엔드 연동**(영구 저장). 로딩/목록/에러 3-상태, graceful degradation.
- **관리자 모드**: 숨김 라우트 `/#/admin` → 비밀번호 → sessionStorage 세션. 탭 2개:
  - **방명록 관리**: 모든 글 수정/삭제.
  - **접속 통계**: 코드 프로젝트 페이지별 총/오늘/순방문 + Word Guesser "오늘의 정답"(변형별).
- 상세 명세(API 계약 포함): [GUESTBOOK_BACKEND.md](./GUESTBOOK_BACKEND.md).

## 6. 서브앱 요약 (`lib/apps/`)

| 디렉터리 | 앱 | 핵심 |
|----------|-----|------|
| `jara_holdem/` | Jara Holdem Timer | 블라인드 타이머, 구조 생성기/파서, 사운드, Provider |
| `whos_the_nut/` | Who's the Nut? | 7카드 핸드 평가, 너트 탐색, 사이드팟 분배 |
| `icm_split/` | ICM Split | ICM 분배 계산/시각화, Riverpod+Hive+fl_chart |
| `roulette/` | 자마카세 인원뽑기 | 참가자 룰렛 스피너 |
| `safe_link/` | It's Safe Link | lz-string 압축+hash, 도착지 미리보기 리다이렉트 |
| `cannon/` | THE CANNON | 주사위 텀블 애니메이션 추첨, CustomPainter |
| `web_embed/` | (래퍼) | `html_app_page.dart` — HTML/사전빌드 앱 iframe 임베드 |
| `app_wrapper.dart` | (래퍼) | 모든 Flutter 서브앱 공통 뒤로가기 바 |

`web/apps/`의 HTML 프로젝트: `jamakase/`, `birthday/`, `word-guesser/`(사전빌드 Flutter Web), `word-finder/`(사전빌드 Flutter Web + 임베딩 데이터), `whos-the-nut/`(개인정보처리방침·패치노트 HTML).

## 7. 디자인 시스템

색상은 반드시 `AppColors`(`lib/theme/app_colors.dart`) 상수 사용. 하드코딩 금지.

| 역할 | 상수 | Hex |
|------|------|-----|
| 페이지 BG | `abyss` | `#050507` |
| 카드 BG | `carbon` | `#101010` |
| 주 악센트 | `signalGreen` | `#00D992` |
| 버튼 텍스트 | `mint` | `#2FD6A1` |
| 보조 악센트 | `emerald` | `#10B981` |
| 보더/비활성 | `warmCharcoal` | `#3D3A39` |
| 주 텍스트 | `snow` | `#F2F2F2` |
| 보조 텍스트 | `parchment` | `#B8B3B0` |
| 흐린 텍스트 | `steel` | `#8B949E` |
| Flutter 배지 | `softPurple` | `#818CF8` |
| 경고/위험/성공 | `warning`/`danger`/`success` | `#FFBA00`/`#FB565B`/`#008B00` |

타이포(`app_theme.dart`): displayLarge 60 / displayMedium 36 / headlineLarge 24(w700) / labelLarge 14(letterSpacing 2.52, 오버라인) / bodyLarge 16(Inter) / bodyMedium 14(Inter).

**인터랙션 규칙**: 호버 200~300ms `AnimatedContainer`, border → `signalGreen` 전환. 반응형 768px(모바일/데스크톱), 600px(카드 그리드 열 수).

## 8. 빌드 & 배포

```bash
flutter run -d chrome     # 로컬 개발
flutter build web         # 프로덕션 빌드 → build/web/
```

`.github/workflows/deploy.yml`: `main` 푸시 → flutter-action(stable) → `flutter pub get` → `flutter build web --release --base-href /` → `web/CNAME` 복사 → GitHub Pages 배포(`actions/deploy-pages@v4`).

## 9. 알려진 불일치 / 정리 대상

- `CLAUDE.md`가 "코드 프로젝트 4개", Flutter 버전 등 일부 구버전 정보 보유 → **동기화 필요** (c3 작업).
- `lib/sections/`(구 싱글페이지 위젯), `lib/widgets/drive_video_player.dart`(YouTube로 대체됨) → **삭제 대상** (import 없는지 확인 후).
- 영상 연대표 6개 시대(2021 외) placeholder → `VIDEO_SLOTS.md` 채우기 필요.
