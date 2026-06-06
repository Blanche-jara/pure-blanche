import 'dart:math' as math;

import 'icm_calculator.dart';

/// 히어로가 한 상대와 [risk] 칩을 주고받는 대결의 ICM 3상태.
class ConfrontationIcm {
  const ConfrontationIcm({
    required this.icmFold,
    required this.icmWin,
    required this.icmLose,
    required this.risk,
  });

  /// 대결을 피했을 때(현재 스택) 히어로 ICM($).
  final double icmFold;

  /// 승리 후(히어로 +risk, 상대 −risk) 히어로 ICM($).
  final double icmWin;

  /// 패배 후(히어로 −risk, 상대 +risk) 히어로 ICM($).
  final double icmLose;

  final double risk;

  /// 이겼을 때 얻는 ICM($).
  double get dollarsGained => icmWin - icmFold;

  /// 졌을 때 잃는 ICM($).
  double get dollarsLost => icmFold - icmLose;
}

/// 푸시/폴드 비교 결과.
class PushFoldResult {
  const PushFoldResult({
    required this.foldEv,
    required this.callEv,
    required this.shouldCall,
  });

  final double foldEv;
  final double callEv;
  final bool shouldCall;

  /// 권장 액션으로 얻는 ICM($). 양수면 콜/푸시 이득.
  double get edge => callEv - foldEv;
}

/// ICM 기반 의사결정 도구. 공식·골든값은 docs/VERIFIED_FORMULAS.md 참조.
class DecisionTools {
  const DecisionTools._();

  static const double _eps = 1e-9;

  /// 올인 대결의 유효 risk(두 스택 중 작은 값).
  static int effectiveRisk(int heroStack, int oppStack) =>
      math.min(heroStack, oppStack);

  /// 히어로[hero]가 상대[opp]와 [risk] 칩을 걸고 붙는 대결의 ICM 3상태를 계산한다.
  static ConfrontationIcm confrontation(
    List<int> stacks,
    List<num> payouts, {
    required int hero,
    required int opp,
    required int risk,
  }) {
    final fold = IcmCalculator.equities(stacks, payouts)[hero];

    final winStacks = [...stacks];
    winStacks[hero] += risk;
    winStacks[opp] = math.max(0, winStacks[opp] - risk);
    final win = IcmCalculator.equities(winStacks, payouts)[hero];

    final loseStacks = [...stacks];
    loseStacks[hero] = math.max(0, loseStacks[hero] - risk);
    loseStacks[opp] += risk;
    final lose = IcmCalculator.equities(loseStacks, payouts)[hero];

    return ConfrontationIcm(
      icmFold: fold,
      icmWin: win,
      icmLose: lose,
      risk: risk.toDouble(),
    );
  }

  /// 버블 팩터 = (잃는 ICM) / (얻는 ICM). 1.0=칩 EV 중립, >1.0=ICM 압박.
  ///
  /// 얻는 ICM이 0이면(거래 가치 없음) null 반환(N/A).
  static double? bubbleFactor(ConfrontationIcm c) {
    if (c.dollarsGained.abs() < _eps) return null;
    return c.dollarsLost / c.dollarsGained;
  }

  /// 올인 콜에 필요한 브레이크이븐 승률 p*.
  ///
  /// `p* = (ICM_fold − ICM_lose) / (ICM_win − ICM_lose)`. 분모 0이면 null.
  static double? requiredEquity(ConfrontationIcm c) {
    final denom = c.icmWin - c.icmLose;
    if (denom.abs() < _eps) return null;
    return (c.icmFold - c.icmLose) / denom;
  }

  /// 푸시/폴드 ICM EV 비교.
  ///
  /// [foldEv]는 (블라인드/앤티 차감 후) 폴드 시 ICM, [winProb]는 콜/푸시 승률(0~1).
  static PushFoldResult pushFold({
    required double foldEv,
    required double winProb,
    required double icmWin,
    required double icmLose,
  }) {
    final p = winProb.clamp(0.0, 1.0);
    final callEv = p * icmWin + (1 - p) * icmLose;
    return PushFoldResult(
      foldEv: foldEv,
      callEv: callEv,
      shouldCall: callEv > foldEv,
    );
  }
}
