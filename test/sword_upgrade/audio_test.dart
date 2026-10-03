import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pure_blanche/apps/sword_upgrade/audio/forge_audio.dart';
import 'package:pure_blanche/apps/sword_upgrade/data/save_repository.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/models.dart';
import 'package:pure_blanche/apps/sword_upgrade/state/game_controller.dart';

class RecordingAudio extends ForgeAudio {
  final events = <String>[];
  int stops = 0;
  @override
  void hammer({bool quiet = false}) =>
      events.add(quiet ? 'quiet hammer' : 'hammer');
  @override
  void shatter({bool quiet = false}) =>
      events.add(quiet ? 'quiet break' : 'break');
  @override
  void stop() => stops++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<GameController> make(
    RecordingAudio audio, {
    GameState? state,
    double Function()? roll,
  }) async {
    SharedPreferences.setMockInitialValues({});
    return GameController(
      SaveRepository(await SharedPreferences.getInstance()),
      state: state,
      audio: audio,
      roll: roll ?? () => 0,
      trackTime: false,
    );
  }

  testWidgets('manual impact follows the hammer, with no fracture on success', (
    tester,
  ) async {
    final audio = RecordingAudio();
    final game = await make(audio);
    final attempt = game.enhance();
    await tester.pump(const Duration(milliseconds: 161));
    expect(audio.events, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(audio.events, ['hammer']);
    await tester.pump(const Duration(milliseconds: 738));
    await attempt;
    expect(audio.events, ['hammer']);
    game.dispose();
  });

  for (final rareDiscovery in [false, true]) {
    testWidgets(
      'fracture follows impact, including rare discovery=$rareDiscovery',
      (tester) async {
        final audio = RecordingAudio();
        var rolls = 0;
        final game = await make(
          audio,
          roll: () => ++rolls == 1 || !rareDiscovery ? .999 : 0,
        );
        final attempt = game.enhance();
        final total = rareDiscovery ? 1200 : 900;
        final hit = (total * .18).round();
        final fracture = (total * .28).round();
        await tester.pump(Duration(milliseconds: hit));
        expect(audio.events, ['hammer']);
        await tester.pump(Duration(milliseconds: fracture - hit - 1));
        expect(audio.events, ['hammer']);
        await tester.pump(const Duration(milliseconds: 1));
        expect(audio.events, ['hammer', 'break']);
        await tester.pump(Duration(milliseconds: total - fracture));
        await attempt;
        game.dispose();
      },
    );
  }

  testWidgets('rare durability loss sounds only a hit; last heart fractures', (
    tester,
  ) async {
    final audio = RecordingAudio();
    final game = await make(
      audio,
      state: GameState()
        ..gold = 1e9
        ..rareFinds = 1
        ..discovered['alexandros'] = 0
        ..sword = const Sword(rareId: 'alexandros', rareBase: 7690, hearts: 2),
      roll: () => .999,
    );
    var attempt = game.enhance();
    await tester.pump(const Duration(milliseconds: 900));
    await attempt;
    expect(audio.events, ['hammer']);
    expect(game.state.sword.hearts, 1);
    attempt = game.enhance();
    await tester.pump(const Duration(milliseconds: 900));
    await attempt;
    expect(audio.events, ['hammer', 'hammer', 'break']);
    game.dispose();
  });

  testWidgets('fast auto uses quiet impacts and muted setting survives save', (
    tester,
  ) async {
    final audio = RecordingAudio();
    final game = await make(
      audio,
      state: GameState()
        ..shortAnimation = true
        ..autoTarget = 2,
    );
    final running = game.startAuto();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 150));
    await running;
    expect(audio.events, ['quiet hammer', 'quiet hammer']);
    game.setSettings(soundEnabled: false);
    await game.saveNow();
    expect(game.repository.load()?.soundEnabled, isFalse);
    final attempt = game.enhance();
    await tester.pump(const Duration(milliseconds: 400));
    await attempt;
    expect(audio.events, ['quiet hammer', 'quiet hammer']);
    game.dispose();
  });

  testWidgets(
    'mute, hidden page and disposal cancel pending sounds and tails',
    (tester) async {
      for (final action in ['mute', 'hide', 'dispose']) {
        final audio = RecordingAudio();
        final game = await make(audio, roll: () => .999);
        final attempt = game.enhance();
        await tester.pump(const Duration(milliseconds: 162));
        expect(audio.events, ['hammer']);
        switch (action) {
          case 'mute':
            game.setSettings(soundEnabled: false);
          case 'hide':
            game.didChangeAppLifecycleState(AppLifecycleState.hidden);
          case 'dispose':
            game.dispose();
        }
        expect(audio.stops, greaterThan(0));
        await tester.pump(const Duration(milliseconds: 738));
        await attempt;
        expect(audio.events, ['hammer']);
        if (action != 'dispose') game.dispose();
      }
    },
  );
}
