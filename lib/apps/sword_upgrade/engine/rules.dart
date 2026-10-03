import 'dart:math';
import 'balance.dart';
import 'checkpoints.dart';
import 'models.dart';
import 'rare.dart';

enum OutcomeKind {
  success,
  protected,
  destroyed,
  rareFound,
  breakthrough,
  ending,
}

class Outcome {
  final OutcomeKind kind;
  final Sword before;
  final String message;
  const Outcome(this.kind, this.before, this.message);
}

class RuleException implements Exception {
  final String message;
  const RuleException(this.message);
  @override
  String toString() => message;
}

class GameRules {
  final GameState state;
  final double Function() roll;
  GameRules(this.state, {double Function()? roll})
    : roll = roll ?? Random().nextDouble;
  double get probability {
    final sword = state.sword;
    if (sword.level == sword.maximum) return 0;
    if (sword.isRare) return Balance.rareProbabilities[sword.level];
    return min(
      1,
      Balance.probabilities[sword.level] *
          min(2, 1 + .1 * state.failures[sword.level]),
    );
  }

  double get enhanceCost => state.sword.level == state.sword.maximum
      ? 0
      : state.sword.isRare
      ? state.sword.value * .03
      : Balance.enhanceCosts[state.sword.level];
  double get protectionCost => state.sword.isRare
      ? 0
      : Balance.protectionCost(state.sword.level, state.protection);
  double get totalCost => enhanceCost + protectionCost;
  double saleNet(Sword sword) =>
      (sword.value - sword.starterValue) * (1 - state.fee);
  String get startName => state.startRareId == null
      ? '일반 검 +${state.startLevel}'
      : '${rareWeapons.firstWhere((w) => w.id == state.startRareId).name} +0';
  Sword newStartSword() => state.startRareId == null
      ? Sword(
          level: state.startLevel,
          starterValue: Balance.salePrices[state.startLevel],
        )
      : Sword(
          rareId: state.startRareId,
          rareBase: Checkpoints.rareBase,
          starterValue: Checkpoints.rareBase,
        );
  Gate? get gate =>
      state.sword.isRare ? null : Balance.gates[state.sword.level];
  List<int> materialCandidates({bool includeLocked = false}) {
    final need = gate;
    if (need == null) return [];
    final indexes = <int>[];
    for (var i = 0; i < state.storage.length; i++) {
      final sword = state.storage[i];
      if (sword != null &&
          !sword.isRare &&
          sword.canStore &&
          (includeLocked || !sword.locked) &&
          sword.level >= need.minimumLevel &&
          sword.level < Balance.maxLevel) {
        indexes.add(i);
      }
    }
    indexes.sort(
      (a, b) => state.storage[a]!.level.compareTo(state.storage[b]!.level),
    );
    return indexes;
  }

  bool get canRelief =>
      state.gold < Balance.enhanceCosts[0] &&
      !(state.sword.canSell && !state.sword.locked) &&
      !state.storage.whereType<Sword>().any((s) => s.canSell && !s.locked);
  Outcome enhance({List<int>? materials}) {
    final before = state.sword;
    if (before.level == before.maximum) {
      throw const RuleException('최고 단계에 도달했습니다.');
    }
    final need = gate;
    final selected =
        materials ?? materialCandidates().take(need?.count ?? 0).toList();
    if (need != null &&
        (selected.length != need.count ||
            selected.toSet().length != need.count ||
            selected.any(
              (i) => !materialCandidates(includeLocked: true).contains(i),
            ))) {
      throw RuleException(
        '+${need.minimumLevel} 이상 일반 검 ${need.count}자루를 보관함에 준비하세요.',
      );
    }
    final cost = totalCost;
    if (state.gold < cost) {
      throw const RuleException('골드가 부족합니다. 검을 팔아 자금을 마련하세요.');
    }
    final success = roll() < probability;
    state.gold = max(0, state.gold - cost);
    state.spent += cost;
    state.attempts++;
    if (success) {
      state.sword = before.copyWith(level: before.level + 1);
      if (before.isRare) {
        state.discovered[before.rareId!] = max(
          state.discovered[before.rareId!] ?? 0,
          before.level + 1,
        );
      } else {
        state.failures[before.level] = 0;
        state.bestLevel = max(state.bestLevel, before.level + 1);
        for (final index in need == null ? <int>[] : selected) {
          state.storage[index] = null;
        }
        if (state.sword.level == Balance.maxLevel && state.ending == null) {
          state.ending = {
            'attempts': state.attempts,
            'destructions': state.destructions,
            'spent': state.spent,
            'playSeconds': state.playSeconds,
            'rareFinds': state.rareFinds,
          };
          return Outcome(
            OutcomeKind.ending,
            before,
            '종언의 검 완성. 당신의 대장간에 전설이 남았습니다.',
          );
        }
      }
      return Outcome(
        need == null ? OutcomeKind.success : OutcomeKind.breakthrough,
        before,
        '${need == null ? '강화 성공' : '돌파 성공'}! +${state.sword.level} ${state.sword.name}',
      );
    }
    if (before.isRare) {
      if (before.hearts > 1) {
        state.sword = before.copyWith(hearts: before.hearts - 1);
        return Outcome(OutcomeKind.protected, before, '강화 실패. 내구도가 1 감소했습니다.');
      }
    } else {
      state.failures[before.level]++;
      if (before.level > 0 &&
          state.protection > 0 &&
          roll() < Balance.protectionChances[state.protection]) {
        return Outcome(OutcomeKind.protected, before, '강화 실패. 보호가 검을 지켰습니다.');
      }
    }
    state.destructions++;
    if (!before.isRare && roll() < state.rareChance) {
      final rare =
          rareWeapons[min(
            rareWeapons.length - 1,
            (roll() * rareWeapons.length).floor(),
          )];
      state.sword = Sword(
        rareId: rare.id,
        rareBase: max(Balance.salePrices[10], before.value * 3),
      );
      state.rareFinds++;
      state.discovered.putIfAbsent(rare.id, () => 0);
      return Outcome(
        OutcomeKind.rareFound,
        before,
        '희귀 무기 발견! 잿더미 속에서 ${rare.name}가 나타났습니다.',
      );
    }
    state.sword = newStartSword();
    return Outcome(
      OutcomeKind.destroyed,
      before,
      '검이 파괴됐습니다. $startName 시작 검을 준비했습니다.',
    );
  }

