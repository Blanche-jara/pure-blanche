import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pure_blanche/apps/app_wrapper.dart';
import 'package:pure_blanche/apps/sword_upgrade/data/save_repository.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/models.dart';
import 'package:pure_blanche/apps/sword_upgrade/state/game_controller.dart';
import 'package:pure_blanche/apps/sword_upgrade/sword_upgrade_app.dart';
import 'package:pure_blanche/apps/sword_upgrade/ui/forge_screen.dart';

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
    const Size(430, 932),
    const Size(844, 390),
  ]) {
    testWidgets('hub bar, rich save and game dialogs fit $size', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      SharedPreferences.setMockInitialValues({});
      final repository = SaveRepository(await SharedPreferences.getInstance());
      final state = SaveRepository.decode(
        File('test/sword_upgrade/fixtures/CHEAT_BACKUP.txt').readAsStringSync(),
      )..sword = const Sword(level: 5);
      final game = GameController(
        repository,
        state: state,
        roll: () => 0,
        trackTime: false,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: SafeArea(
            child: AppWrapper(
              title: 'SWORD +38',
              child: Theme(
                data: swordTheme,
                child: ForgeScreen(controller: game),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.byIcon(Icons.arrow_back)).top,
        greaterThan(24),
      );
      final enhance = find.byKey(const ValueKey('enhance'));
      await tester.ensureVisible(enhance);
      await tester.tap(enhance);
      await tester.pumpAndSettle();
      expect(state.sword.level, 6);
      expect(tester.takeException(), isNull);

      // Dialogs use the root Navigator, keeping the pixel theme after embedding.
      for (final entry in ['상점', '도감', '기록', '설정', '?']) {
        final button = entry == '?'
            ? find.byKey(const ValueKey('game-help'))
            : find.text(entry);
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$entry at $size');
        final close = find.byTooltip('닫기');
        final rect = tester.getRect(close);
        expect(rect.top, greaterThanOrEqualTo(24));
        expect(rect.bottom, lessThanOrEqualTo(size.height - 20));
        if (entry == '?') {
          final next = find.byKey(const ValueKey('guide-next'));
          for (var page = 1; page <= 7; page++) {
            expect(find.text('$page / 7'), findsOneWidget);
            expect(
              tester.getRect(next).bottom,
              lessThanOrEqualTo(size.height - 20),
            );
            if (page < 7) {
              await tester.tap(next);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
          }
        }
        await tester.tap(close);
        await tester.pumpAndSettle();
      }
      if (size == const Size(360, 640)) {
        final settings = find.text('설정');
        await tester.ensureVisible(settings);
        await tester.tap(settings);
        await tester.pumpAndSettle();
        final import = find.text('백업 코드 가져오기');
        await tester.ensureVisible(import);
        await tester.tap(import);
        await tester.pumpAndSettle();
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('가져오기'));
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.text('가져오기')).bottom,
          lessThanOrEqualTo(size.height - 280),
        );
        await tester.tap(find.byTooltip('닫기'));
        await tester.pumpAndSettle();
        tester.view.resetViewInsets();
      }
      await game.saveNow();
      expect(repository.load()!.sword.level, 6);
      await tester.pumpWidget(const SizedBox());
      game.dispose();
    });
  }
}
