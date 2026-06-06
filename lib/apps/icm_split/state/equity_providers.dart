import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../poker/equity.dart';

/// 카드 슬롯 종류.
enum CardSlot { hero, villain, board }

/// 에쿼티 화면의 카드 선택 상태.
@immutable
class EquitySelection {
  const EquitySelection({
    required this.hero,
    required this.villain,
    required this.board,
  });

  /// 히어로 홀 카드 2슬롯(미선택은 null).
  final List<int?> hero;

  /// 빌런 홀 카드 2슬롯.
  final List<int?> villain;

  /// 보드 5슬롯.
  final List<int?> board;

  factory EquitySelection.empty() => const EquitySelection(
    hero: [null, null],
    villain: [null, null],
    board: [null, null, null, null, null],
  );

  Set<int> get used => [...hero, ...villain, ...board].whereType<int>().toSet();

  bool get heroComplete => hero.every((c) => c != null);
  bool get villainComplete => villain.every((c) => c != null);
  bool get ready => heroComplete && villainComplete;

  List<int> get heroCards => hero.whereType<int>().toList();
  List<int> get villainCards => villain.whereType<int>().toList();
  List<int> get boardCards => board.whereType<int>().toList();

  EquitySelection copyWith({
    List<int?>? hero,
    List<int?>? villain,
    List<int?>? board,
  }) => EquitySelection(
    hero: hero ?? this.hero,
    villain: villain ?? this.villain,
    board: board ?? this.board,
  );
}

@immutable
class EquityViewState {
  const EquityViewState({
    required this.selection,
    this.result,
    this.computing = false,
  });

  final EquitySelection selection;
  final EquityResult? result;
  final bool computing;

  EquityViewState copyWith({
    EquitySelection? selection,
    EquityResult? result,
    bool? computing,
    bool clearResult = false,
  }) => EquityViewState(
    selection: selection ?? this.selection,
    result: clearResult ? null : (result ?? this.result),
    computing: computing ?? this.computing,
  );
}

class EquityController extends Notifier<EquityViewState> {
  @override
  EquityViewState build() =>
      EquityViewState(selection: EquitySelection.empty());

  void setCard(CardSlot slot, int index, int? card) {
    final sel = state.selection;
    List<int?> list;
    switch (slot) {
      case CardSlot.hero:
        list = [...sel.hero];
      case CardSlot.villain:
        list = [...sel.villain];
      case CardSlot.board:
        list = [...sel.board];
    }
    if (index < 0 || index >= list.length) return;
    list[index] = card;
    final next = switch (slot) {
      CardSlot.hero => sel.copyWith(hero: list),
      CardSlot.villain => sel.copyWith(villain: list),
      CardSlot.board => sel.copyWith(board: list),
    };
    // 선택이 바뀌면 결과를 비우고, 진행 중 계산이 있어도 UI를 잠그지 않는다(레이스 방지).
    state = state.copyWith(
      selection: next,
      clearResult: true,
      computing: false,
    );
  }

  void clearAll() =>
      state = EquityViewState(selection: EquitySelection.empty());

  /// 몬테카를로 에쿼티 계산을 Isolate(`compute`)로 오프로딩한다.
  Future<void> calculate({int iterations = 50000}) async {
    final sel = state.selection;
    if (!sel.ready) return;
    state = state.copyWith(computing: true);
    final spec = EquitySpec(
      hero: sel.heroCards,
      villain: sel.villainCards,
      board: sel.boardCards,
      iterations: iterations,
      seed: 1,
    );
    final result = await compute(computeEquity, spec);
    // 계산 도중 사용자가 카드를 바꿨으면(선택 객체가 교체됨) stale 결과를 폐기.
    if (!identical(state.selection, sel)) return;
    state = state.copyWith(result: result, computing: false);
  }
}

final equityControllerProvider =
    NotifierProvider<EquityController, EquityViewState>(EquityController.new);
