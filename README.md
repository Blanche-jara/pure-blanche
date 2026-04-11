# Pure Blanche

직접 만든 유틸리티들을 모아둔 웹사이트.

## Pages

| Page | Description |
|------|-------------|
| **Code Projects** | 코딩 프로젝트 4개를 웹에서 바로 실행 |
| **Video Works** | 영상 작업물을 연대표 형태로 열람 |
| **Guestbook** | 방명록 / 문의 |

## Code Projects

| Project | Type | Description |
|---------|------|-------------|
| Jara Holdem Timer | Flutter | 포커 토너먼트 블라인드 타이머 & 구조 관리 |
| 자마카세 인원뽑기 | Flutter | 룰렛 애니메이션으로 참가자 랜덤 추첨 |
| Jamakase Notify | Web | 프라이빗 디너 이벤트 알림 페이지 |
| 생일 선물 리스트 | Web | 선물 목록 & 감사 페이지 |

## Video Timeline

영상 작업의 시대별 변화를 풀페이지 스냅 연대표로 구성.


## Tech Stack

- Flutter Web (Dart)
- Provider (state management)
- SharedPreferences (browser localStorage)
- YouTube iframe embed (youtube-nocookie.com)
- Design system based on VoltAgent dark theme

## Development

```bash
flutter run -d chrome        # dev server
flutter build web             # production build → build/web/
```

## Structure

```
lib/
├── main.dart              # entry + routing
├── theme/                 # colors, typography
├── pages/                 # main, code, video, guestbook
├── apps/                  # migrated sub-apps (jara-holdem, roulette, web embeds)
└── widgets/               # shared components (youtube player, nav, scaffolds)

web/apps/                  # HTML projects (jamakase, birthday) + video player
```

## Data Files

- `VIDEO_SLOTS.md` — 영상 연대표 데이터 관리
- `design/DESIGN.md` — 디자인 시스템 레퍼런스
- `CLAUDE.md` — AI 어시스턴트용 프로젝트 컨텍스트

## License

Private project by Blanche.
