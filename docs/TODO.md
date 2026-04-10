# Pure Blanche — TODO Roadmap

## Phase 1: 기본 구조 (완료)

- [x] Flutter Web 프로젝트 초기화
- [x] 디자인 시스템 적용 (AppColors, AppTheme — DESIGN.md 기반)
- [x] 멀티페이지 라우팅 (`/`, `/code`, `/video`, `/guestbook`)
- [x] 메인 페이지: 히어로 + 3개 네비게이션 카드
- [x] 서브페이지 공통 레이아웃 (PageScaffold — 뒤로가기 + 스크롤)
- [x] Code Projects 페이지 셸 (플레이스홀더 카드)
- [x] Video Works 페이지 셸 (격자 플레이스홀더)
- [x] Guestbook 페이지 셸 (입력 폼 + 로컬 state 리스트)

## Phase 2: 콘텐츠 연동

- [ ] `ex-work/` 폴더 생성 및 코딩 프로젝트 구조 정의
  - [ ] 각 프로젝트별 메타데이터 포맷 결정 (JSON? YAML? 폴더 구조?)
  - [ ] ex-work → Code Projects 페이지 동적 연동
  - [ ] 프로젝트 상세 페이지 or 모달 추가
- [ ] Video Works 페이지 실제 영상 링크 추가
  - [ ] 유튜브/비메오 썸네일 자동 표시 (URL → 썸네일 추출)
  - [ ] 클릭 시 영상 재생 (외부 링크 or 임베드)
- [ ] Guestbook 백엔드 연동
  - [ ] Firebase Firestore or Supabase 등 선택
  - [ ] 메시지 영구 저장/불러오기
  - [ ] 스팸 방지 (rate limit or captcha)

## Phase 3: 디자인 완성도

- [ ] 페이지 전환 애니메이션 (fade, slide 등)
- [ ] 스크롤 기반 등장 애니메이션 (fade-in on scroll)
- [ ] `lib/sections/` 정리 (구버전 싱글페이지 위젯 제거 or 재활용)
- [ ] 메인 페이지 NavBar 활용 여부 결정 (현재 미사용)
- [ ] 다크/라이트 모드 토글 (DESIGN.md에 light preview도 존재)
- [ ] 파비콘 & OG 메타태그 커스텀
- [ ] 로딩 스플래시 화면 개선

## Phase 4: 배포 & 인프라

- [ ] GitHub Pages or Vercel or Firebase Hosting 배포
- [ ] 커스텀 도메인 연결
- [ ] SEO 기본 설정 (title, description, OG tags)
- [ ] Google Analytics or 간단한 방문자 추적
- [ ] CI/CD (GitHub Actions → 자동 빌드/배포)

## Phase 5: 추가 기능 (선택)

- [ ] 블로그/글쓰기 섹션
- [ ] 이력서/CV 다운로드
- [ ] 다국어 지원 (한국어/영어)
- [ ] 키보드 네비게이션 & 접근성 개선
- [ ] PWA 설정 (오프라인 지원)
