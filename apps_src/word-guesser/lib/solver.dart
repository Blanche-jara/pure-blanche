/// 한글 워들("오늘의 단어") 솔버 코어.
///
/// 정보이론(엔트로피) 기반 그리디 솔버. 표준 워들 피드백 규칙(중복 자모 포함)을
/// 단일 함수 [_pattern] 으로 정의하고, 후보 필터링은 "패턴 일치 재시뮬레이션"으로
/// 처리해 중복 처리 버그 가능성을 원천 차단한다.
///   후보 a 가 (추측 g, 관측 패턴 P) 와 일치 ⇔ pattern(g, a) == P
library;

import 'dart:math';
import 'dart:typed_data';

import 'hangul.dart';

/// 칸별 피드백 색. base-3 인코딩용 index: absent=0(회색), present=1(노랑), correct=2(초록).
enum Mark { absent, present, correct }

/// 게임에서 쓰는 24개 자모 (자음 14 + 모음 10). 인덱스 0~13 자음, 14~23 모음.
final List<String> kJamo = [...kBasicConsonants, ...kBasicVowels];

final Map<String, int> _jamoIndex = {
  for (var i = 0; i < kJamo.length; i++) kJamo[i]: i,
};

/// 추측 g 를 정답 a 에 대해 채점한 base-3 패턴. cell0 이 최상위 자리. 임의 길이 지원.
/// [counts] 는 길이 24 재사용 버퍼(핫 루프 GC 방지). 호출자가 제공한다.
///
/// 표준 워들 규칙: 1차로 초록(정위치)을 먼저 소진, 2차로 남은 개수만큼 노랑.
/// 정답보다 많이 친 중복 자모는 회색이 된다. (alloc 없이 greenMask 비트로 1·2차 분리)
int wordlePattern(Uint8List g, Uint8List a, Int32List counts) {
  final len = g.length;
  for (var i = 0; i < 24; i++) {
    counts[i] = 0;
  }
  for (var i = 0; i < len; i++) {
    counts[a[i]]++;
  }
  // pass1: 초록(정위치) 표시 + 카운트 소진
  var greenMask = 0;
  for (var i = 0; i < len; i++) {
    if (g[i] == a[i]) {
      greenMask |= 1 << i;
      counts[g[i]]--;
    }
  }
  // pass2: 코드 조립 (초록=2, 남은 카운트 있으면 노랑=1, 아니면 회색=0)
  var code = 0;
  for (var i = 0; i < len; i++) {
    var mark = 0;
    if ((greenMask >> i) & 1 == 1) {
      mark = 2;
    } else if (counts[g[i]] > 0) {
      mark = 1;
      counts[g[i]]--;
    }
    code = code * 3 + mark;
  }
  return code;
}

/// 3^n.
int _pow3(int n) {
  var p = 1;
  for (var i = 0; i < n; i++) {
    p *= 3;
  }
  return p;
}

/// 단어 한 개의 사전 인코딩.
class WordEntry {
  final String text; // 예: 사람
  final Uint8List jamo; // 길이 5, 각 칸 자모 인덱스(0~23)
  final bool allDistinct; // 5개 자모가 모두 다른가 (오프너 후보용)

  WordEntry(this.text, this.jamo, this.allDistinct);

  /// 완성형 단어 문자열을 인코딩. [length] 자모·기본자모가 아니면 null.
  static WordEntry? tryParse(String word, int length) {
    final w = word.trim();
    final jamoStr = decomposeWord(w);
    if (jamoStr.length != length) return null;
    final arr = Uint8List(length);
    for (var i = 0; i < length; i++) {
      final idx = _jamoIndex[jamoStr[i]];
      if (idx == null) return null; // 기본 자모가 아님
      arr[i] = idx;
    }
    final distinct = arr.toSet().length == length;
    return WordEntry(w, arr, distinct);
  }
}

/// 다음 추천 단어 한 건.
class Suggestion {
  final String word;
  final double entropy; // 기대 정보량(bit)
  final bool isCandidate; // 현재 정답 후보에 포함되는가(=정답일 수 있는가)
  final int worstBucket; // 최악의 경우 남는 후보 수(작을수록 좋음)

  Suggestion({
    required this.word,
    required this.entropy,
    required this.isCandidate,
    required this.worstBucket,
  });
}

/// 한 번의 추측 기록.
class GuessRecord {
  final String word;
  final Uint8List jamo;
  final List<Mark> marks; // 길이 5
  final int pattern; // base-3 인코딩

  GuessRecord(this.word, this.jamo, this.marks, this.pattern);
}

class Solver {
  /// 정답 길이(자모 수): 카카오톡 5, 꼬들 6, 꼬오오오오들 12.
  final int wordLen;

