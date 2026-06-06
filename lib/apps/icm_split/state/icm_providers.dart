import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/icm_calculator.dart';
import 'scenario_controller.dart';

/// 플레이어 한 명의 ICM 결과 행.
@immutable
class IcmRow {
  const IcmRow({
    required this.playerId,
    required this.label,
    required this.stack,
    required this.equity,
    required this.percent,
  });

  final String playerId;

  /// 표시 라벨(이름이 있으면 이름, 없으면 "P1" 등).
  final String label;
  final int stack;

  /// ICM 기대값($).
  final double equity;

  /// 상금풀 대비 비율(%).
  final double percent;
}

/// 현재 시나리오의 플레이어별 ICM 결과. 입력 변경 시 자동 재계산.
final icmResultsProvider = Provider<List<IcmRow>>((ref) {
  final s = ref.watch(scenarioControllerProvider);
  final stacks = s.players.map((p) => p.stack).toList();
  final ev = IcmCalculator.equities(stacks, s.payout.payouts);
  final pool = s.payout.total;
  return [
    for (var i = 0; i < s.players.length; i++)
      IcmRow(
        playerId: s.players[i].id,
        label: s.players[i].name.trim().isEmpty
            ? 'P${i + 1}'
            : s.players[i].name.trim(),
        stack: s.players[i].stack,
        equity: ev[i],
        percent: pool > 0 ? ev[i] / pool * 100.0 : 0.0,
      ),
  ];
});

/// 칩 합계.
final totalChipsProvider = Provider<int>(
  (ref) => ref.watch(scenarioControllerProvider).totalChips,
);

/// 상금풀 합계($).
final prizePoolProvider = Provider<double>(
  (ref) => ref.watch(scenarioControllerProvider).payout.total,
);
