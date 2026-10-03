import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/models.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/rules.dart';
import 'package:pure_blanche/apps/sword_upgrade/ui/widgets/forge_stage.dart';

void main() {
  for (final kind in OutcomeKind.values) {
    testWidgets('first $kind effect is decoded, large, and keeps its result', (
      tester,
    ) async {
      const before = Sword(level: 5);
      final after = kind == OutcomeKind.destroyed
          ? const Sword()
          : kind == OutcomeKind.rareFound
          ? const Sword(rareId: 'alexandros', rareBase: 7690)
          : const Sword(level: 6);
      Widget stage({Outcome? outcome, int sequence = 0}) => MaterialApp(
        home: Center(
          child: SizedBox(
            width: 320,
            child: ForgeStage(
              sword: outcome == null ? before : after,
              sequence: sequence,
              duration: const Duration(milliseconds: 900),
              outcome: outcome,
            ),
          ),
        ),
      );
      await tester.pumpWidget(stage());
      // The forge opens before any attempt. Unused sheets must also be ready.
      await tester.runAsync(() async {
        final context = tester.element(find.byType(ForgeStage));
        await Future.wait(
          forgeEffectAssets.map(
            (path) => precacheImage(AssetImage(path), context),
          ),
        );
      });
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('forge-result-label')), findsNothing);
      await tester.pumpWidget(
        stage(outcome: Outcome(kind, before, 'result'), sequence: 1),
      );
      await tester.pump(const Duration(milliseconds: 220));
      final strike = tester.widget<SpriteEffect>(
        find.byKey(const ValueKey('forge-strike')),
      );
      final fxFinder = find.byKey(const ValueKey('forge-result-effect'));
      final effect = tester.widget<SpriteEffect>(fxFinder);
      expect(strike.sheet, isNotNull);
      expect(effect.sheet, isNotNull);
      expect(tester.getSize(fxFinder).width, greaterThan(128));
      expect(find.byKey(const ValueKey('forge-result-label')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(fxFinder, findsNothing);
      expect(find.byKey(const ValueKey('forge-result-label')), findsOneWidget);
      // Selling or changing swords clears the previous result without replaying.
      await tester.pumpWidget(stage(sequence: 1));
      expect(find.byKey(const ValueKey('forge-result-label')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('rare durability loss is distinguished from protection', (
    tester,
  ) async {
    const before = Sword(rareId: 'alexandros', rareBase: 7690);
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 320,
          child: ForgeStage(
            sword: Sword(rareId: 'alexandros', rareBase: 7690, hearts: 2),
            sequence: 1,
            duration: Duration(milliseconds: 900),
            outcome: Outcome(OutcomeKind.protected, before, 'durability'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('강화 실패 · 내구도 −1'), findsOneWidget);
    expect(find.text('보호 발동 · 검 유지'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
