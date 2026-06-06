import 'package:flutter/foundation.dart';

/// 등수별 상금 구조. 프리셋으로 저장/불러올 수 있다.
@immutable
class PayoutStructure {
  const PayoutStructure({required this.name, required this.payouts});

  /// 프리셋 이름(예: "표준 MTT 9인", "STT 3인 50/30/20").
  final String name;

  /// 등수별 상금($). 1등이 index 0. 내림차순 권장이나 강제하지 않는다.
  final List<double> payouts;

  /// 상금풀 총합($).
  double get total => payouts.fold(0.0, (a, b) => a + b);

  /// 인머니(상금이 0보다 큰) 자리 수.
  int get paidPlaces => payouts.where((p) => p > 0).length;

  PayoutStructure copyWith({String? name, List<double>? payouts}) =>
      PayoutStructure(
        name: name ?? this.name,
        payouts: payouts ?? this.payouts,
      );

  Map<String, dynamic> toJson() => {'name': name, 'payouts': payouts};

  factory PayoutStructure.fromJson(Map<String, dynamic> json) =>
      PayoutStructure(
        name: (json['name'] as String?) ?? '',
        payouts: (json['payouts'] as List<dynamic>)
            .map((e) => (e as num).toDouble())
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      other is PayoutStructure &&
      other.name == name &&
      listEquals(other.payouts, payouts);

  @override
  int get hashCode => Object.hash(name, Object.hashAll(payouts));

  @override
  String toString() => 'PayoutStructure("$name", $payouts)';
}
