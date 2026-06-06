import 'dart:math' as math;

import 'icm_calculator.dart';

/// 딜(deal) 분배 계산기. 공식·골든값은 docs/VERIFIED_FORMULAS.md 참조.
///
/// 세 가지 방식을 제공한다:
/// - ICM 딜: 지급액 = ICM 기대값.
/// - Chip-chop: 최저 상금 보장 + 나머지를 칩 비율로 분배.
/// - Save-for-winner: 위너 몫 S를 떼고 나머지를 ICM으로 즉시 분배.
class DealCalculator {
  const DealCalculator._();

  /// payouts를 플레이어 수 [n]에 맞춰 정규화한다(길면 상위 n개, 짧으면 0 패딩).
  static List<double> _effectivePayouts(List<num> payouts, int n) {
    final p = payouts.map((e) => e.toDouble()).toList();
    if (p.length > n) return p.sublist(0, n);
    if (p.length < n) {
      return [...p, ...List<double>.filled(n - p.length, 0.0)];
    }
    return p;
  }

  /// (1) ICM 딜 — 각 플레이어 지급액 = ICM 기대값.
  static List<double> icm(List<num> stacks, List<num> payouts) =>
      IcmCalculator.equities(stacks, payouts);

  /// (2) Chip-chop 딜.
  ///
  /// `chipChop[i] = minPayout + (totalPool − n·minPayout) · (stack[i] / T)`.
  /// `remainingPot < 0`이면 0으로 클램프 후 순수 칩 비례 분배. T==0이면 균등 분배.
  static List<double> chipChop(List<num> stacks, List<num> payouts) {
    final int n = stacks.length;
    if (n == 0) return const [];
    final s = stacks.map((e) => math.max(0.0, e.toDouble())).toList();
    final p = _effectivePayouts(payouts, n);
    final double total = p.fold(0.0, (a, b) => a + b);
    final double t = s.fold(0.0, (a, b) => a + b);

    if (t <= 0) return List<double>.filled(n, total / n);

    final double minPayout = p.reduce(math.min);
    double remainingPot = total - n * minPayout;
    if (remainingPot < 0) {
      // 비정상 구조: 순수 칩 비례 분배.
      return [for (final st in s) total * (st / t)];
    }
    return [for (final st in s) minPayout + remainingPot * (st / t)];
  }

  /// (3) Save-for-winner 딜. 위너 적립금 [save]만큼 1등 상금을 줄여 ICM 분배.
  static SaveForWinnerDeal saveForWinner(
    List<num> stacks,
    List<num> payouts,
    double save,
  ) {
    final int n = stacks.length;
    final p = _effectivePayouts(payouts, n);
    final double s = math.max(0.0, save);
    final reduced = [...p];
    if (reduced.isNotEmpty) {
      reduced[0] = math.max(0.0, reduced[0] - s);
    }
    final now = IcmCalculator.equities(stacks, reduced);

    final double t = stacks.fold(
      0.0,
      (a, b) => a + math.max(0.0, b.toDouble()),
    );
    final expectedTotal = <double>[];
    final ifWin = <double>[];
    for (var i = 0; i < n; i++) {
      final frac = t > 0 ? math.max(0.0, stacks[i].toDouble()) / t : 0.0;
      expectedTotal.add(now[i] + s * frac);
      ifWin.add(now[i] + s);
    }
    return SaveForWinnerDeal(
      save: s,
      now: now,
      ifWin: ifWin,
      expectedTotal: expectedTotal,
    );
  }

  /// Save-for-winner 안전 입력 범위 상한: `payouts[0] − payouts[1]`(없으면 payouts[0]).
  ///
  /// 이 범위 안에서는 줄인 1등 상금이 2등 이상으로 유지된다.
  static double safeSaveMax(List<num> payouts) {
    if (payouts.isEmpty) return 0;
    final p0 = payouts[0].toDouble();
    if (payouts.length < 2) return math.max(0.0, p0);
    return math.max(0.0, p0 - payouts[1].toDouble());
  }
}

/// Save-for-winner 결과. [now]는 즉시 분배 확정액, [ifWin]은 위너일 때 총액,
/// [expectedTotal]은 기대총액(= 순수 ICM 딜과 동일, 분산만 이동).
class SaveForWinnerDeal {
  const SaveForWinnerDeal({
    required this.save,
    required this.now,
    required this.ifWin,
    required this.expectedTotal,
  });

  final double save;
  final List<double> now;
  final List<double> ifWin;
  final List<double> expectedTotal;
}
