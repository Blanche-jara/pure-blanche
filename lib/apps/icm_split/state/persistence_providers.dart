import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/scenario_repository.dart';
import '../models/payout_structure.dart';
import '../models/scenario.dart';

/// 저장소 인스턴스. main()에서 초기화된 인스턴스로 override 한다.
final scenarioRepositoryProvider = Provider<ScenarioRepository>(
  (ref) => throw UnimplementedError('main()에서 override 필요'),
);

/// 저장된 시나리오 목록(최근 수정순). 저장/삭제 시 갱신.
class SavedScenariosController extends Notifier<List<Scenario>> {
  ScenarioRepository get _repo => ref.read(scenarioRepositoryProvider);

  @override
  List<Scenario> build() => _repo.allScenarios();

  Future<void> save(Scenario s) async {
    await _repo.saveScenario(s);
    state = _repo.allScenarios();
  }

  Future<void> remove(String id) async {
    await _repo.deleteScenario(id);
    state = _repo.allScenarios();
  }
}

final savedScenariosProvider =
    NotifierProvider<SavedScenariosController, List<Scenario>>(
      SavedScenariosController.new,
    );

/// 저장된 페이아웃 프리셋 목록.
class SavedPresetsController extends Notifier<List<PayoutStructure>> {
  ScenarioRepository get _repo => ref.read(scenarioRepositoryProvider);

  @override
  List<PayoutStructure> build() => _repo.allPresets();

  Future<void> save(PayoutStructure p) async {
    await _repo.savePreset(p);
    state = _repo.allPresets();
  }

  Future<void> remove(String name) async {
    await _repo.deletePreset(name);
    state = _repo.allPresets();
  }
}

final savedPresetsProvider =
    NotifierProvider<SavedPresetsController, List<PayoutStructure>>(
      SavedPresetsController.new,
    );