  /// 허용 시도 횟수: 카카오톡 5, 꼬들/꼬오오오오들 6.
  final int maxGuesses;

  /// 정답 후보 풀(상용어). 추천·엔트로피 계산의 기본 모집단.
  final List<WordEntry> answers;

  /// 유효 추측 풀(전체). 사용자가 직접 친 단어 검증용. answers 를 포함.
  final List<WordEntry> guesses;

  /// 단어 문자열 -> WordEntry (guesses 기준 빠른 조회)
  final Map<String, WordEntry> _byText;

  /// 현재 남은 정답 후보.
  late List<WordEntry> candidates;

  /// 정답 후보 모집단이 상용어(answers)인가, 아니면 전체(guesses)로 확장됐는가.
  bool wideMode = false;

  final List<GuessRecord> history = [];

  /// 미리 계산해 둔 좋은 오프너 목록(자모 모두 다름 + 엔트로피 상위).
  late final List<Suggestion> topOpeners;

  final Random _rng;

  // 재사용 버퍼(핫 루프 GC 방지)
  final Int32List _counts = Int32List(24);
  late final Int32List _buckets;

  Solver({
    required this.wordLen,
    required this.maxGuesses,
    required this.answers,
    required this.guesses,
    Random? rng,
  })  : _byText = {for (final w in guesses) w.text: w},
        _rng = rng ?? Random() {
    _buckets = Int32List(_pow3(wordLen));
    candidates = List<WordEntry>.from(answers);
    topOpeners = _computeTopOpeners();
  }

  /// 문자열 리스트로부터 솔버 생성(에셋 로딩 후 사용).
  factory Solver.fromWords({
    required int wordLen,
    required int maxGuesses,
    required List<String> answerWords,
    required List<String> guessWords,
    Random? rng,
  }) {
    final ans = <WordEntry>[];
    for (final w in answerWords) {
      final e = WordEntry.tryParse(w, wordLen);
      if (e != null) ans.add(e);
    }
    final gset = <String, WordEntry>{};
    for (final w in guessWords) {
      final e = WordEntry.tryParse(w, wordLen);
      if (e != null) gset[e.text] = e;
    }
    // answers 가 guesses 에 반드시 포함되도록 보강
    for (final e in ans) {
      gset.putIfAbsent(e.text, () => e);
    }
    return Solver(
      wordLen: wordLen,
      maxGuesses: maxGuesses,
      answers: ans,
      guesses: gset.values.toList(),
      rng: rng,
    );
  }

  int get candidateCount => candidates.length;
  int get turnsUsed => history.length;
  int get guessesLeft => maxGuesses - history.length;

  /// 마지막 추측이 모두 초록(정답)인가.
  bool get isSolved =>
      history.isNotEmpty && history.last.marks.every((m) => m == Mark.correct);

  /// 단어가 유효 추측 풀에 있는가(사용자 직접 입력 검증).
  bool isValidGuess(String word) => _byText.containsKey(word.trim());

  WordEntry? entryOf(String word) => _byText[word.trim()];

  // ---- 피드백 패턴 (단일 진실 원천) ----

  int _pattern(Uint8List g, Uint8List a) => wordlePattern(g, a, _counts);

  /// marks 리스트를 base-3 패턴으로 인코딩.
  static int encodeMarks(List<Mark> marks) {
    var code = 0;
    for (final m in marks) {
      code = code * 3 + m.index;
    }
    return code;
  }

  /// 추측 결과를 적용: 기록 추가 후 후보를 필터링한다.
  /// [word] 는 실제로 추측한 단어, [marks] 는 칸별 색(길이 5).
  void applyResult(String word, List<Mark> marks) {
    final entry = WordEntry.tryParse(word, wordLen);
    if (entry == null) {
      throw ArgumentError('유효하지 않은 단어: $word');
    }
    final pattern = encodeMarks(marks);
    history.add(GuessRecord(entry.text, entry.jamo, List.of(marks), pattern));
    _refilter();
  }

  /// 전체 history 로부터 후보를 다시 계산. 후보가 비면 전체 풀로 확장.
  void _refilter() {
    candidates = _filterPool(wideMode ? guesses : answers);
    if (candidates.isEmpty && !wideMode) {
      wideMode = true;
      candidates = _filterPool(guesses);
    }
  }

  List<WordEntry> _filterPool(List<WordEntry> pool) {
    return pool.where((w) {
      for (final h in history) {
        if (_pattern(h.jamo, w.jamo) != h.pattern) return false;
      }
      return true;
    }).toList();
  }

  // ---- 추천 ----

