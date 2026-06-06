import 'dart:math';

import 'evaluator.dart';

/// 에쿼티 계산 결과(승/타이/패 횟수 + 에쿼티).
class EquityResult {
  const EquityResult({
    required this.trials,
    required this.heroWins,
    required this.ties,
    required this.villainWins,
  });

  final int trials;
  final int heroWins;
  final int ties;
  final int villainWins;

  /// 히어로 에쿼티(0~1). 타이는 절반씩 분배.
  double get heroEquity => trials == 0 ? 0 : (heroWins + ties / 2) / trials;
  double get villainEquity =>
      trials == 0 ? 0 : (villainWins + ties / 2) / trials;
  double get tieRate => trials == 0 ? 0 : ties / trials;

  static const EquityResult empty = EquityResult(
    trials: 0,
    heroWins: 0,
    ties: 0,
    villainWins: 0,
  );
}

/// `compute`(Isolate)로 넘기기 위한 직렬화 가능 입력.
class EquitySpec {
  const EquitySpec({
    required this.hero,
    required this.villain,
    this.board = const [],
    this.iterations = 40000,
    this.seed = 1,
  });

  /// 히어로 홀 카드 2장(0..51).
  final List<int> hero;

  /// 빌런 홀 카드 2장.
  final List<int> villain;

  /// 알려진 보드 카드(0~5장).
  final List<int> board;

  /// 몬테카를로 시뮬 횟수(보드가 미완성일 때만 사용).
  final int iterations;

  /// 재현용 시드.
  final int seed;
}

/// 최상위 함수 — `compute(computeEquity, spec)` 진입점.
EquityResult computeEquity(EquitySpec spec) => EquityCalculator.run(spec);

/// 텍사스 홀덤 헤즈업 에쿼티 계산기(몬테카를로 + 완성 보드 즉시 판정).
class EquityCalculator {
  const EquityCalculator._();

  static EquityResult run(EquitySpec s) {
    if (s.hero.length != 2 || s.villain.length != 2 || s.board.length > 5) {
      return EquityResult.empty;
    }
    final used = <int>{...s.hero, ...s.villain, ...s.board};
    if (used.length != s.hero.length + s.villain.length + s.board.length) {
      return EquityResult.empty; // 카드 중복.
    }

    final deck = <int>[
      for (var c = 0; c < 52; c++)
        if (!used.contains(c)) c,
    ];
    final boardNeeded = 5 - s.board.length;
    final rng = Random(s.seed);

    final board5 = List<int>.filled(5, 0);
    for (var i = 0; i < s.board.length; i++) {
      board5[i] = s.board[i];
    }
    final hero7 = List<int>.filled(7, 0);
    final vil7 = List<int>.filled(7, 0);
    hero7[0] = s.hero[0];
    hero7[1] = s.hero[1];
    vil7[0] = s.villain[0];
    vil7[1] = s.villain[1];

    final trials = boardNeeded == 0 ? 1 : s.iterations;
    var hw = 0, ti = 0, vw = 0;

    for (var it = 0; it < trials; it++) {
      // 부분 Fisher–Yates로 남은 보드 카드 추출.
      for (var i = 0; i < boardNeeded; i++) {
        final j = i + rng.nextInt(deck.length - i);
        final tmp = deck[i];
        deck[i] = deck[j];
        deck[j] = tmp;
        board5[s.board.length + i] = deck[i];
      }
      for (var k = 0; k < 5; k++) {
        hero7[2 + k] = board5[k];
        vil7[2 + k] = board5[k];
      }
      final hs = HandEvaluator.eval7(hero7);
      final vs = HandEvaluator.eval7(vil7);
      if (hs > vs) {
        hw++;
      } else if (hs < vs) {
        vw++;
      } else {
        ti++;
      }
    }
    return EquityResult(
      trials: trials,
      heroWins: hw,
      ties: ti,
      villainWins: vw,
    );
  }
}
