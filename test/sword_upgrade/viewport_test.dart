import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pure_blanche/apps/sword_upgrade/data/save_repository.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/models.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/balance.dart';
import 'package:pure_blanche/apps/sword_upgrade/state/game_controller.dart';
import 'package:pure_blanche/apps/sword_upgrade/sword_upgrade_app.dart';
import 'package:pure_blanche/apps/sword_upgrade/ui/forge_screen.dart';
import 'package:pure_blanche/apps/sword_upgrade/ui/design_tokens.dart';
import 'package:pure_blanche/apps/sword_upgrade/ui/widgets/forge_stage.dart';

void main() {
  testWidgets(
    'mobile protection selection shows proportional cost and charges on success',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final repository = SaveRepository(await SharedPreferences.getInstance());
      final state = GameState()
        ..sword = const Sword(level: 5)
        ..bestLevel = 31;
      final game = GameController(
        repository,
        state: state,
        roll: () => 0,
        trackTime: false,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: swordTheme,
          home: ForgeScreen(controller: game),
        ),
      );
      await tester.pumpAndSettle();
      final option = find.byKey(const ValueKey('protection-3'));
      await tester.ensureVisible(option);
      expect(tester.widget<PixelButton>(option).detail, '127 G');
      await tester.tap(option);
      await tester.pumpAndSettle();
      final cost = game.rules.totalCost;
      final enhance = find.byKey(const ValueKey('enhance'));
      await tester.ensureVisible(enhance);
      await tester.tap(enhance);
      await tester.pumpAndSettle();
      expect(state.sword.level, 6);
      expect(state.gold, closeTo(500 - cost, 1e-8));
      expect(tester.widget<PixelButton>(option).detail, '223 G');
      await game.saveNow();
      expect(repository.load()!.protection, 3);
      expect(repository.load()!.gold, state.gold);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      game.dispose();
    },
  );
  testWidgets(
    'cheat storage fits mobile; reset popup cancels or clears all progress',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final repository = SaveRepository(await SharedPreferences.getInstance());
      final cheat = SaveRepository.decode(
        File('test/sword_upgrade/fixtures/CHEAT_BACKUP.txt').readAsStringSync(),
      );
      final game = GameController(repository, state: cheat, trackTime: false);
      await tester.pumpWidget(
        MaterialApp(
          theme: swordTheme,
          home: ForgeScreen(controller: game),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('+10 잠금'), findsNWidgets(7));
      expect(find.text('+38 잠금'), findsOneWidget);
      expect(tester.takeException(), isNull);
      for (final confirm in [false, true]) {
        await tester.tap(find.text('설정'));
        await tester.pumpAndSettle();
        final reset = find.byKey(const ValueKey('reset-game'));
        await tester.ensureVisible(reset);
        await tester.tap(reset);
        await tester.pumpAndSettle();
        expect(find.text('게임을 초기화할까요?'), findsOneWidget);
        expect(game.state.gold, 1e100);
        final button = confirm
            ? find.byKey(const ValueKey('confirm-reset'))
            : find.text('취소');
        await tester.tap(button);
        await tester.pumpAndSettle();
        if (!confirm) {
          expect(game.state, same(cheat));
        }
      }
      expect(game.state.toJson(), GameState().toJson());
      expect(repository.load()!.toJson(), GameState().toJson());
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      game.dispose();
    },
  );
  testWidgets(
    'mobile shop upgrades rare discovery to five percent and saves it',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final repository = SaveRepository(await SharedPreferences.getInstance());
      final game = GameController(repository, trackTime: false);
      await tester.pumpWidget(
        MaterialApp(
          theme: swordTheme,
          home: ForgeScreen(controller: game),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('상점'));
      await tester.pumpAndSettle();
      final button = find.byKey(const ValueKey('buy-rare-chance'));
      await tester.ensureVisible(button);
      expect(tester.widget<PixelButton>(button).onPressed, isNull);
      game.state.gold = Balance.rareChancePrices.reduce((a, b) => a + b) + 1000;
      game.notify();
      await tester.pumpAndSettle();
      for (var level = 1; level <= 5; level++) {
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(game.state.rareChanceLevel, level);
        expect(tester.takeException(), isNull);
      }
      expect(find.text('희귀 발견 확률 최대 달성'), findsOneWidget);
      expect(tester.widget<PixelButton>(button).onPressed, isNull);
      expect(tester.getRect(find.byTooltip('닫기')).top, greaterThanOrEqualTo(0));
      await game.saveNow();
      expect(repository.load()?.rareChance, .05);
      await tester.pumpWidget(const SizedBox());
      game.dispose();
    },
  );
  testWidgets(
    'shop buys branch and rare starts and can switch back to free +0',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final repository = SaveRepository(await SharedPreferences.getInstance());
      final game = GameController(
        repository,
        state: GameState()
          ..gold = 1e20
          ..bestLevel = 31
          ..rareFinds = 1
          ..discovered['alexandros'] = 0,
        trackTime: false,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: swordTheme,
          home: ForgeScreen(controller: game),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('상점'));
      await tester.pumpAndSettle();
      for (final level in [11, 21, 31]) {
        final button = find.byKey(ValueKey('buy-start-$level'));
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(game.state.startLevel, level);
        expect(game.state.sword.level, level);
        expect(tester.takeException(), isNull);
      }
      final rare = find.byKey(const ValueKey('buy-rare-start'));
      await tester.ensureVisible(rare);
      await tester.tap(rare);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byTooltip('닫기')).top, greaterThanOrEqualTo(0));
      expect(game.state.startRareId, 'alexandros');
      expect(game.state.sword.rareId, 'alexandros');
      expect(game.state.rareFinds, 1);
      final choice = find.byKey(const ValueKey('start-point'));
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.pumpAndSettle();
      await tester.tap(find.text('일반 검 +0').last);
      await tester.pumpAndSettle();
      expect(game.state.startRareId, isNull);
      expect(game.state.sword.level, 0);
      expect(game.state.sword.isRare, isFalse);
      await game.saveNow();
      expect(repository.load()?.unlockedStartLevel, 31);
      expect(repository.load()?.rareStarts, ['alexandros']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      game.dispose();
    },
  );
  testWidgets('opening shop stops auto and waits for the current animation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final game = GameController(
      SaveRepository(await SharedPreferences.getInstance()),
      state: GameState()..autoTarget = 8,
      roll: () => 0,
      trackTime: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: swordTheme,
        home: ForgeScreen(controller: game),
      ),
    );
    await tester.pumpAndSettle();
    final running = game.startAuto();
    await tester.pump();
    await tester.tap(find.text('상점'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await running;
    expect(game.autoRunning, isFalse);
    expect(game.state.attempts, 1);
    expect(find.text('대장간 상점'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    game.dispose();
  });
  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1440, 900),
  ]) {
    testWidgets('main screen and shop fit ${size.width}×${size.height}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final game = GameController(
        SaveRepository(await SharedPreferences.getInstance()),
        state: GameState(),
        trackTime: false,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: swordTheme,
          home: ForgeScreen(controller: game),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('강화하기'), findsOneWidget);
      if (size.width < 1000) {
        final stage = tester.getRect(find.byType(ForgeStage));
        final button = tester.getRect(find.byKey(const ValueKey('enhance')));
        expect(stage.top, greaterThanOrEqualTo(0));
        expect(button.top, greaterThan(stage.bottom));
        expect(button.bottom, lessThanOrEqualTo(size.height));
      }
      await tester.tap(find.text('상점'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('대장간 상점'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      game.dispose();
    });
  }
}
