import 'dart:math' as math;

/// 순수 ICM(Independent Chip Model) 계산 엔진.
///
/// UI·상태관리와 완전히 분리된 순수 함수 모음이다. 테스트 1순위 대상.
///
/// 핵심 가정: "다음 순위(아직 비어 있는 가장 높은 등수)로 끝날 확률 = 본인 칩 / 남은 전체 칩".
/// 1등을 확정한 뒤 그 사람을 제거하고 같은 방식으로 2등 확률을 재귀 계산한다.
///
/// 복잡도: 지불 등수 수를 k, 플레이어 수를 n이라 하면 대략 O(n!/(n-k)!).
/// 실전 페이아웃은 보통 k ≪ n(예: 9인 중 3인 인머니)이라 매우 빠르다.
/// k ≈ n(거의 모든 자리에 상금)인 무거운 경우만 Isolate(`compute`)로 오프로딩 권장.
class IcmCalculator {
  const IcmCalculator._();

  /// 부동소수 비교 허용 오차(테스트·합계 검증용 기본값).
  static const double epsilon = 1e-6;

  /// 각 플레이어의 ICM 기대값($)을 [stacks]와 동일한 인덱스 순서로 반환한다.
  ///
  /// - [stacks]: 각 플레이어의 칩 스택(0 이상). 0 이하인 스택은 탈락자로 보고 0 EV 처리.
  /// - [payouts]: 등수별 상금(내림차순 권장이나 강제하지 않음). 길이가 플레이어 수보다
  ///   많으면 초과분은 분배되지 않는다(자리 수보다 많은 등수는 도달 불가).
  ///
  /// 동점(타이) 스택은 확률이 동일하게 분배되어 자연스럽게 처리된다.
  static List<double> equities(List<num> stacks, List<num> payouts) {
    final int n = stacks.length;
    final List<double> ev = List<double>.filled(n, 0.0);
    if (n == 0 || payouts.isEmpty) return ev;

    final List<double> s = List<double>.generate(
      n,
      (i) => math.max(0.0, stacks[i].toDouble()),
    );
    final List<double> p = List<double>.generate(
      payouts.length,
      (i) => payouts[i].toDouble(),
    );

    final double totalStack = s.fold(0.0, (a, b) => a + b);
    if (totalStack <= 0) return ev; // 모든 스택이 0이면 분배 불가.

    final int maxDepth = math.min(n, p.length);
    final List<bool> taken = List<bool>.filled(n, false);

    void recurse(int depth, double prob, double remainingStack) {
      if (depth >= maxDepth || remainingStack <= 0) return;
      for (int i = 0; i < n; i++) {
        if (taken[i]) continue;
        final double stack = s[i];
        if (stack <= 0) continue; // 스택 0 플레이어는 유효 자리에 들어갈 확률 0.
        final double finishProb = prob * (stack / remainingStack);
        ev[i] += finishProb * p[depth];
        taken[i] = true;
        recurse(depth + 1, finishProb, remainingStack - stack);
        taken[i] = false;
      }
    }

    recurse(0, 1.0, totalStack);
    return ev;
  }

  /// 실제로 분배되는 상금풀($).
  ///
  /// 엔진은 스택이 양수인 플레이어에게만 유효 자리를 배정하므로, 분배 가능한 상금은
  /// 상위 `min(라이브 인원, payouts 길이)`개 등수의 합이다(좌석 수가 아님).
  static double distributablePool(List<num> stacks, List<num> payouts) {
    final int live = stacks.where((s) => s.toDouble() > 0).length;
    final int payable = math.min(live, payouts.length);
    double pool = 0.0;
    for (int i = 0; i < payable; i++) {
      pool += payouts[i].toDouble();
    }
    return pool;
  }

  /// 각 플레이어가 (분배 가능한) 상금풀에서 차지하는 비율(%)을 반환한다(0~100).
  ///
  /// 분배 가능 상금풀이 0이면 모든 값이 0. payouts가 플레이어보다 많아도 합이 100%가 되도록
  /// 분배 가능한 풀로 나눈다.
  static List<double> equityPercents(List<num> stacks, List<num> payouts) {
    final List<double> ev = equities(stacks, payouts);
    final double pool = distributablePool(stacks, payouts);
    if (pool <= 0) return List<double>.filled(ev.length, 0.0);
    return ev.map((e) => e / pool * 100.0).toList();
  }

  /// 단일 플레이어 집합에 대한 ICM 합계가 분배 가능한 상금풀과 일치하는지 검증한다.
  ///
  /// 부동소수 오차를 [tolerance] 범위에서 허용한다. 입력 검증·테스트용.
  static bool sumMatchesPool(
    List<num> stacks,
    List<num> payouts, {
    double tolerance = 1e-4,
  }) {
    final List<double> ev = equities(stacks, payouts);
    final double evSum = ev.fold(0.0, (a, b) => a + b);
    return (evSum - distributablePool(stacks, payouts)).abs() <= tolerance;
  }
}

/// `compute`(Isolate)로 ICM 계산을 오프로딩하기 위한 직렬화 가능 입력.
///
/// 9~10인 등 무거운 페이아웃 구조에서 UI 스레드 끊김을 막기 위해 사용한다.
class IcmInput {
  const IcmInput(this.stacks, this.payouts);

  final List<num> stacks;
  final List<num> payouts;
}

/// 최상위 함수(`compute`의 진입점 요건). [IcmCalculator.equities]를 위임 호출한다.
List<double> computeIcmEquities(IcmInput input) =>
    IcmCalculator.equities(input.stacks, input.payouts);
