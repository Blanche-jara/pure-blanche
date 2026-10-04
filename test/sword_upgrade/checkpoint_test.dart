import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/balance.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/checkpoints.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/models.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/rules.dart';

void main() {
  for (final start in [10, 20, 30]) {
    test(
      '+$start starter keeps normal odds/cost and does not consume materials',
      () {
        final state = GameState()
          ..gold = 1e20
          ..bestLevel = start
          ..storage = [const Sword(level: 5), const Sword(level: 25)];
        final rules = GameRules(state, roll: () => 0);
        rules.buyNormalStart(start);
        final materialSnapshot = jsonEncode(
          state.storage.map((s) => s?.toJson()).toList(),
        );
        expect(rules.startMaterialsExempt, isTrue);
        expect(rules.probability, Balance.probabilities[start]);
        expect(rules.totalCost, Balance.enhanceCosts[start]);
        final spent = state.spent;
        expect(rules.enhance().kind, OutcomeKind.success);
        expect(state.spent - spent, closeTo(Balance.enhanceCosts[start], .01));
        expect(state.sword.level, start + 1);
        expect(state.sword.starterValue, Balance.salePrices[start]);
        expect(
          jsonEncode(state.storage.map((s) => s?.toJson()).toList()),
          materialSnapshot,
        );
        expect(rules.startMaterialsExempt, isFalse);
        rules.sell();
        expect(state.sword.level, start);
        expect(rules.startMaterialsExempt, isTrue);
      },
    );
  }
  test(
    'an earned gate still requires materials even when its checkpoint is owned',
    () {
      final state = GameState()
        ..gold = 1e10
        ..bestLevel = 20
        ..unlockedStartLevel = 20
        ..startLevel = 20
        ..sword = const Sword(level: 10);
      final rules = GameRules(state);
      expect(rules.startMaterialsExempt, isFalse);
      expect(rules.gate, isNotNull);
      expect(() => rules.enhance(), throwsA(isA<RuleException>()));
      state.sword = Sword(level: 20, starterValue: Balance.salePrices[10]);
      expect(rules.startMaterialsExempt, isFalse);
      expect(rules.gate, isNotNull);
      expect(() => rules.enhance(), throwsA(isA<RuleException>()));
    },
  );
  test(
    'first-gate exemption retains failure, pity, protection fees and destruction',
    () {
      final state = GameState()
        ..gold = 1e10
        ..bestLevel = 10;
      final rules = GameRules(state, roll: () => .999);
      rules.buyNormalStart(10);
      final before = state.gold;
      expect(rules.enhance().kind, OutcomeKind.destroyed);
      expect(state.gold, before - Balance.enhanceCosts[10]);
      expect(state.sword.level, 10);
      expect(state.failures[10], 1);
      expect(rules.startMaterialsExempt, isTrue);
      expect(rules.probability, closeTo(.77, 1e-9));
      state.protection = 1;
      final rolls = [.999, 0.0];
      final protected = GameRules(state, roll: () => rolls.removeAt(0));
      final gold = state.gold;
      final cost = protected.totalCost;
      expect(protected.enhance().kind, OutcomeKind.protected);
      expect(state.gold, closeTo(gold - cost, .00001));
      expect(state.failures[10], 2);
      expect(protected.startMaterialsExempt, isTrue);
      expect(state.sword.canStore, isFalse);
    },
  );
  test('only 10, 20 and 30 starts are sold after reaching the branch', () {
    final state = GameState()..gold = 1e20;
    final rules = GameRules(state);
    for (final level in [1, 5, 11, 15, 21, 25, 31, 35, 38]) {
      final before = jsonEncode(state.toJson());
      expect(() => rules.buyNormalStart(level), throwsA(isA<RuleException>()));
      expect(jsonEncode(state.toJson()), before);
    }
    state.bestLevel = 30;
    rules.buyNormalStart(30);
    expect(state.unlockedStartLevel, 30);
    expect(state.startLevel, 30);
    expect(state.sword.level, 30);
    expect(state.spent, Checkpoints.normalPrice(30));
    rules.selectStart(level: 10);
    expect(state.sword.level, 10);
    rules.selectStart(level: 20);
    expect(state.sword.level, 20);
    rules.selectStart();
    expect(state.sword.level, 0);
  });
  test(
    'normal upgrades charge only the difference and do not replace progress',
    () {
      final state = GameState()
        ..gold = 1e20
        ..bestLevel = 30
        ..sword = const Sword(level: 7);
      final rules = GameRules(state);
      rules.buyNormalStart(10);
      expect(state.sword.level, 7);
      expect(
        rules.normalStartCost(20),
        Checkpoints.normalPrice(20) - Checkpoints.normalPrice(10),
      );
      rules.buyNormalStart(20);
      rules.buyNormalStart(30);
      expect(state.spent, Checkpoints.normalPrice(30));
      expect(state.sword.level, 7);
      final before = jsonEncode(state.toJson());
      expect(() => rules.buyNormalStart(30), throwsA(isA<RuleException>()));
      expect(jsonEncode(state.toJson()), before);
    },
  );
  test(
    'insufficient checkpoint funds leave ownership and current sword intact',
    () {
      final state = GameState()..bestLevel = 30;
      final rules = GameRules(state);
      final before = jsonEncode(state.toJson());
      expect(() => rules.buyNormalStart(10), throwsA(isA<RuleException>()));
      expect(() => rules.selectStart(level: 10), throwsA(isA<RuleException>()));
      expect(jsonEncode(state.toJson()), before);
    },
  );
  test(
    'purchased starters waive their first gate only; later gates still need materials',
    () {
      final state = GameState()
        ..gold = 1e10
        ..bestLevel = 10
        ..sword = const Sword(level: 9);
      final rules = GameRules(state, roll: () => .999);
      rules.buyNormalStart(10);
      expect(rules.enhance().kind, OutcomeKind.destroyed);
      expect(state.sword.level, 10);
      expect(rules.gate, isNull);
      final success = GameRules(state, roll: () => 0);
      expect(success.enhance().kind, OutcomeKind.success);
      expect(state.sword.level, 11);
      state.sword = Sword(level: 15, starterValue: Balance.salePrices[10]);
      expect(rules.gate, isNotNull);
      final before = jsonEncode(state.toJson());
      expect(() => rules.enhance(), throwsA(isA<RuleException>()));
      expect(jsonEncode(state.toJson()), before);
    },
  );
  test(
    'free starters cannot be sold or stored; sales credit only gained value',
    () {
      final state = GameState()
        ..gold = 1e10
        ..bestLevel = 10
        ..storage = [const Sword(level: 5)];
      final rules = GameRules(state, roll: () => 0);
      rules.buyNormalStart(10);
      final before = jsonEncode(state.toJson());
      expect(() => rules.sell(), throwsA(isA<RuleException>()));
      expect(() => rules.store(), throwsA(isA<RuleException>()));
      expect(jsonEncode(state.toJson()), before);
      rules.swap(0);
      expect(state.storage[0], isNull);
      rules.sell();
      expect(state.sword.level, 10);
      state.storage[0] = const Sword(level: 5);
      expect(rules.enhance().kind, OutcomeKind.success);
      final gained = Balance.salePrices[11] - Balance.salePrices[10];
      expect(rules.saleNet(state.sword), gained * .75);
      final gold = state.gold;
      rules.sell();
      expect(state.gold, gold + gained * .75);
      expect(state.sword.level, 10);
      expect(state.sword.canSell, isFalse);
    },
  );
  test(
    'storing an enhanced starter keeps its basis and creates the selected start',
    () {
      final state = GameState()
        ..gold = 1e10
        ..bestLevel = 10
        ..storage = [null];
      final rules = GameRules(state, roll: () => 0);
      rules.buyNormalStart(10);
      rules.enhance();
      rules.store();
      expect(state.sword.level, 10);
      expect(state.storage[0]?.starterValue, Balance.salePrices[10]);
      rules.swap(0);
      expect(state.storage[0], isNull);
      expect(
        rules.saleNet(state.sword),
        (Balance.salePrices[11] - Balance.salePrices[10]) * .75,
      );
    },
  );
  test(
    'rare starts require discovery and cost 30 times the highest normal start',
    () {
      final state = GameState()..gold = 1e20;
      final rules = GameRules(state);
      expect(Checkpoints.rarePrice, Checkpoints.normalPrice(30) * 30);
      final before = jsonEncode(state.toJson());
      expect(
        () => rules.buyRareStart('alexandros'),
        throwsA(isA<RuleException>()),
      );
      expect(jsonEncode(state.toJson()), before);
      state.discovered['alexandros'] = 0;
      state.rareFinds = 1;
      rules.buyRareStart('alexandros');
      expect(state.sword.rareId, 'alexandros');
      expect(state.sword.level, 0);
      expect(state.sword.hearts, 3);
      expect(state.sword.rareBase, Balance.salePrices[30] * 3);
      expect(state.sword.canSell, isFalse);
      expect(state.sword.canStore, isFalse);
      expect(state.rareFinds, 1);
      expect(state.spent, Checkpoints.rarePrice);
      expect(
        () => rules.buyRareStart('alexandros'),
        throwsA(isA<RuleException>()),
      );
      expect(
        () => rules.selectStart(rareId: 'softshell'),
        throwsA(isA<RuleException>()),
      );
    },
  );
  test(
    'rare starters reset hearts on destruction and retain basis after enhancement',
    () {
      final state = GameState()
        ..gold = 1e20
        ..discovered['softshell'] = 0
        ..rareFinds = 1;
      final failure = GameRules(state, roll: () => .999);
      failure.buyRareStart('softshell');
      failure.enhance();
      expect(state.sword.hearts, 2);
      failure.enhance();
      expect(state.sword.hearts, 1);
      expect(failure.enhance().kind, OutcomeKind.destroyed);
      expect(state.sword.rareId, 'softshell');
      expect(state.sword.hearts, 3);
      expect(state.sword.level, 0);
      expect(state.rareFinds, 1);
      final success = GameRules(state, roll: () => 0);
      success.enhance();
      final increased = Checkpoints.rareBase * (Balance.rareMultipliers[1] - 1);
      expect(success.saleNet(state.sword), closeTo(increased * .75, 1));
      success.sell();
      expect(state.sword.level, 0);
      expect(state.sword.rareId, 'softshell');
      expect(state.sword.canSell, isFalse);
      expect(state.rareFinds, 1);
    },
  );
}
