import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pure_blanche/apps/sword_upgrade/data/save_repository.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/models.dart';
import 'package:pure_blanche/apps/sword_upgrade/state/game_controller.dart';
import 'package:pure_blanche/apps/sword_upgrade/sword_upgrade_app.dart';
import 'package:pure_blanche/apps/sword_upgrade/ui/design_tokens.dart';
import 'package:pure_blanche/apps/sword_upgrade/ui/forge_screen.dart';

void main() {
  for (final size in [
    const Size(360, 640),
    const Size(360, 800),
    const Size(1440, 900),
  ]) {
    testWidgets(
      'screenshot guide navigates, enlarges and keeps controls visible at $size',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final game = GameController(
          SaveRepository(await SharedPreferences.getInstance()),
          trackTime: false,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: swordTheme,
            home: ForgeScreen(controller: game),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('game-help')));
        await tester.pumpAndSettle();
        expect(find.text('게임 도움말'), findsOneWidget);
        expect(
          tester
              .widget<PixelButton>(find.byKey(const ValueKey('guide-previous')))
              .onPressed,
          isNull,
        );
        const pages = [
          'probability',
          'protection',
          'storage',
          'rare',
          'shop',
          'auto',
          'save',
        ];
        for (int i = 0; i < pages.length; i++) {
          final id = pages[i];
          expect(find.text('${i + 1} / 7'), findsOneWidget);
          final image = find.descendant(
            of: find.byKey(ValueKey('guide-image-$id')),
            matching: find.byType(Image),
          );
          expect(
            tester.widget<Image>(image).image,
            const TypeMatcher<ExactAssetImage>().having(
              (image) => image.assetName,
              'lossless screenshot',
              'assets/sword_upgrade/guide/$id.png',
            ),
          );
          final next = find.byKey(const ValueKey('guide-next'));
          expect(tester.getRect(next).bottom, lessThanOrEqualTo(size.height));
          expect(
            tester.getRect(find.byTooltip('닫기')).top,
            greaterThanOrEqualTo(0),
          );
          final details = find.byKey(ValueKey('guide-details-$id'));
          await tester.ensureVisible(details);
          await tester.tap(details);
          await tester.pumpAndSettle();
          // Details scroll independently; changing a page resets them and its scroll.
          await tester.drag(
            find.byKey(const ValueKey('guide-body')),
            const Offset(0, -220),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (i < pages.length - 1) {
            await tester.tap(next);
            await tester.pumpAndSettle();
            expect(
              tester
                  .state<ScrollableState>(
                    find.descendant(
                      of: find.byKey(const ValueKey('guide-body')),
                      matching: find.byType(Scrollable),
                    ),
                  )
                  .position
                  .pixels,
              0,
            );
          }
        }
        expect(
          tester
              .widget<PixelButton>(find.byKey(const ValueKey('guide-next')))
              .onPressed,
          isNull,
        );
        // Topic shortcuts work even after reaching and scrolling the last page.
        await tester.tap(find.byKey(const ValueKey('guide-probability')));
        await tester.pumpAndSettle();
        expect(find.text('1 / 7'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('guide-image-probability')));
        await tester.pumpAndSettle();
        expect(find.byType(InteractiveViewer), findsOneWidget);
        expect(
          tester.getRect(find.byTooltip('확대 화면 닫기')).top,
          greaterThanOrEqualTo(0),
        );
        await tester.tap(find.byTooltip('확대 화면 닫기'));
        await tester.pumpAndSettle();
        expect(find.text('게임 도움말'), findsOneWidget);
        await tester.tap(find.byTooltip('닫기'));
        await tester.pumpAndSettle();
        expect(game.state.attempts, 0);
        expect(game.state.gold, 500);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        game.dispose();
      },
    );
  }
  testWidgets('opening help stops auto after its current animation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final game = GameController(
      SaveRepository(await SharedPreferences.getInstance()),
      state: GameState()..autoTarget = 5,
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
    await tester.tap(find.byKey(const ValueKey('game-help')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await running;
    expect(game.autoRunning, isFalse);
    expect(game.state.attempts, 1);
    expect(find.text('게임 도움말'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(game.state.attempts, 1);
    await tester.pumpWidget(const SizedBox());
    game.dispose();
  });
}
