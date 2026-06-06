import 'dart:math' as math;

/// 상금 자동 분배용 비율 프리셋과 분배 유틸.
///
/// "총 상금풀 + 인머니 인원수 → 프리셋 비율로 자동 분배" 기능을 지원한다(Handoff 8장 결정).
/// 비율은 항상 내부적으로 정규화되므로 합이 정확히 1.0이 아니어도 된다.
class RatioPreset {
  const RatioPreset(this.name, this.ratios);

  /// 표시 이름(예: "표준 50/30/20").
  final String name;

  /// 등수별 비율(내림차순). 1등이 index 0. 합은 정규화됨.
  final List<double> ratios;

  int get places => ratios.length;

  /// [pool]을 비율대로 분배해 등수별 상금($)을 반환한다.
  ///
  /// 정수 달러로 분배하되 **최대잔여(Hamilton) 방식**으로 합계가 [pool]과 정확히 일치하게 한다.
  /// 각 자리를 내림한 뒤 남은 달러를 소수부가 큰 자리부터 1달러씩 배분(동률 시 상위 등수 우선).
  /// 잔차를 1등에 몰지 않으므로 1등이 2등보다 작아지는 역전이 생기지 않는다.
  List<double> distribute(double pool, {bool roundToWhole = true}) {
    if (ratios.isEmpty || pool <= 0) {
      return List<double>.filled(ratios.length, 0.0);
    }
    final double sum = ratios.fold(0.0, (a, b) => a + b);
    final List<double> raw = ratios
        .map((r) => pool * (r / sum))
        .toList(growable: false);
    if (!roundToWhole) return raw;

    final List<double> floors = raw
        .map((v) => v.floorToDouble())
        .toList(growable: false);
    final double allocated = floors.fold(0.0, (a, b) => a + b);
    int leftover = (pool - allocated).round();

    // 소수부 내림차순 인덱스(동률이면 상위 등수=낮은 인덱스 우선).
    final idx = List<int>.generate(raw.length, (i) => i)
      ..sort((a, b) {
        final fa = raw[a] - floors[a];
        final fb = raw[b] - floors[b];
        final c = fb.compareTo(fa);
        return c != 0 ? c : a.compareTo(b);
      });

    final result = [...floors];
    for (var k = 0; k < idx.length && leftover > 0; k++, leftover--) {
      result[idx[k]] += 1;
    }
    return result;
  }
}

class PayoutPresets {
  const PayoutPresets._();

  /// 인머니 자리 수별 표준 비율 프리셋(흔한 SNG/MTT 구조 근사).
  static const Map<int, RatioPreset> byPlaces = {
    1: RatioPreset('위너 독식', [1.0]),
    2: RatioPreset('65/35', [0.65, 0.35]),
    3: RatioPreset('50/30/20', [0.50, 0.30, 0.20]),
    4: RatioPreset('40/30/20/10', [0.40, 0.30, 0.20, 0.10]),
    5: RatioPreset('38/27/18/10/7', [0.38, 0.27, 0.18, 0.10, 0.07]),
    6: RatioPreset('34/24/17/12/8/5', [0.34, 0.24, 0.17, 0.12, 0.08, 0.05]),
    7: RatioPreset('32/22/15.5/11/8.5/6.5/4.5', [
      0.32,
      0.22,
      0.155,
      0.11,
      0.085,
      0.065,
      0.045,
    ]),
    8: RatioPreset('30/20.5/14.5/10.5/8/6/5.5/5', [
      0.30,
      0.205,
      0.145,
      0.105,
      0.08,
      0.06,
      0.055,
      0.05,
    ]),
    9: RatioPreset('표준 MTT 9인', [
      0.30,
      0.195,
      0.135,
      0.095,
      0.075,
      0.06,
      0.05,
      0.045,
      0.045,
    ]),
  };

  /// 자리 수 [places]에 맞는 기본 비율 프리셋을 반환한다.
  ///
  /// 표에 없는 큰 값은 기하 감쇠(r=0.7)로 생성해 정규화한다.
  static RatioPreset forPlaces(int places) {
    if (places <= 0) return const RatioPreset('없음', []);
    final preset = byPlaces[places];
    if (preset != null) return preset;
    const double r = 0.7;
    final List<double> ratios = List<double>.generate(
      places,
      (i) => math.pow(r, i).toDouble(),
    );
    return RatioPreset('자동 $places인', ratios);
  }

  /// 총 상금풀 [pool]을 인머니 [places]명에게 자동 분배한다.
  static List<double> autoDistribute(double pool, int places) =>
      forPlaces(places).distribute(pool);
}
