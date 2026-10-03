import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_blanche/apps/sword_upgrade/data/save_repository.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/balance.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/models.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/rules.dart';

void main() {
  test(
    'protection follows current sword, not best record, including late discounts',
    () {
      final state = GameState()
        ..gold = 1e20
        ..bestLevel = 37
        ..protection = 3;
      final rules = GameRules(state);
      for (final level in [1, 5, 25, 26, 30, 31, 37]) {
        state.sword = Sword(level: level);
        final discount = level >= 31
            ? .3
            : level >= 26
            ? .6
            : 1;
        expect(
          rules.protectionCost,
          closeTo(Balance.salePrices[level] * .35 * discount, .001),
        );
        expect(rules.totalCost, rules.enhanceCost + rules.protectionCost);
      }
      state.sword = const Sword(level: 1);
      expect(rules.protectionCost, 7);
      state.protection = 0;
      expect(rules.protectionCost, 0);
    },
  );
  test('success and protected failure both pay once, without inventory', () {
    final state = GameState()
      ..gold = 10000
      ..sword = const Sword(level: 5)
      ..bestLevel = 5
      ..protection = 3;
    final cost = Balance.enhanceCosts[5] + Balance.salePrices[5] * .35;
    expect(GameRules(state, roll: () => 0).enhance().kind, OutcomeKind.success);
    expect(state.gold, closeTo(10000 - cost, 1e-8));
    state.sword = const Sword(level: 5);
    final draws = [.999, .1].iterator;
    final rules = GameRules(
      state,
      roll: () {
        draws.moveNext();
        return draws.current;
      },
    );
    expect(rules.enhance().kind, OutcomeKind.protected);
    expect(state.gold, closeTo(10000 - 2 * cost, 1e-8));
    expect(state.spent, closeTo(2 * cost, 1e-8));
    expect(state.protection, 3);
  });
  test(
    'gold enough for enhancement alone cannot silently downgrade protection',
    () {
      final state = GameState()
        ..gold = Balance.enhanceCosts[5]
        ..sword = const Sword(level: 5)
        ..bestLevel = 5
        ..protection = 3;
      final before = jsonEncode(state.toJson());
      final rules = GameRules(
        state,
        roll: () => throw StateError('must not roll'),
      );
      expect(() => rules.enhance(), throwsA(isA<RuleException>()));
      expect(jsonEncode(state.toJson()), before);
    },
  );
  test('invalid materials never spend protection or roll', () {
    final state = GameState()
      ..gold = 1e6
      ..sword = const Sword(level: 10)
      ..bestLevel = 10
      ..protection = 3;
    final before = jsonEncode(state.toJson());
    expect(
      () => GameRules(
        state,
        roll: () => throw StateError('must not roll'),
      ).enhance(),
      throwsA(isA<RuleException>()),
    );
    expect(jsonEncode(state.toJson()), before);
  });
  test('ninety percent protection can fail and destroy despite payment', () {
    expect(Balance.protectionChances.last, .9);
    final state = GameState()
      ..gold = 10000
      ..sword = const Sword(level: 5)
      ..bestLevel = 5
      ..protection = 3;
    final draws = [.999, .9, .999].iterator;
    final rules = GameRules(
      state,
      roll: () {
        draws.moveNext();
        return draws.current;
      },
    );
    final cost = rules.totalCost;
    expect(rules.enhance().kind, OutcomeKind.destroyed);
    expect(state.gold, closeTo(10000 - cost, 1e-8));
    expect(rules.protectionCost, 0);
    expect(state.protection, 3);
  });
  test(
    'normal +0 gets no free protection, and rare only charges enhancement',
    () {
      final state = GameState()..protection = 3;
      final draws = [.999, .999].iterator;
      final rules = GameRules(
        state,
        roll: () {
          draws.moveNext();
          return draws.current;
        },
      );
      expect(rules.protectionCost, 0);
      expect(rules.enhance().kind, OutcomeKind.destroyed);
      expect(state.gold, 490);
      state
        ..gold = 1e6
        ..sword = const Sword(rareId: 'alexandros', rareBase: 7690)
        ..discovered['alexandros'] = 0
        ..rareFinds = 1;
      final rare = GameRules(state, roll: () => .999);
      expect(rare.protectionCost, 0);
      final cost = rare.totalCost;
      rare.enhance();
      expect(state.gold, closeTo(1e6 - cost, 1e-8));
      expect(state.sword.hearts, 2);
    },
  );
  test(
    'cheat flag never overrides odds; full cheat has capped pity, baseline has none',
    () {
      final full = SaveRepository.decode(
        File('test/sword_upgrade/fixtures/CHEAT_BACKUP.txt').readAsStringSync(),
      );
      final baseline = SaveRepository.decode(
        File('test/sword_upgrade/fixtures/CHEAT_BACKUP_BASE_ODDS.txt').readAsStringSync(),
      );
      for (var level = 0; level < Balance.maxLevel; level++) {
        full.sword = Sword(level: level);
        baseline.sword = Sword(level: level);
        expect(
          GameRules(full).probability,
          (Balance.probabilities[level] * 2).clamp(0, 1),
        );
        expect(GameRules(baseline).probability, Balance.probabilities[level]);
      }
      expect(GameRules(full).probability, .1);
      expect(full.failures.every((f) => f == 10), isTrue);
      expect(baseline.failures.every((f) => f == 0), isTrue);
      full.sword = baseline.sword = const Sword(
        rareId: 'alexandros',
        rareBase: 7690,
      );
      expect(GameRules(full).probability, .7);
      expect(GameRules(baseline).probability, .7);
    },
  );
}