  void sell({int? slot}) {
    _checkSlot(slot);
    final sword = slot == null ? state.sword : state.storage[slot];
    if (sword == null || !sword.canSell) {
      throw const RuleException('이 검은 판매할 수 없습니다.');
    }
    if (sword.locked) throw const RuleException('잠금을 해제한 뒤 판매하세요.');
    state.gold = min(Balance.maxGold, state.gold + saleNet(sword));
    if (slot == null) {
      state.sword = newStartSword();
    } else {
      state.storage[slot] = null;
    }
  }

  void store({int? slot}) {
    _checkSlot(slot);
    if (!state.sword.canStore) {
      throw const RuleException('시작 검은 한 번 강화한 뒤 보관할 수 있습니다.');
    }
    final target = slot ?? state.storage.indexOf(null);
    if (target < 0 || state.storage[target] != null) {
      throw const RuleException('빈 보관 칸이 없습니다. 상점에서 보관 칸을 구매하세요.');
    }
    state.storage[target] = state.sword;
    state.sword = newStartSword();
  }

  void swap(int slot) {
    _checkSlot(slot);
    final stored = state.storage[slot];
    if (stored == null) throw const RuleException('비어 있는 칸입니다.');
    state.storage[slot] = state.sword.canStore ? state.sword : null;
    state.sword = stored.copyWith(locked: false);
  }

  void toggleLock(int slot) {
    _checkSlot(slot);
    final sword = state.storage[slot];
    if (sword == null) return;
    state.storage[slot] = sword.copyWith(locked: !sword.locked);
  }

  void buySlot() {
    if (state.storage.length >= Balance.slotPrices.length) {
      throw const RuleException('보관함은 최대 5칸입니다.');
    }
    _pay(Balance.slotPrices[state.storage.length]);
    state.storage.add(null);
  }

  void buyNegotiation() {
    if (state.negotiation >= Balance.negotiationPrices.length) {
      throw const RuleException('협상력이 최고 수준입니다.');
    }
    _pay(Balance.negotiationPrices[state.negotiation]);
    state.negotiation++;
  }

  void buyRareChance() {
    if (state.rareChanceLevel >= Balance.rareChancePrices.length) {
      throw const RuleException('희귀 발견 확률은 최대 5%입니다.');
    }
    _pay(Balance.rareChancePrices[state.rareChanceLevel]);
    state.rareChanceLevel++;
  }

  double normalStartCost(int level) =>
      Checkpoints.normalPrice(level) -
      Checkpoints.normalPrice(state.unlockedStartLevel);

  void buyNormalStart(int level) {
    if (!Checkpoints.normalLevels.contains(level) ||
        level <= state.unlockedStartLevel) {
      throw const RuleException('구매 가능한 일반 시작점이 아닙니다.');
    }
    if (state.bestLevel < level) {
      throw RuleException('먼저 일반 검 +$level에 도달하세요.');
    }
    _pay(normalStartCost(level));
    state.unlockedStartLevel = level;
    selectStart(level: level);
  }

  void buyRareStart(String id) {
    if (!rareWeapons.any((w) => w.id == id) || state.rareStarts.contains(id)) {
      throw const RuleException('구매 가능한 희귀 시작점이 아닙니다.');
    }
    if (!state.discovered.containsKey(id)) {
      throw const RuleException('먼저 이 희귀 무기를 발견하세요.');
    }
    _pay(Checkpoints.rarePrice);
    state.rareStarts.add(id);
    selectStart(rareId: id);
  }

  void selectStart({int level = 0, String? rareId}) {
    if (rareId == null
        ? !Checkpoints.isNormalLevel(level) || level > state.unlockedStartLevel
        : !state.rareStarts.contains(rareId)) {
      throw const RuleException('구매한 시작점을 선택하세요.');
    }
    state.startLevel = rareId == null ? level : 0;
    state.startRareId = rareId;
    // Keep a sword the player has enhanced; an unused starter can be replaced.
    if (!state.sword.canStore && !state.sword.locked) {
      state.sword = newStartSword();
    }
  }

  void relief() {
    if (!canRelief) throw const RuleException('판매할 검이 있거나 강화 자금이 충분합니다.');
    state.gold += 50;
  }

  void _checkSlot(int? slot) {
    if (slot != null && (slot < 0 || slot >= state.storage.length)) {
      throw const RuleException('잘못된 보관 칸입니다.');
    }
  }

  void _pay(double cost) {
    if (state.gold < cost) throw const RuleException('골드가 부족합니다.');
    state.gold -= cost;
    state.spent += cost;
  }
}
