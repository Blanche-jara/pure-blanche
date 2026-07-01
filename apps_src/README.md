# apps_src — 사전빌드 임베드 앱의 소스

`web/apps/`에 iframe으로 임베드되는 Flutter 앱들의 **소스 프로젝트**를 모아둔 곳.
메인 앱(`lib/`)과 별개로 각자 독립 빌드된다. (다른 6개 서브앱은 `lib/apps/`에 소스가 직접 편입돼 있고, 이쪽은 사전빌드 번들로 임베드되는 앱들이다.)

## word-guesser — 한글 워들 "필승법" 솔버

- 진입: 메인 앱 라우트 `/#/app/word-guesser` → `HtmlAppPage`가 `web/apps/word-guesser/`(사전빌드 번들)를 iframe 임베드.
- 변형 3종: `kakao5`(카카오톡 오늘의 단어·5자모) / `kordle6`(꼬들·6자모) / `kordle12`(꼬오오오오들·12자모).
- 외부 게임의 색 결과를 입력하면 엔트로피로 후보를 좁히는 **솔버**(정답을 자체 생성하지 않음).
- **오늘의 정답 보고**: 후보가 1개로 수렴하거나 정답을 맞히면 세션당 1회 `POST /api/wg/answer {variant, answer}` (`lib/report.dart`). 관리자 통계 탭이 이걸 집계해 "오늘의 정답"으로 표시.

### 수정 후 재배포 절차
```bash
cd apps_src/word-guesser
flutter pub get
# 주의: Git Bash는 --base-href 의 '/'를 경로로 변환하므로 PowerShell에서 빌드 권장
flutter build web --release --base-href /apps/word-guesser/
```
그다음 `build/web` 전체를 `web/apps/word-guesser/`로 **미러 복사**(robocopy /MIR 등) → 커밋 → 메인 앱 푸시로 배포.
빌드 산출물(`build/`, `.dart_tool/`)은 프로젝트 `.gitignore`로 제외된다.

> word-finder(Semantle) 소스는 원본 `Documents/Word-Guesser/semantle/`에 있으며, 필요 시 같은 방식으로 편입 가능(임베딩 에셋이 커서 아직 미편입).
