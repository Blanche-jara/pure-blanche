import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/decision_tools.dart';
import '../core/icm_calculator.dart';
import 'scenario_controller.dart';

/// 의사결정 도구 입력값(현재 시나리오에 종속되지 않는 사용자 선택).
@immutable
class DecisionInputs {
  const DecisionInputs({
    this.heroIndex = 0,
    this.oppIndex = 1,
    this.riskOverride = 0,
    this.winProbPercent = 50,
    this.deadChips = 0,
  });

  final int heroIndex;
  final int oppIndex;

  /// 0이면 자동(두 스택 중 작은 값 = 올인 유효 risk).
  final int riskOverride;

  /// 콜/푸시 승률(%) 0~100.
  final double winProbPercent;

  /// 폴드 시 이미 낸 데드 칩(블라인드/앤티). foldEV 계산 시 히어로 스택에서 차감.
  final int deadChips;

  DecisionInputs copyWith({
    int? heroIndex,
    int? oppIndex,
    int? riskOverride,
    double? winProbPercent,
    int? deadChips,
  }) => DecisionInputs(
    heroIndex: heroIndex ?? this.heroIndex,
    oppIndex: oppIndex ?? this.oppIndex,
    riskOverride: riskOverride ?? this.riskOverride,
    winProbPercent: winProbPercent ?? this.winProbPercent,
    deadChips: deadChips ?? this.deadChips,
  );
}

class DecisionInputsController extends Notifier<DecisionInputs> {
  @override
  DecisionInputs build() => const DecisionInputs();

  void setHero(int i) => state = state.copyWith(heroIndex: i);
  void setOpp(int i) => state = state.copyWith(oppIndex: i);
  void setRisk(int chips) =>
      state = state.copyWith(riskOverride: math.max(0, chips));
  void setWinProb(double pct) =>
      state = state.copyWith(winProbPercent: pct.clamp(0, 100));
  void setDeadChips(int chips) =>
      state = state.copyWith(deadChips: math.max(0, chips));
}

final decisionInputsProvider =
    NotifierProvider<DecisionInputsController, DecisionInputs>(
      DecisionInputsController.new,
    );

/// 의사결정 계산 결과(현재 시나리오 + 입력 기준). 입력 부족/무효 시 null.
@immutable
class DecisionResult {
  const DecisionResult({
    required this.hero,
    required this.opp,
    required this.risk,
    required this.conf,
    required this.bubbleFactor,
    required this.requiredEquity,
    required this.pushFold,
    required this.winProb,
  });

  final int hero;
  final int opp;
  final int risk;
  final ConfrontationIcm conf;
  final double? bubbleFactor;
  final double? requiredEquity;
  final PushFoldResult pushFold;
  final double winProb;
}

final decisionResultProvider = Provider<DecisionResult?>((ref) {
  final s = ref.watch(scenarioControllerProvider);
  final inp = ref.watch(decisionInputsProvider);
  final n = s.players.length;
  if (n < 2 || s.totalChips <= 0 || s.payout.total <= 0) return null;

  final hero = inp.heroIndex.clamp(0, n - 1);
  var opp = inp.oppIndex.clamp(0, n - 1);
  if (opp == hero) opp = (hero + 1) % n;

  final stacks = s.players.map((p) => p.stack).toList();
  final payouts = s.payout.payouts;
  final maxRisk = math.min(stacks[hero], stacks[opp]);
  final risk = inp.riskOverride > 0
      ? math.min(inp.riskOverride, maxRisk)
      : maxRisk;

  final conf = DecisionTools.confrontation(
    stacks,
    payouts,
    hero: hero,
    opp: opp,
    risk: risk,
  );

  double foldEv = conf.icmFold;
  if (inp.deadChips > 0) {
    final fs = [...stacks];
    fs[hero] = math.max(0, fs[hero] - inp.deadChips);
    foldEv = IcmCalculator.equities(fs, payouts)[hero];
  }

  final pf = DecisionTools.pushFold(
    foldEv: foldEv,
    winProb: inp.winProbPercent / 100.0,
    icmWin: conf.icmWin,
    icmLose: conf.icmLose,
  );

  return DecisionResult(
    hero: hero,
    opp: opp,
    risk: risk,
    conf: conf,
    bubbleFactor: DecisionTools.bubbleFactor(conf),
    requiredEquity: DecisionTools.requiredEquity(conf),
    pushFold: pf,
    winProb: inp.winProbPercent,
  );
});
