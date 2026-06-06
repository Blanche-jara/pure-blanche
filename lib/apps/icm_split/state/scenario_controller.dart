import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/payout_presets.dart';
import '../models/payout_structure.dart';
import '../models/player.dart';
import '../models/scenario.dart';

const _uuid = Uuid();

/// 현재 편집 중인 시나리오의 작업 상태(불변).
@immutable
class ScenarioState {
  const ScenarioState({
    required this.id,
    required this.title,
    required this.players,
    required this.payout,
  });

  final String id;
  final String title;
  final List<Player> players;
  final PayoutStructure payout;

  int get totalChips => players.fold(0, (a, p) => a + p.stack);

  /// 칩 합계가 0보다 큰 유효한 입력인지.
  bool get hasChips => totalChips > 0;

  ScenarioState copyWith({
    String? id,
    String? title,
    List<Player>? players,
    PayoutStructure? payout,
  }) => ScenarioState(
    id: id ?? this.id,
    title: title ?? this.title,
    players: players ?? this.players,
    payout: payout ?? this.payout,
  );

  /// 영속화용 [Scenario]로 변환(updatedAt 주입).
  Scenario toScenario(DateTime updatedAt) => Scenario(
    id: id,
    title: title.isEmpty ? '제목 없음' : title,
    players: players,
    payout: payout,
    updatedAt: updatedAt,
  );

  factory ScenarioState.fromScenario(Scenario s) => ScenarioState(
    id: s.id,
    title: s.title,
    players: s.players,
    payout: s.payout,
  );
}

/// 작업 시나리오 컨트롤러. 입력 변경 시 즉시 상태 갱신 → 파생 프로바이더가 재계산.
class ScenarioController extends Notifier<ScenarioState> {
  @override
  ScenarioState build() => _defaultState();

  static ScenarioState _defaultState() => ScenarioState(
    id: _uuid.v4(),
    title: '',
    players: [
      Player(id: _uuid.v4(), stack: 5000),
      Player(id: _uuid.v4(), stack: 3000),
      Player(id: _uuid.v4(), stack: 2000),
    ],
    payout: const PayoutStructure(
      name: '50/30/20',
      payouts: [500000, 300000, 200000],
    ),
  );

  /// 새 계산 시작(초기 상태로 리셋, 새 id).
  void reset() => state = _defaultState();

  /// 저장된 시나리오 불러오기.
  void load(Scenario s) => state = ScenarioState.fromScenario(s);

  void setTitle(String title) => state = state.copyWith(title: title);

  // ---- 플레이어 ----

  /// 플레이어 수를 [count]명(2~10 권장)으로 맞춘다. 늘리면 0칩 추가, 줄이면 뒤에서 제거.
  void setPlayerCount(int count) {
    final target = count.clamp(1, 30);
    final current = [...state.players];
    if (target == current.length) return;
    if (target > current.length) {
      while (current.length < target) {
        current.add(Player(id: _uuid.v4(), stack: 0));
      }
    } else {
      current.removeRange(target, current.length);
    }
    state = state.copyWith(players: current);
  }

  void addPlayer({int stack = 0}) {
    state = state.copyWith(
      players: [
        ...state.players,
        Player(id: _uuid.v4(), stack: stack),
      ],
    );
  }

  void removePlayer(String id) {
    if (state.players.length <= 1) return;
    state = state.copyWith(
      players: state.players.where((p) => p.id != id).toList(),
    );
  }

  void updateStack(String id, int stack) {
    state = state.copyWith(
      players: state.players
          .map((p) => p.id == id ? p.copyWith(stack: math.max(0, stack)) : p)
          .toList(),
    );
  }

  void updateName(String id, String name) {
    state = state.copyWith(
      players: state.players
          .map((p) => p.id == id ? p.copyWith(name: name) : p)
          .toList(),
    );
  }

  // ---- 상금 구조 ----

  void setPayouts(List<double> payouts, {String? name}) {
    state = state.copyWith(
      payout: state.payout.copyWith(
        payouts: payouts,
        name: name ?? state.payout.name,
      ),
    );
  }

  void setPayoutName(String name) {
    state = state.copyWith(payout: state.payout.copyWith(name: name));
  }

  void updatePayoutAt(int index, double value) {
    final list = [...state.payout.payouts];
    if (index < 0 || index >= list.length) return;
    list[index] = math.max(0.0, value);
    state = state.copyWith(payout: state.payout.copyWith(payouts: list));
  }

  void setPayoutPlaces(int places) {
    final target = places.clamp(1, 30);
    final list = [...state.payout.payouts];
    if (target == list.length) return;
    if (target > list.length) {
      while (list.length < target) {
        list.add(0.0);
      }
    } else {
      list.removeRange(target, list.length);
    }
    state = state.copyWith(payout: state.payout.copyWith(payouts: list));
  }

  /// 총 상금풀 + 인머니 인원수 → 프리셋 비율로 자동 분배.
  void autoDistribute(double pool, int places) {
    final payouts = PayoutPresets.autoDistribute(pool, places);
    state = state.copyWith(
      payout: state.payout.copyWith(
        payouts: payouts,
        name: PayoutPresets.forPlaces(places).name,
      ),
    );
  }

  /// 프리셋(절대 금액 구조) 적용.
  void applyPreset(PayoutStructure preset) {
    state = state.copyWith(payout: preset);
  }
}

final scenarioControllerProvider =
    NotifierProvider<ScenarioController, ScenarioState>(ScenarioController.new);
