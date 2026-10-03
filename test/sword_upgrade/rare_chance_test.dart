import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/balance.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/models.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/rules.dart';

void main() {
  test(
    'permanent discovery upgrades charge each price and stop at five percent',
    () {
      final total = Balance.rareChancePrices.reduce((a, b) => a + b);
      final state = GameState()..gold = total + 1000;
      final rules = GameRules(state);
      expect(state.rareChance, .005);
      for (final chance in [.01, .02, .03, .04, .05]) {
        rules.buyRareChance();
        expect(state.rareChance, chance);
      }
      expect(state.rareChanceLevel, 5);
      expect(state.gold, 1000);
      expect(state.spent, total);
      expect(state.sword.level, 0);
      final before = jsonEncode(state.toJson());
      expect(() => rules.buyRareChance(), throwsA(isA<RuleException>()));
      expect(jsonEncode(state.toJson()), before);
    },
  );

  test(
    'unaffordable discovery upgrade leaves money, level and sword unchanged',
    () {
      for (final level in [0, 4]) {
        final state = GameState()
          ..rareChanceLevel = level
          ..gold = Balance.rareChancePrices[level] - 1
          ..sword = const Sword(level: 5)
          ..bestLevel = 5;
        final before = jsonEncode(state.toJson());
        expect(
          () => GameRules(state).buyRareChance(),
          throwsA(isA<RuleException>()),
        );
        expect(jsonEncode(state.toJson()), before);
      }
    },
  );

  test(
    'actual destruction uses purchased rate with a strict five percent ceiling',
    () {
      for (final (level, draw, appears) in [
        (0, .005, false),
        (1, .005, true),
        (2, .02, false),
        (3, .02, true),
        (5, .049999, true),
        (5, .05, false),
      ]) {
        final state = GameState()..rareChanceLevel = level;
        final sequence = [.999, draw, .25].iterator;
        var drawCount = 0;
        final rules = GameRules(
          state,
          roll: () {
            drawCount++;
            sequence.moveNext();
            return sequence.current;
          },
        );
        final outcome = rules.enhance();
        expect(
          outcome.kind,
          appears ? OutcomeKind.rareFound : OutcomeKind.destroyed,
        );
        expect(state.sword.isRare, appears);
        expect(state.rareFinds, appears ? 1 : 0);
        expect(state.destructions, 1);
        expect(drawCount, appears ? 3 : 2);
        if (appears) {
          expect(state.sword.level, 0);
          expect(state.sword.hearts, 3);
          expect(state.sword.rareBase, Balance.salePrices[10]);
        }
      }
    },
  );
}
