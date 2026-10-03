import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/balance.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/models.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/rules.dart';

void main() {
  test('generated balance tables cover every normal and rare level', () {
    expect(Balance.probabilities.length, Balance.maxLevel);
    expect(Balance.salePrices.length, Balance.maxLevel + 1);
    expect(Balance.enhanceCosts.length, Balance.maxLevel);
    expect(Balance.normalNames.length, Balance.maxLevel + 1);
    expect(Balance.rareMultipliers.length, Balance.rareMaxLevel + 1);
    expect(Balance.salePrices.last, 7.98e17);
  });
  test(
    'crafts 0 to ending using recursive material production in five slots',
    () {
      final state = GameState()
        ..gold = 1e25
        ..storage = List.filled(5, null);
      final rules = GameRules(state, roll: () => 0);
      void craft(int target) {
        while (state.sword.level < target) {
          final gate = rules.gate;
          if (gate != null) {
            final mainSlot = state.storage.indexOf(null);
            rules.store();
            for (var i = 0; i < gate.count; i++) {
              craft(gate.minimumLevel);
              if (i == gate.count - 1) {
                rules.swap(mainSlot);
              } else {
                rules.store();
              }
            }
          }
          rules.enhance();
        }
      }

      craft(Balance.maxLevel);
      expect(state.sword.level, Balance.maxLevel);
      expect(state.storage.whereType<Sword>(), isEmpty);
      expect(state.ending, isNotNull);
      expect(() => rules.enhance(), throwsA(isA<RuleException>()));
      expect(() => rules.sell(), throwsA(isA<RuleException>()));
      expect(
        GameState.fromJson(jsonDecode(jsonEncode(state.toJson()))).ending,
        state.ending,
      );
    },
  );
  test('insufficient money or invalid materials leave all state unchanged', () {
    final state = GameState()..gold = 1;
    final rules = GameRules(state, roll: () => 0);
    var before = jsonEncode(state.toJson());
    expect(() => rules.enhance(), throwsA(isA<RuleException>()));
    expect(jsonEncode(state.toJson()), before);
    state
      ..gold = 1e6
      ..sword = const Sword(level: 10)
      ..bestLevel = 10
      ..storage = [
        const Sword(level: 5),
        const Sword(rareId: 'softshell', rareBase: 7690),
      ];
    before = jsonEncode(state.toJson());
    expect(() => rules.enhance(materials: [1]), throwsA(isA<RuleException>()));
    expect(jsonEncode(state.toJson()), before);
  });
  test(
    'breakthrough consumes materials only on success, including explicit locked selection',
    () {
      final state = GameState()
        ..gold = 1e6
        ..sword = const Sword(level: 10)
        ..bestLevel = 10
        ..protection = 3
        ..storage = [const Sword(level: 5, locked: true)];
      final rolls = [.99, .1, 0.0].iterator;
      final rules = GameRules(
        state,
        roll: () {
          rolls.moveNext();
          return rolls.current;
        },
      );
      expect(rules.materialCandidates(), isEmpty);
      expect(rules.enhance(materials: [0]).kind, OutcomeKind.protected);
      expect(state.storage[0]?.level, 5);
      expect(state.failures[10], 1);
      expect(rules.enhance(materials: [0]).kind, OutcomeKind.breakthrough);
      expect(state.storage[0], isNull);
      expect(state.failures[10], 0);
    },
  );
  test(
    'pity survives destruction, sale, storage and swap, then resets only on success',
    () {
      final state = GameState()
        ..sword = const Sword(level: 6)
        ..bestLevel = 6
        ..gold = 1e6
        ..storage = [const Sword(level: 6)];
      final failure = GameRules(state, roll: () => .999);
      failure.enhance();
      expect(state.failures[6], 1);
      failure.swap(0);
      expect(failure.probability, closeTo(.902, 1e-10));
      failure.sell();
      expect(state.failures[6], 1);
      state.sword = const Sword(level: 6);
      final success = GameRules(state, roll: () => 0);
      success.enhance();
      expect(state.failures[6], 0);
      state
        ..sword = const Sword(level: 37)
        ..failures[37] = 100;
      expect(success.probability, .1);
    },
  );
  test(
    'rare draw happens on actual normal destruction, uses destroyed value, and cannot chain',
    () {
      final state = GameState()
        ..rareChanceLevel = 5
        ..gold = 1e12
        ..sword = const Sword(level: 20)
        ..bestLevel = 20
        ..storage = [const Sword(level: 15)];
      final draws = [.99, .001, 0.0].iterator;
      final rules = GameRules(
        state,
        roll: () {
          draws.moveNext();
          return draws.current;
        },
      );
      expect(rules.enhance().kind, OutcomeKind.rareFound);
      expect(state.sword.rareId, 'alexandros');
      expect(state.sword.rareBase, Balance.salePrices[20] * 3);
      expect(state.rareFinds, 1);
      expect(state.discovered['alexandros'], 0);
      state.protection = 3;
      final rareRules = GameRules(state, roll: () => .999);
      expect(rareRules.totalCost, rareRules.enhanceCost);
      rareRules.enhance();
      rareRules.enhance();
      expect(state.sword.hearts, 1);
      rareRules.enhance();
      expect(state.sword.isRare, isFalse);
      expect(state.rareFinds, 1);
      expect(state.failures[0], 0);
    },
  );
  test('protected failure never draws a rare sword', () {
    final state = GameState()
      ..rareChanceLevel = 5
      ..gold = 1e6
      ..sword = const Sword(level: 5)
      ..bestLevel = 5
      ..protection = 3;
    var count = 0;
    final rules = GameRules(state, roll: () => count++ == 0 ? .99 : 0);
    expect(rules.enhance().kind, OutcomeKind.protected);
    expect(count, 2);
    expect(state.rareFinds, 0);
  });
  test('shop, fee, storage swap, locks and rare +0 sale', () {
    final state = GameState()
      ..gold = 10000
      ..sword = const Sword(level: 5)
      ..bestLevel = 5;
    final rules = GameRules(state);
    rules.buySlot();
    rules.store();
    rules.toggleLock(0);
    expect(() => rules.sell(slot: 0), throwsA(isA<RuleException>()));
    rules.swap(0);
    expect(state.sword.level, 5);
    expect(state.sword.locked, isFalse);
    rules.buyNegotiation();
    final gold = state.gold;
    rules.sell();
    expect(state.gold, closeTo(gold + Balance.salePrices[5] * .8, 1e-6));
    state
      ..sword = const Sword(rareId: 'softshell', rareBase: 7690)
      ..discovered['softshell'] = 0
      ..rareFinds = 1;
    rules.store();
    rules.sell(slot: 0);
    expect(state.storage[0], isNull);
    expect(state.discovered['softshell'], 0);
  });
  test(
    'relief excludes locked and unsellable swords but blocks when sale is possible',
    () {
      final state = GameState()
        ..gold = 0
        ..storage = [const Sword(level: 5, locked: true)];
      final rules = GameRules(state);
      expect(rules.canRelief, isTrue);
      rules.relief();
      expect(state.gold, 50);
      state.gold = 0;
      rules.toggleLock(0);
      expect(rules.canRelief, isFalse);
      expect(() => rules.relief(), throwsA(isA<RuleException>()));
    },
  );
  test(
    'ending swords and rare weapons cannot become breakthrough materials',
    () {
      final state = GameState()
        ..sword = const Sword(level: 35)
        ..storage = [
          const Sword(level: Balance.maxLevel),
          const Sword(rareId: 'muramasa', rareBase: 7690),
          const Sword(level: 30),
        ];
      expect(GameRules(state).materialCandidates(includeLocked: true), [2]);
    },
  );
}
