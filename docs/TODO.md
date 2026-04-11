# Pure Blanche — TODO Roadmap

## Phase 1: 기본 구조 (완료)

- [x] Flutter Web 프로젝트 초기화
- [x] 디자인 시스템 적용 (AppColors, AppTheme — DESIGN.md 기반)
- [x] 멀티페이지 라우팅 (`/`, `/code`, `/video`, `/guestbook`)
- [x] 메인 페이지: 히어로 + 3개 네비게이션 카드
- [x] 서브페이지 공통 레이아웃 (PageScaffold — 뒤로가기 + 스크롤)

## Phase 2: Code Projects 마이그레이션 (완료)

- [x] ex-work 4개 프로젝트 분석 (jara-holdem, roulette_app, Jamakase, 251228)
- [x] Code Projects 페이지에 실제 프로젝트 데이터 반영 (제목, 설명, 기능, 기술 스택)
- [x] Flutter 앱 마이그레이션: jara-holdem → `lib/apps/jara_holdem/`
- [x] Flutter 앱 마이그레이션: roulette_app → `lib/apps/roulette/`
- [x] HTML 프로젝트 복사: Jamakase, 251228 → `web/apps/`
- [x] 카드 클릭 → 실제 앱 실행 라우팅 연결
- [x] jara-holdem SetupScreen Provider 스코프 버그 수정
- [x] 룰렛 앱 참가자 리스트 localStorage 저장/복원 추가
- [x] 룰렛 앱 "전체 삭제" 버튼 추가
- [x] 프로젝트 카드에 Flutter App / Web 타입 배지 추가

## Phase 3: Video Works 연대표 (완료)

- [x] 영상 페이지를 격자 → 연대표 풀페이지 스냅 방식으로 리뉴얼
- [x] 좌측 타임라인 레일 + 우측 메인/서브 영상 레이아웃
- [x] 시대별 챕터: 2016 / 2018 / 2019 / 2021 / 2023 / 2025 / 2026
- [x] 스크롤 쿨다운 (800ms 락, 한 번 = 한 챕터)
- [x] 인트로 애니메이션 (연대표 중앙 → 좌측 슬라이드 → 콘텐츠 페이드인)
- [x] 서브 영상 ← → 화살표 페이지네이션
- [x] YouTube iframe 플레이어 임베드 (youtube-nocookie.com)
- [x] YouTube 자동 썸네일 미리보기 (img.youtube.com)
- [x] 서브 영상 클릭 → 팝업 모달 플레이어
- [x] `VIDEO_SLOTS.md` 데이터 관리 파일 생성

## Phase 4: 남은 기능

- [ ] Guestbook 백엔드 연동
  - [ ] Firebase Firestore or Supabase 선택
  - [ ] 메시지 영구 저장/불러오기
  - [ ] 스팸 방지 (rate limit or captcha)
- [ ] VIDEO_SLOTS.md에 실제 영상 채우기 (youtubeId 추가)
- [ ] Hero 영상 자동재생 (youtubeId 있을 때 YouTube autoplay)
- [ ] `lib/sections/` 정리 (구버전 싱글페이지 위젯 제거)
- [ ] `lib/widgets/drive_video_player.dart` 제거 (YouTube로 전환 완료)

## Phase 5: 디자인 완성도

- [ ] 메인 페이지 ↔ 서브페이지 전환 애니메이션 (fade/slide)
- [ ] 모바일 대응 개선 (비디오 페이지 인트로, 네비게이션 등)
- [ ] 다크/라이트 모드 토글 (DESIGN.md에 light preview 존재)
- [ ] 파비콘 & OG 메타태그 커스텀
- [ ] 로딩 스플래시 화면 개선

## Phase 6: 배포 & 인프라

- [ ] GitHub Pages or Vercel or Firebase Hosting 배포
- [ ] 커스텀 도메인 연결
- [ ] SEO 기본 설정 (title, description, OG tags)
- [ ] CI/CD (GitHub Actions → 자동 빌드/배포)

## Phase 7: 추가 기능 (선택)

- [ ] 블로그/글쓰기 섹션
- [ ] 이력서/CV 다운로드
- [ ] 다국어 지원 (한국어/영어)
- [ ] PWA 설정 (오프라인 지원)
- [ ] 새 유틸리티 앱 추가 (Code Projects 확장)
