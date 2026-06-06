import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/payout_structure.dart';
import '../models/scenario.dart';

/// 로컬 영속화 저장소. Hive 박스에 모델을 JSON 문자열로 저장한다(결정 D2 — TypeAdapter 미사용).
///
/// 시나리오는 `id`를 키로, 프리셋은 이름을 키로 사용한다.
class ScenarioRepository {
  ScenarioRepository._(this._scenarios, this._presets);

  static const String scenarioBoxName = 'scenarios';
  static const String presetBoxName = 'payout_presets';

  final Box<String> _scenarios;
  final Box<String> _presets;

  /// 앱 실행 시 1회 초기화. 테스트에서는 [path]를 주어 임시 디렉터리를 사용한다.
  static Future<ScenarioRepository> open({String? path}) async {
    if (path != null) {
      Hive.init(path);
    } else {
      await Hive.initFlutter();
    }
    final scenarios = await Hive.openBox<String>(scenarioBoxName);
    final presets = await Hive.openBox<String>(presetBoxName);
    return ScenarioRepository._(scenarios, presets);
  }

  // ---- 시나리오 ----

  Future<void> saveScenario(Scenario s) =>
      _scenarios.put(s.id, jsonEncode(s.toJson()));

  Future<void> deleteScenario(String id) => _scenarios.delete(id);

  /// 최근 수정순(내림차순) 시나리오 목록.
  List<Scenario> allScenarios() {
    final list = _scenarios.values
        .map((j) => Scenario.fromJson(jsonDecode(j) as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  // ---- 페이아웃 프리셋 ----

  Future<void> savePreset(PayoutStructure p) =>
      _presets.put(p.name, jsonEncode(p.toJson()));

  Future<void> deletePreset(String name) => _presets.delete(name);

  List<PayoutStructure> allPresets() {
    final list = _presets.values
        .map(
          (j) =>
              PayoutStructure.fromJson(jsonDecode(j) as Map<String, dynamic>),
        )
        .toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  /// 테스트 정리용.
  Future<void> clear() async {
    await _scenarios.clear();
    await _presets.clear();
  }
}
