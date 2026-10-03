import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pure_blanche/apps/sword_upgrade/data/save_repository.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/models.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/balance.dart';
import 'package:pure_blanche/apps/sword_upgrade/state/game_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<GameController> make(
    GameState state, {
    double Function()? roll,
  }) async {
    SharedPreferences.setMockInitialValues({});
    return GameController(
      SaveRepository(await SharedPreferences.getInstance()),
      state: state,
      roll: roll ?? () => 0,
      trackTime: false,
    );
  }

  testWidgets(
    'auto stops exactly at target and blocks duplicate manual input',
    (tester) async {
      final state = GameState()..autoTarget = 2;
      final game = await make(state);
      final running = game.startAuto();
      expect(game.busy, isTrue);
      await game.enhance();
      expect(state.attempts, 1);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await running;
      expect(state.sword.level, 2);
      expect(state.attempts, 2);
      expect(game.autoRunning, isFalse);
      game.dispose();
    },
  );
  testWidgets(
    'auto stops at breakthrough before spending gold or consuming material',
    (tester) async {
      final state = GameState()
        ..sword = const Sword(level: 9)
        ..bestLevel = 9
        ..gold = 1e6
        ..storage = [const Sword(level: 5)]
        ..autoTarget = 12;
      final game = await make(state);
      final running = game.startAuto();
      await tester.pump(const Duration(milliseconds: 300));
      await running;
      expect(state.sword.level, 10);
      expect(state.storage[0]?.level, 5);
      expect(state.attempts, 1);
      expect(game.message, contains('돌파'));
      game.dispose();
    },
  );
  testWidgets('auto stops on rare discovery', (tester) async {
    final state = GameState()..autoTarget = 5;
    final sequence = [.999, .001, 0.0].iterator;
    final game = await make(
      state,
      roll: () {
        sequence.moveNext();
        return sequence.current;
      },
    );
    final running = game.startAuto();
    await tester.pump(const Duration(milliseconds: 1200));
    await running;
    expect(state.sword.rareId, 'alexandros');
    expect(state.attempts, 1);
    expect(game.autoRunning, isFalse);
    game.dispose();
  });
  for (final short in [false, true]) {
    testWidgets(
      'upgraded auto discovery preserves rare +0 and hearts, short=$short',
      (tester) async {
        final state = GameState()
          ..gold = Balance.rareChancePrices.reduce((a, b) => a + b) + 1e6
          ..shortAnimation = short
          ..sword = const Sword(level: 5)
          ..bestLevel = 5
          ..autoTarget = 8;
        final draws = [.999, .03, .45].iterator;
        final game = await make(
          state,
          roll: () {
            draws.moveNext();
            return draws.current;
          },
        );
        for (var i = 0; i < 5; i++) {
          game.rules.buyRareChance();
        }
        final gold = state.gold;
        final cost = game.rules.totalCost;
        final running = game.startAuto();
        expect(state.sword.rareId, 'softshell');
        expect(state.sword.level, 0);
        expect(state.sword.hearts, 3);
        expect(game.busy, isTrue);
        await game.enhance();
        await game.startAuto();
        await tester.pump(Duration(milliseconds: (short ? 600 : 1200) - 1));
        expect(state.attempts, 1);
        await tester.pump(const Duration(milliseconds: 1));
        await running;
        expect(game.autoRunning, isFalse);
        expect(game.message, contains('수동'));
        await tester.pump(const Duration(seconds: 5));
        await game.startAuto();
        expect(state.attempts, 1);
        expect(state.gold, gold - cost);
        expect(state.sword.level, 0);
        expect(state.sword.hearts, 3);
        await game.saveNow();
        final restored = game.repository.load()!;
        expect(restored.rareChanceLevel, 5);
        expect(restored.sword.toJson(), state.sword.toJson());
        final reloaded = GameController(
          game.repository,
          state: restored,
          trackTime: false,
        );
        expect(reloaded.autoRunning, isFalse);
        await reloaded.startAuto();
        expect(restored.attempts, 1);
        reloaded.dispose();
        game.dispose();
      },
    );
  }
  testWidgets('manual effects finish before another attempt is accepted', (
    tester,
  ) async {
    final game = await make(GameState());
    final attempt = game.enhance();
    await tester.pump(const Duration(milliseconds: 300));
    expect(game.busy, isTrue);
    await game.enhance();
    expect(game.state.attempts, 1);
    await tester.pump(const Duration(milliseconds: 600));
    await attempt;
    expect(game.busy, isFalse);
    game.setSettings(shortAnimation: true);
    final shortAttempt = game.enhance();
    await tester.pump(const Duration(milliseconds: 399));
    expect(game.busy, isTrue);
    await tester.pump(const Duration(milliseconds: 1));
    await shortAttempt;
    expect(game.busy, isFalse);
    game.dispose();
  });
  testWidgets('short animation preserves the fast auto pace', (tester) async {
    final game = await make(
      GameState()
        ..shortAnimation = true
        ..autoTarget = 2,
    );
    final running = game.startAuto();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 150));
    await running;
    expect(game.state.attempts, 2);
    expect(game.autoRunning, isFalse);
    game.dispose();
  });
  testWidgets('auto stops at the gate of a purchased replacement starter', (
    tester,
  ) async {
    final state = GameState()
      ..gold = 1e20
      ..bestLevel = 10
      ..sword = const Sword(level: 9)
      ..autoTarget = 12;
    final game = await make(state, roll: () => .999);
    game.rules.buyNormalStart(10);
    final running = game.startAuto();
    await tester.pump(const Duration(milliseconds: 300));
    await running;
    expect(state.sword.level, 10);
    expect(state.attempts, 1);
    expect(game.message, contains('돌파'));
    expect(game.autoRunning, isFalse);
    game.dispose();
  });
  testWidgets(
    'auto stops when the selected rare starter replaces a normal sword',
    (tester) async {
      final state = GameState()
        ..gold = 1e20
        ..bestLevel = 1
        ..sword = const Sword(level: 1)
        ..autoTarget = 3
        ..rareFinds = 1
        ..discovered['alexandros'] = 0;
      final game = await make(state, roll: () => .999);
      game.rules.buyRareStart('alexandros');
      expect(state.sword.isRare, isFalse);
      final running = game.startAuto();
      await tester.pump(const Duration(milliseconds: 300));
      await running;
      expect(state.sword.rareId, 'alexandros');
      expect(state.sword.hearts, 3);
      expect(state.rareFinds, 1);
      expect(game.autoRunning, isFalse);
      game.dispose();
    },
  );
  testWidgets(
    'auto never downgrades protection when only enhancement gold is available',
    (tester) async {
      final state = GameState()
        ..sword = const Sword(level: 5)
        ..bestLevel = 5
        ..gold = 35
        ..protection = 3
        ..autoTarget = 6;
      final game = await make(state);
      await game.startAuto();
      expect(state.attempts, 0);
      expect(state.gold, 35);
      expect(state.protection, 3);
      expect(game.autoRunning, isFalse);
      game.dispose();
    },
  );
  testWidgets(
    'auto pays current proportional cost and stops before an unaffordable next attempt',
    (tester) async {
      final state = GameState()
        ..gold = 29
        ..protection = 3
        ..autoTarget = 5;
      final game = await make(state);
      final running = game.startAuto();
      expect(state.sword.level, 1);
      expect(state.gold, 19);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await running;
      expect(state.sword.level, 2);
      expect(state.attempts, 2);
      expect(state.gold, 0);
      expect(state.protection, 3);
      expect(game.message, contains('골드'));
      await game.startAuto();
      expect(state.attempts, 2);
      game.dispose();
    },
  );
  testWidgets(
    'auto uses lower protection cost after destruction and preserves selection',
    (tester) async {
      final state = GameState()
        ..gold = 29
        ..protection = 3
        ..autoTarget = 5;
      final draws = [.999, .999, 0.0].iterator;
      final game = await make(
        state,
        roll: () {
          draws.moveNext();
          return draws.current;
        },
      );
      final running = game.startAuto();
      expect(state.destructions, 1);
      expect(state.gold, 19);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await running;
      expect(state.sword.level, 1);
      expect(state.attempts, 2);
      expect(state.gold, 9);
      expect(game.rules.protectionCost, 7);
      expect(state.protection, 3);
      game.dispose();
    },
  );
  testWidgets('hidden lifecycle stops auto after its current atomic attempt', (
    tester,
  ) async {
    final state = GameState()..autoTarget = 8;
    final game = await make(state);
    final running = game.startAuto();
    game.didChangeAppLifecycleState(AppLifecycleState.hidden);
    await tester.pump(const Duration(milliseconds: 300));
    await running;
    await tester.pump(const Duration(seconds: 10));
    expect(state.attempts, 1);
    expect(game.autoRunning, isFalse);
    game.dispose();
  });
}