  /// 현재 상태 기준 다음 추천 단어 top-N.
  List<Suggestion> suggest({int topN = 8}) {
    if (candidates.isEmpty) return [];
    if (history.isEmpty) {
      // 오프너: 미리 계산해 둔 목록 사용.
      return topOpeners.take(topN).toList();
    }
    if (candidates.length == 1) {
      final w = candidates.first;
      return [
        Suggestion(word: w.text, entropy: 0, isCandidate: true, worstBucket: 1)
      ];
    }

    // 추측 후보 풀(P) 결정.
    //  - 엔드게임(남은 후보 ≤ 남은 턴, 또는 남은 턴 ≤ 2): 반드시 "정답 가능" 단어만 → P = candidates
    //  - 그 외(탐색/좁히기): 신선한 자모 탐색을 위해 상용 전체(answers) + 후보 를 P 로
    final endgame = candidates.length <= guessesLeft || guessesLeft <= 2;
    final List<WordEntry> pool;
    if (endgame) {
      pool = candidates;
    } else {
      final seen = <String>{};
      pool = <WordEntry>[];
      for (final w in candidates) {
        if (seen.add(w.text)) pool.add(w);
      }
      for (final w in answers) {
        if (seen.add(w.text)) pool.add(w);
      }
    }

    final candidateSet = {for (final w in candidates) w.text};
    final scored = <Suggestion>[];
    for (final g in pool) {
      final s = _score(g, candidates, candidateSet.contains(g.text));
      scored.add(s);
    }
    scored.sort(_compareSuggestion);
    return scored.take(topN).toList();
  }

  /// 정렬 키: 엔트로피↓, (동률) 정답가능 우선, (동률) 최악버킷↓.
  int _compareSuggestion(Suggestion a, Suggestion b) {
    final e = b.entropy.compareTo(a.entropy);
    if (e != 0) return e;
    if (a.isCandidate != b.isCandidate) return a.isCandidate ? -1 : 1;
    return a.worstBucket.compareTo(b.worstBucket);
  }

  /// 추측 g 를 후보집합 S 에 대해 채점.
  Suggestion _score(WordEntry g, List<WordEntry> s, bool isCandidate) {
    final buckets = _buckets;
    // 사용한 버킷만 초기화하기 위해 touched 추적
    final touched = <int>[];
    for (final a in s) {
      final p = _pattern(g.jamo, a.jamo);
      if (buckets[p] == 0) touched.add(p);
      buckets[p]++;
    }
    final n = s.length;
    var entropy = 0.0;
    var worst = 0;
    for (final p in touched) {
      final c = buckets[p];
      if (c > worst) worst = c;
      final prob = c / n;
      entropy -= prob * (log(prob) / ln2);
      buckets[p] = 0; // 초기화
    }
    return Suggestion(
      word: g.text,
      entropy: entropy,
      isCandidate: isCandidate,
      worstBucket: worst,
    );
  }

  /// 오프너 후보 계산: 자모가 모두 다른 상용어 중 엔트로피 상위.
  List<Suggestion> _computeTopOpeners() {
    final distinct = answers.where((w) => w.allDistinct).toList();
    final pool = distinct.isNotEmpty ? distinct : answers;
    final scored = <Suggestion>[];
    final candidateSet = {for (final w in answers) w.text};
    for (final g in pool) {
      scored.add(_score(g, answers, candidateSet.contains(g.text)));
    }
    scored.sort(_compareSuggestion);
    return scored.take(30).toList();
  }

  /// 오프너를 무작위로 하나 고른다(상위권 내에서). 초기화마다 다른 추천을 주기 위함.
  Suggestion randomOpener({int fromTop = 12}) {
    final pool = topOpeners.take(min(fromTop, topOpeners.length)).toList();
    return pool[_rng.nextInt(pool.length)];
  }

  // ---- 키보드 히트맵 ----

  /// 각 자모의 현재까지 알려진 최고 상태(없으면 미포함=흰색).
  Map<String, Mark> keyboardMarks() {
    final result = <String, Mark>{};
    for (final h in history) {
      for (var i = 0; i < wordLen; i++) {
        final jamo = kJamo[h.jamo[i]];
        final m = h.marks[i];
        final prev = result[jamo];
        if (prev == null || m.index > prev.index) {
          result[jamo] = m;
        }
      }
    }
    return result;
  }

  /// 마지막 추측 입력을 취소하고 후보를 다시 계산.
  void undo() {
    if (history.isEmpty) return;
    history.removeLast();
    wideMode = false;
    _refilter();
  }

  /// 초기화: 모든 기록·후보를 리셋.
  void reset() {
    history.clear();
    wideMode = false;
    candidates = List<WordEntry>.from(answers);
  }
}
