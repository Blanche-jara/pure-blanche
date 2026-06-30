# Pure Blanche — 코드 프로젝트 서브앱 레퍼런스

> `/code`(`CodeProjectsPage`)에 카드로 노출되는 **10개 코드 프로젝트**의 상세 레퍼런스다.
> 출처: `lib/pages/code_projects_page.dart`(카드 데이터) + `lib/main.dart`(라우트) + 각 앱 디렉터리.
> 라우팅·디자인 등 사이트 전체 구조는 [ARCHITECTURE.md](./ARCHITECTURE.md)(특히 3장 라우트, 6장 서브앱 요약) 참조.
> 코드와 이 문서가 다르면 코드가 정답이며, 발견 즉시 고친다.

## 개요

총 10개. 실행 방식은 두 가지다.

- **Flutter 인앱(6개)**: `lib/apps/<name>/`의 Dart 위젯을 `AppWrapper`(상단 뒤로가기 바)로 감싸 라우트에 직접 연결.
- **HTML/사전빌드 임베드(4개)**: `web/apps/<name>/`의 정적 산출물을 `HtmlAppPage`(`lib/apps/web_embed/html_app_page.dart`)가 `iframe`(HtmlElementView)으로 로드.

| 앱 | 라우트 | 타입 | 위치 | 한 줄 목적 | 외부 링크 |
|----|--------|------|------|-----------|-----------|
| Jara Holdem Timer | `/app/jara-holdem` | Flutter | `lib/apps/jara_holdem/` | 포커 토너먼트 블라인드 타이머 & 매니저 | [APK](https://drive.google.com/file/d/1UsKiAJHPsZe6JUVeP9EOWsg511bBOVSg/view?usp=sharing) |
| Who's the Nut? | `/app/whos-the-nut` | Flutter | `lib/apps/whos_the_nut/` | 너트 핸드 맞히기 + 사이드팟 분배 미니게임 | [APK](https://drive.google.com/file/d/1SliqndoB7B_Uoyxa52ZeaueQx3krhbeW/view?usp=sharing) · 정책/패치노트(`web/apps/whos-the-nut/`) |
| ICM Split | `/app/icm-split` | Flutter | `lib/apps/icm_split/` | 토너먼트 딜(상금 분배)·버블 의사결정 ICM 계산기 | [APK](https://drive.google.com/file/d/149H-LL1Jxr-hk1EBSzu17rKF2QkpXpfk/view?usp=sharing) |
| 자마카세 인원뽑기 | `/app/roulette` | Flutter | `lib/apps/roulette/` | 이벤트 참가자 랜덤 룰렛 | — |
| It's Safe Link | `/app/safe-link` | Flutter | `lib/apps/safe_link/` | 본인 도메인 경유 trustable URL redirector | — |
| THE CANNON | `/app/cannon` | Flutter | `lib/apps/cannon/` | 주사위 테마 랜덤 추첨기 | [EXE](https://drive.google.com/uc?export=download&id=1v_DzUDF51JRhPviEllY_UmHQzNqTP-aj) |
| Jamakase Notify | `/app/jamakase` | Web | `web/apps/jamakase/` | 프라이빗 디너 이벤트 알림 페이지 | — |
| 제 25회 자라 생일 선물 리스트 | `/app/birthday` | Web | `web/apps/birthday/` | 생일 선물 목록 & 감사 페이지 | — |
| Word Guesser | `/app/word-guesser` | Web(사전빌드 Flutter) | `web/apps/word-guesser/` | 한글 워들(풀어쓰기) 솔버 | — |
| Word Finder | `/app/word-finder` | Web(사전빌드 Flutter) | `web/apps/word-finder/` | 꼬맨틀(한국어 Semantle) 추측 보조기 | — |

---

## Flutter 인앱

### Jara Holdem Timer — `/app/jara-holdem`

- **목적**: 포커 토너먼트 타이머 & 매니저. 블라인드 자동 진행, 사운드 알림, 커스텀 구조 생성/파싱, 캐시게임 모드까지 지원하는 올인원 앱.
- **핵심 기능**: 블라인드 레벨 타이머 & 자동 진행 / 토너먼트 구조 생성기·파서 / 프리셋 저장·불러오기 / 사운드 알림 & 브레이크 관리.
- **기술/패키지**: Flutter, Dart, `provider`, `audioplayers`, `shared_preferences`.
- **주요 파일 구조** (`lib/apps/jara_holdem/`):
  - `jara_holdem_app.dart` — Provider로 감싼 진입 위젯
  - `models/` — `blind_level.dart`, `break_level.dart`, `tournament_structure.dart`
  - `presets/default_presets.dart`
  - `providers/tournament_provider.dart` — 상태 + 타이머
  - `screens/` — `timer_screen.dart`, `setup_screen.dart`, `help_screen.dart`
  - `services/` — `sound_service.dart`, `storage_service.dart`, `structure_generator.dart`, `structure_parser.dart`, `fullscreen_service.dart`(+`fullscreen_web.dart`/`fullscreen_stub.dart` 조건부 import)
  - `widgets/` — `countdown_display.dart`, `blind_info_display.dart`, `control_buttons.dart`, `level_list_editor.dart`
- **다운로드**: Google Drive APK (위 표).

### Who's the Nut? — `/app/whos-the-nut`

- **목적**: 포커 미니게임 모음. 커뮤니티 5장만 보고 너트 핸드 맞히기 + 다인원 올인 시 메인/사이드 팟 분배 계산.
- **핵심 기능**: 7카드 핸드 평가 엔진 / C(47,2) 너트 핸드 자동 탐색 / 사이드 팟 자동 계산·분배 / 청크·타이 시 odd chip 처리.
- **기술/패키지**: Flutter, Dart, 자체 포커 핸드 평가 로직.
- **주요 파일 구조** (`lib/apps/whos_the_nut/`):
  - `whos_the_nut_app.dart` — 진입 위젯
  - `models/` — `playing_card.dart`, `hand_evaluator.dart`, `restriction.dart`
  - `screens/` — `nut_hand_screen.dart`, `side_pot_screen.dart`
  - `widgets/poker_card.dart`
- **외부 링크**: APK(Drive) + 카드에 `Privacy Policy`(`apps/whos-the-nut/privacy.html`)·`Patch Notes`(`apps/whos-the-nut/release_notes/patch_notes.html`) 링크 노출. 관련 정적 HTML/스크린샷은 `web/apps/whos-the-nut/`.

### ICM Split — `/app/icm-split`

- **목적**: 토너먼트 막바지 딜(상금 분배)과 버블 의사결정을 ICM 기준으로 계산. ICM · Chip-chop · Save-for-winner 비교 + 콜/폴드를 ICM EV로 판단.
- **핵심 기능**: ICM 지분(₩) 계산 & 막대그래프 시각화 / ICM·Chip-chop·Save 분배 비교 / 버블 팩터·콜 필요 에쿼티·푸시·폴드 EV / 시나리오 저장·불러오기(로컬).
- **기술/패키지**: Flutter, Dart, `flutter_riverpod`(상태), `hive`/`hive_flutter`(영속), `fl_chart`(차트), `uuid`. 자체 ICM/에쿼티 엔진.
- **주요 파일 구조** (`lib/apps/icm_split/`):
  - `icm_split_app.dart` — 진입 위젯
  - `core/` — `icm_calculator.dart`, `deal_calculator.dart`, `decision_tools.dart`, `payout_presets.dart`, `formatting.dart`
  - `poker/` — `cards.dart`, `equity.dart`, `evaluator.dart`
  - `state/` — Riverpod providers (`icm_providers`, `deal_providers`, `decision_providers`, `equity_providers`, `persistence_providers`, `scenario_controller`)
  - `models/` — `player.dart`, `payout_structure.dart`, `scenario.dart`
  - `data/scenario_repository.dart`, `l10n/`(한국어 현지화), `ui/`(`home_shell`, `screens/`, `widgets/`, `theme.dart`, `design_tokens.dart`)
- **다운로드**: Google Drive APK (위 표).

### 자마카세 인원뽑기 — `/app/roulette`

- **목적**: 자마카세 이벤트 참가자를 랜덤으로 뽑는 룰렛 앱. 인원 추가/삭제, 뽑기 수 조절, 스피너 애니메이션으로 결과 발표.
- **핵심 기능**: 참가자 리스트 관리(최대 30명) / 뽑기 인원 수 조절 / 룰렛 스피너 애니메이션 / 페이드 페이지 전환. 참가자 목록은 localStorage에 저장(전체삭제 지원).
- **기술/패키지**: Flutter, Dart, Pretendard 폰트, `shared_preferences`(localStorage).
- **주요 파일 구조** (`lib/apps/roulette/`): `roulette_main.dart`(단일 파일, `RouletteAppEntry`).

### It's Safe Link — `/app/safe-link`

- **목적**: 본인 도메인을 통한 trustable redirector. lz-string으로 압축된 URL을 hash에 담아 정적 페이지에서 디코드 → redirect.
- **핵심 기능**: 백엔드·DB·커밋 0(완전 정적) / lz-string 압축 + hash 인코딩 / 도착지 미리보기 후 자동 이동(피싱 방지) / http·https 스킴만 허용.
- **기술/패키지**: Flutter, Dart, `lz-string`(JS interop — `web/index.html`의 `<script>`로 로드), 정적 HTML, `package:web`.
- **주요 파일 구조** (`lib/apps/safe_link/`): `safe_link_app.dart`(`@JS('LZString.compressToEncodedURIComponent')` interop), `_dict.dart`(URL 단축 사전).

### THE CANNON — `/app/cannon`

- **목적**: 주사위 테마 랜덤 추첨기. 상한 숫자를 정하면 6단위로 주사위 개수가 자동 증가하고, DRAW 버튼을 누르면 주사위가 굴러가며 결과 발표.
- **핵심 기능**: 상한별 주사위 개수 자동 결정(1D~) / 70ms 텀블 애니메이션(~1.7초) / 거대 폰트 결과 표시 / 커스텀 페인터 주사위 + 빠른 면 전환.
- **기술/패키지**: Flutter, Dart, `CustomPainter`(주사위 렌더), 스트림 친화적 애니메이션.
- **주요 파일 구조** (`lib/apps/cannon/`): `cannon_app.dart`(단일 파일).
- **다운로드**: Google Drive EXE (위 표, `downloadLabel: 'EXE'`).

---

## HTML / 사전빌드 임베드

> 모두 `HtmlAppPage`로 `web/apps/<name>/index.html`을 iframe 임베드. `lib/main.dart`에서 `htmlPath`만 지정.

### Jamakase Notify — `/app/jamakase`

- **목적**: "자라 + 오마카세" 프라이빗 디너 이벤트 알림 페이지. 배경 음악 + 골드 톤 다크 테마 + 구글 폼 연동 참가 신청을 원페이지로 구성.
- **핵심 기능**: 다크 테마 + 골드(#D4AF37) 악센트 / 배경 음악 재생·토글 / Google Forms 참가 신청 연동 / 네이버 지도 위치 안내.
- **기술/패키지**: HTML, Tailwind CSS, JavaScript, Audio API.
- **주요 파일**: `web/apps/jamakase/index.html`, `BG.mp3`(배경 음악). `htmlPath: 'apps/jamakase/index.html'`.

### 제 25회 자라 생일 선물 리스트 — `/app/birthday`

- **목적**: 25번째 생일 선물 목록 & 감사 페이지.
- **핵심 기능**: 다크/라이트 모드 토글 / 2열 반응형 선물 리스트 / 기부자 익명 처리 / 핑크(#ee2b8c) 포인트 컬러.
- **기술/패키지**: HTML, Tailwind CSS, Noto Sans KR.
- **주요 파일**: `web/apps/birthday/index.html`. `htmlPath: 'apps/birthday/index.html'`. (카드 subtitle: `251228`.)

### Word Guesser — `/app/word-guesser`

- **목적**: 풀어쓰기 한글 워들 3종(카카오톡 오늘의 단어 5자 · 꼬들 6자 · 꼬오오오오들 12자) 필승법. 정보이론(엔트로피)으로 최적 추측을 추천하고, 칸별 색을 입력하면 후보를 좁혀 정답에 도달.
- **핵심 기능**: 3변형 탭(5/6/12 자모) / 엔트로피 최대화 추천 + 시도 내 수렴 / 쌍자음·복합모음·겹받침 자모 분해 / 칸별 색 입력 + 키보드 히트맵.
- **기술/패키지**: 사전빌드 **Flutter Web**(별도 빌드 산출물), Dart, 정보이론(엔트로피), 한글 자모 처리.
- **주요 파일**(`web/apps/word-guesser/`): `index.html`, `main.dart.js`, `flutter_bootstrap.js`, `canvaskit/`, `assets/assets/`의 사전 데이터 — `kakao5_*`, `kordle6_*`, `kordle12_*`의 `answers.txt`/`guesses.txt`. `htmlPath: 'apps/word-guesser/index.html'`.

### Word Finder — `/app/word-finder`

- **목적**: 꼬맨틀(한국어 Semantle) 추측 보조기. 단어와 유사도 점수를 입력하면 fastText 임베딩으로 정답 벡터 방향을 삼각측량해 다음 추천 단어를 정렬.
- **핵심 기능**: 능선 최소제곱 삼각측량(Cholesky) / 정답·풀 임베딩 51k·4.6k(int8 300d) / 최원점 시드 탐색 + 고유사도 가중 / 평균 ~30추측 수렴(시뮬).
- **기술/패키지**: 사전빌드 **Flutter Web**, Dart, fastText 임베딩(int8 양자화).
- **주요 파일**(`web/apps/word-finder/`): `index.html`, `main.dart.js`, `canvaskit/`, 임베딩 데이터 `assets/assets/` — `vecs.i8`(int8 벡터), `scales.f32`, `vocab.txt`, `answers.txt`, `meta.txt`. `htmlPath: 'apps/word-finder/index.html'`.

---

## 카드 메타데이터 형식 (참고)

`code_projects_page.dart`의 `_ProjectData`가 카드 한 장을 정의한다. 새 앱 추가 시 이 배열에 항목을 더하고 `lib/main.dart`에 라우트를 추가한다.

| 필드 | 의미 |
|------|------|
| `title` / `subtitle` | 제목 / 폴더명(Consolas 표기) |
| `description` / `features` | 설명 문단 / 기능 불릿(보통 4개) |
| `techTags` | 기술 태그 칩 |
| `icon` / `type` | 아이콘 / `"flutter"`·`"web"` 배지 |
| `route` | 탭 시 `Navigator.pushNamed` 대상 |
| `downloadUrl` / `downloadLabel` | (선택) 다운로드 버튼 URL / 라벨(기본 `APK`, CANNON은 `EXE`) |
| `privacyUrl` / `patchNotesUrl` | (선택) 카드 하단 정책·패치노트 링크 (현재 Who's the Nut?만 사용) |
