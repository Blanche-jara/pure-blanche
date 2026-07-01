# WordFinder — 한국어 단어게임 도우미 모음

이 저장소에는 **독립 실행되는 두 개의 Flutter 웹앱**이 있습니다 (각자 따로 빌드·배포):

| 앱 | 위치 | 설명 | 무게 |
|---|---|---|---|
| **오늘의 단어 필승법** | 루트(`/`) | 카카오톡 한글 워들 솔버 (5턴 보장) | 가벼움 |
| **꼬맨틀 추측기** | [`semantle/`](semantle/) | 한국어 Semantle 추측 보조기 (의미 임베딩) | ~16MB 에셋 |

> 배포 팁: 두 앱은 각각 독립 페이지(예: `/wordle`, `/semantle`)로 올리세요. 무거운 꼬맨틀
> 임베딩은 그 페이지를 열 때만 로드되고 이후 캐시되므로, 나머지 사이트·워들은 영향받지 않습니다.

---

# 오늘의 단어 · 필승법 (Korean Hangul Wordle Solver)

풀어쓰기 한글 워들의 **필승법**을 제공하는 Flutter 웹앱. 탭으로 3변형을 지원한다:
스타팅 단어를 추천받아 게임에 입력 → 나온 색을 앱에 그대로 칠하면 → 다음 최적 단어들을 추천한다.

| 탭 | 게임 | 길이 | 시도 | 정답풀 / 추측풀 |
|---|---|---|---|---|
| 오늘의 단어 | 카카오톡 | 5자모 | 5 | 849 / 22,805 |
| 꼬들 | [kordle.kr](https://kordle.kr/) | 6자모 | 6 | 1,825 / 52,502 |
| 꼬오오오오들 | [koooo.kordle.kr](https://koooo.kordle.kr/) | 12자모 | 6 | 501 / 50,513 |

## 게임 규칙 (반영된 전제)

- 세 변형 모두 키보드에 **기본 자음 14 + 기본 모음 10**(총 24)만 존재, 각 칸 = 기본 자모 하나,
  append-only 입력(두벌식 조합 없음) → 길이만 5/6/12로 다르고 분해 규칙은 동일.
- 모든 합성 글자를 두벌식 입력 순서대로 기본 자모로 **완전 분해**한다:
  - 쌍자음: ㄲ→ㄱ+ㄱ, ㅉ→ㅈ+ㅈ … (초성·받침 모두). 예) 꼬들 = `ㄱㄱㅗㄷㅡㄹ`
  - 합성 모음: ㅐ→ㅏ+ㅣ, ㅘ→ㅗ+ㅏ, ㅙ→ㅗ+ㅏ+ㅣ, ㅢ→ㅡ+ㅣ …
  - 겹받침: ㄺ→ㄹ+ㄱ, ㅄ→ㅂ+ㅅ …
- 피드백: 초록(위치 맞음)·노랑(있지만 위치 틀림)·회색(없음), 표준 워들 중복 처리.

## 솔버 전략

- **정보이론(엔트로피) 그리디** (길이 무관 일반화): 각 추측이 만들 피드백 패턴 분포의 섀넌 엔트로피 최대화.
- 정렬 키: `엔트로피 ↓ → 정답가능 우선 → 최악버킷 ↓`.
- 초반엔 정답풀을 탐색 풀로 써 신선한 자모로 정보 수집, 후보가 좁혀지면 **정답 가능 단어만** 추천.
- 후보 필터링은 "패턴 일치 재시뮬레이션"(`pattern(추측, 후보) == 관측패턴`)으로 중복 처리 버그를 원천 차단.
- 시뮬: 카카오톡 최악 3턴 · 꼬들 최악 3턴 · 꼬오오오오들 최악 2턴 (표본 전부 시도 횟수 내 수렴).

## 구조

```
lib/hangul.dart   한글 자모 분해/펼치기 (24 기본자모, 쌍자음·복합모음·겹받침 전부 분해)
lib/solver.dart   피드백 패턴·후보 필터·엔트로피 랭킹·오프너 (임의 길이 일반화)
lib/main.dart     3탭 반응형 UI (그리드 입력, 추천, 키보드 히트맵, 초기화)
assets/kakao5_*   카카오톡 5자모 정답/추측풀
assets/kordle6_*  꼬들 6자모 정답/추측풀
assets/kordle12_* 꼬오오오오들 12자모 정답/추측풀
build_tools/      단어 사전 빌드 스크립트 (kakao=dart, kordle=python) + 원본 js
test/               분해·솔버·UI 테스트 (5턴 보장 시뮬 포함)
```

## 실행

```bash
flutter pub get
flutter run -d chrome          # 또는 -d edge / -d web-server
flutter test                   # 전체 테스트
flutter build web              # 배포 빌드 → build/web
```

빌드 후 정적 서버로 확인:
```bash
py -m http.server 8000 --directory build/web   # http://localhost:8000
```

## 단어 사전 다시 만들기

원본은 [han-dle/pd-korean-noun-list-for-wordles](https://github.com/han-dle/pd-korean-noun-list-for-wordles) (CC0).
`build_tools/raw/`의 `CommonNouns.js`(정답풀)·`AllNouns.js`(전체)를 받아:

```bash
dart run build_tools/build_wordlist.dart   # assets/answers.txt, guesses.txt 재생성
```

앱과 **동일한 `lib/hangul.dart` 분해 규칙**으로 필터링하므로 결과가 항상 일치한다.
