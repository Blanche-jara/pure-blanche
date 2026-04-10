# Pure Blanche — Personal Portfolio Website

Blanche의 자기소개 웹사이트. Flutter Web으로 구축.

## Tech Stack

- **Framework**: Flutter 3.38.7 (Web)
- **Language**: Dart 3.10.7
- **Fonts**: Google Fonts (Inter), system-ui (headings), Consolas (code)
- **Design System**: `design/DESIGN.md` 기반 — VoltAgent-inspired dark theme

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
├── CLAUDE.md              # 이 파일
├── design/                # 디자인 시스템 원본 (DESIGN.md, preview HTML)
├── docs/
│   └── TODO.md            # 작업 로드맵
├── lib/
│   ├── main.dart          # 앱 엔트리, 라우팅 정의
│   ├── theme/
│   │   ├── app_colors.dart    # 디자인 토큰 색상
│   │   └── app_theme.dart     # ThemeData + 타이포그래피
│   ├── pages/
│   │   ├── main_page.dart         # 메인 (히어로 + 3개 네비카드)
│   │   ├── code_projects_page.dart  # 코딩 프로젝트 목록
│   │   ├── video_projects_page.dart # 영상 작업 격자 그리드
│   │   └── guestbook_page.dart      # 방명록/문의
│   ├── widgets/
│   │   ├── nav_bar.dart           # 상단 네비게이션 (메인용)
│   │   ├── page_scaffold.dart     # 서브페이지 공통 레이아웃 (뒤로가기 + 스크롤)
│   │   └── section_header.dart    # 섹션 헤더 + GlowingCard
│   └── sections/              # (구버전 싱글페이지용, 추후 정리 대상)
│       ├── hero_section.dart
│       ├── about_section.dart
│       ├── projects_section.dart
│       ├── contact_section.dart
│       └── footer_section.dart
├── web/                   # Flutter web 엔트리 (index.html, manifest)
└── pubspec.yaml
```

## Routes

| Path | Page | 설명 |
|------|------|------|
| `/` | `MainPage` | 히어로 + 3개 네비게이션 카드 |
| `/code` | `CodeProjectsPage` | 코딩 프로젝트 (ex-work 폴더 연동 예정) |
| `/video` | `VideoProjectsPage` | 영상 프로젝트 격자 그리드 |
| `/guestbook` | `GuestbookPage` | 방명록 입력/표시 |

## Commands

```bash
flutter run -d chrome        # 로컬 개발 서버
flutter build web             # 프로덕션 빌드 → build/web/
```

## Conventions

- 색상은 반드시 `AppColors` 상수 사용 (하드코딩 금지)
- 호버 인터랙션: 300ms AnimatedContainer, border → signalGreen 전환
- 반응형 기준: 768px (모바일/데스크톱), 600px (카드 그리드 컬럼 수)
- 서브페이지는 `PageScaffold` 위젯으로 감싸서 일관된 레이아웃 유지
- `lib/sections/`는 이전 싱글페이지 구조의 잔재 — 필요시 정리
