import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/deal_calculator.dart';
import 'scenario_controller.dart';

/// Save-for-winner 적립금 S(달러). 사용자가 슬라이더/입력으로 조절.
class SaveAmountController extends Notifier<double> {
  @override
  double build() => 0;

  void set(double value) => state = math.max(0, value);
}

final saveAmountProvider = NotifierProvider<SaveAmountController, double>(
  SaveAmountController.new,
);

/// 세 가지 딜 방식의 비교 결과(현재 시나리오 + 적립금 기준).
@immutable
class DealComparison {
  const DealComparison({
    required this.labels,
    required this.stacks,
    required this.icm,
    required this.chipChop,
    required this.save,
    required this.saveMax,
    required this.pool,
  });

  final List<String> labels;
  final List<int> stacks;
  final List<double> icm;
  final List<double> chipChop;
  final SaveForWinnerDeal save;
  final double saveMax;
  final double pool;
}

final dealComparisonProvider = Provider<DealComparison>((ref) {
  final s = ref.watch(scenarioControllerProvider);
  final saveAmount = ref.watch(saveAmountProvider);
  final stacks = s.players.map((p) => p.stack).toList();
  final payouts = s.payout.payouts;
  // payouts가 바뀌어 saveMax가 줄어든 경우에도 항상 안전 범위로 클램프해 계산.
  final saveMax = DealCalculator.safeSaveMax(payouts);
  final clampedSave = saveAmount.clamp(0.0, saveMax);

  return DealComparison(
    labels: [
      for (var i = 0; i < s.players.length; i++)
        s.players[i].name.trim().isEmpty
            ? 'P${i + 1}'
            : s.players[i].name.trim(),
    ],
    stacks: stacks,
    icm: DealCalculator.icm(stacks, payouts),
    chipChop: DealCalculator.chipChop(stacks, payouts),
    save: DealCalculator.saveForWinner(stacks, payouts, clampedSave),
    saveMax: saveMax,
    pool: s.payout.total,
  );
});
