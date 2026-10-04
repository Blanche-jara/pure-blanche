import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pure_blanche/apps/sword_upgrade/audio/forge_audio.dart';
import 'package:pure_blanche/apps/sword_upgrade/data/save_repository.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/balance.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/checkpoints.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/models.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/rules.dart';
import 'package:pure_blanche/apps/sword_upgrade/state/game_controller.dart';
import 'package:pure_blanche/apps/sword_upgrade/sword_upgrade_app.dart';
import 'package:pure_blanche/apps/sword_upgrade/ui/forge_screen.dart';

class MusicProbe extends ForgeAudio {
  bool playing = false;
  int hits = 0;
  int unlocks = 0;
  @override
  void setMusic({required bool playing}) => this.playing = playing;
  @override
  void unlock() => unlocks++;
  @override
  void hammer({bool quiet = false}) => hits++;
  @override
  void shatter({bool quiet = false}) {}
  @override
  void stop() => playing = false;
}

String oldCode(int start, {int version = 3}) => File(
  'test/sword_upgrade/fixtures/live_v${version}_start_$start.txt',
).readAsStringSync();
Map<String, dynamic> oldJson(int start, {int version = 3}) =>
    jsonDecode(
          (jsonDecode(
                    utf8.decode(
                      base64Url.decode(
                        oldCode(start, version: version).trim().substring(4),
                      ),
                    ),
                  )
                  as Map<String, dynamic>)['payload']
              as String,
        )
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final version in [2, 3, 4]) {
    for (final start in [10, 20, 30]) {
      test(
        'schema $version +$start purchase migrates without altering progress',
        () {
          final original = version == 4
              ? oldJson(start + 1, version: 4)
              : (oldJson(start)..['schemaVersion'] = version);
          final state = version == 4
              ? SaveRepository.decode(oldCode(start + 1, version: 4))
              : version == 3
              ? SaveRepository.decode(oldCode(start))
              : GameState.fromJson(original);
          final expected = Map<String, dynamic>.of(original)
            ..['schemaVersion'] = 5
            ..['startLevel'] = start
            ..['unlockedStartLevel'] = start
            ..['musicEnabled'] = false
            ..['audioMuted'] = false;
          expect(state.toJson(), expected);
          expect(state.bestLevel, start);
          expect(state.sword.toJson(), original['sword']);
          expect(state.storage[0]!.locked, isTrue);
          expect(state.storage[1]!.hearts, 2);
          expect(
            SaveRepository.decode(SaveRepository.encode(state)).toJson(),
            expected,
          );
          final rules = GameRules(state);
          expect(
            Checkpoints.normalPrice(start),
            Balance.salePrices[start] * 100,
          );
          // An old, unused starter is replaced only when the player chooses it.
          rules.selectStart(level: start);
          expect(state.sword.level, start);
          expect(state.bestLevel, start);
          expect(rules.gate, isNull);
          expect(rules.startMaterialsExempt, isTrue);
          expect(state.sword.canSell, isFalse);
          expect(state.sword.canStore, isFalse);
          expect(
            SaveRepository.decode(SaveRepository.encode(state)).bestLevel,
            start,
          );
        },
      );
    }
  }
  test('an enhanced old starter and its stored basis survive migration', () {
    final original = oldJson(30);
    (original['sword'] as Map<String, dynamic>)['starterValue'] =
        Balance.salePrices[20];
    original['storage'][0] = const Sword(
      level: 21,
      starterValue: 51600000,
    ).toJson();
    (original['storage'][0] as Map<String, Object?>)['starterValue'] =
        Balance.salePrices[20];
    final state = GameState.fromJson(original);
    expect(state.sword.toJson(), original['sword']);
    expect(state.storage[0]!.toJson(), original['storage'][0]);
    GameRules(state).selectStart(level: 30);
    expect(state.sword.level, 30);
    expect(state.sword.starterValue, Balance.salePrices[20]);
  });
  test(
    'schema 1 with no checkpoints and old mute preference remains valid',
    () {
      final old = oldJson(10)
        ..['schemaVersion'] = 1
        ..remove('startLevel')
        ..remove('unlockedStartLevel')
        ..remove('rareStarts')
        ..remove('startRareId');
      (old['sword'] as Map<String, dynamic>).remove('starterValue');
      final state = GameState.fromJson(old);
      expect(state.startLevel, 0);
      expect(state.unlockedStartLevel, 0);
      expect(state.musicEnabled, isFalse);
      expect(state.soundEnabled, isFalse);
      expect(state.gold, 9876543210);
    },
  );
  test(
    'loading preserves the original code before any save and does not overwrite backup',
    () async {
      final raw = oldCode(10);
      SharedPreferences.setMockInitialValues({SaveRepository.key: raw});
      final prefs = await SharedPreferences.getInstance();
      final game = await GameController.load(SaveRepository(prefs));
      expect(prefs.getString(SaveRepository.preUpgradeKey), raw);
      expect(prefs.getString(SaveRepository.key), raw);
      await game.saveNow();
      expect(game.repository.load()!.startLevel, 10);
      expect(game.repository.load()!.gold, 9876543210);
      game.dispose();
      final reopened = await GameController.load(SaveRepository(prefs));
      await reopened.saveNow();
      expect(prefs.getString(SaveRepository.preUpgradeKey), raw);
      expect(reopened.state.checkpointMigrated, isFalse);
      reopened.dispose();
    },
  );
  test(
    'schema 4 is preferred and copied intact before saving; older tabs cannot overwrite schema 5',
    () async {
      final raw = oldCode(21, version: 4);
      SharedPreferences.setMockInitialValues({
        SaveRepository.previousKey: raw,
        SaveRepository.key: oldCode(10),
      });
      final prefs = await SharedPreferences.getInstance();
      final game = await GameController.load(SaveRepository(prefs));
      expect(game.state.startLevel, 20);
      expect(game.state.sword.level, 21);
      expect(game.state.bestLevel, 20);
      expect(game.state.sword.starterValue, Balance.salePrices[21]);
      expect(prefs.getString(SaveRepository.preUpgradeKey), raw);
      game.state.gold = 4444;
      await game.saveNow();
      expect(prefs.getString(SaveRepository.previousKey), raw);
      await prefs.setString(
        SaveRepository.previousKey,
        oldCode(11, version: 4),
      );
      await prefs.setString(SaveRepository.key, oldCode(30));
      expect(game.repository.load()!.gold, 4444);
      expect(game.repository.load()!.startLevel, 20);
      expect(game.repository.load()!.sword.level, 21);
      expect(prefs.getString(SaveRepository.preUpgradeKey), raw);
      game.dispose();
    },
  );
  test(
    'enhanced schema-4 swords keep their higher basis and exact sale value',
    () {
      final original = oldJson(21, version: 4);
      (original['sword'] as Map<String, dynamic>)['level'] = 22;
      original['bestLevel'] = 22;
      original['storage'][0] = Map<String, dynamic>.of(original['sword']);
      final state = GameState.fromJson(original);
      expect(state.sword.toJson(), original['sword']);
      expect(state.storage[0]!.toJson(), original['storage'][0]);
      expect(state.gold, original['gold']);
      expect(state.bestLevel, 22);
      expect(
        GameRules(state).saleNet(state.sword),
        (Balance.salePrices[22] - Balance.salePrices[21]) * .9,
      );
      expect(
        SaveRepository.decode(SaveRepository.encode(state)).toJson(),
        state.toJson(),
      );
    },
  );
  test(
    'unreadable saves fail without creating a new game or overwriting the original',
    () async {
      SharedPreferences.setMockInitialValues({
        SaveRepository.key: 'broken original',
      });
      final prefs = await SharedPreferences.getInstance();
      await expectLater(
        GameController.load(SaveRepository(prefs)),
        throwsFormatException,
      );
      expect(prefs.getString(SaveRepository.key), 'broken original');
      expect(
        prefs.getString('${SaveRepository.key}.recovery'),
        'broken original',
      );
    },
  );
  test('a damaged newer save never rolls back to a stale older save', () async {
    SharedPreferences.setMockInitialValues({
      SaveRepository.previousKey: 'broken schema-4 original',
      SaveRepository.key: oldCode(10),
    });
    final prefs = await SharedPreferences.getInstance();
    await expectLater(
      GameController.load(SaveRepository(prefs)),
      throwsFormatException,
    );
    expect(
      prefs.getString(SaveRepository.previousKey),
      'broken schema-4 original',
    );
    expect(
      prefs.getString('${SaveRepository.previousKey}.recovery'),
      'broken schema-4 original',
    );
    expect(prefs.getString(SaveRepository.currentKey), isNull);
  });
  test(
    'an old tab cannot overwrite the updated progress or read a new schema',
    () async {
      final raw = oldCode(20);
      SharedPreferences.setMockInitialValues({SaveRepository.key: raw});
      final prefs = await SharedPreferences.getInstance();
      final repository = SaveRepository(prefs);
      final migrated = repository.load()!..gold = 4444;
      await repository.save(migrated);
      expect(prefs.getString(SaveRepository.key), raw);
      expect(prefs.getString(SaveRepository.currentKey), isNotNull);
      // Simulate a still-running old client writing a shipped schema-3 code.
      await prefs.setString(SaveRepository.key, oldCode(10));
      expect(repository.load()!.gold, 4444);
      expect(repository.load()!.startLevel, 20);
      await repository.save(GameState());
      expect(repository.load()!.gold, 500);
      expect(repository.load()!.startLevel, 0);
    },
  );
  testWidgets(
    'music, effects and master mute persist independently; hidden tabs pause',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final audio = MusicProbe();
      final game = GameController(
        SaveRepository(await SharedPreferences.getInstance()),
        audio: audio,
        trackTime: false,
        roll: () => 0,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: swordTheme,
          home: ForgeScreen(controller: game),
        ),
      );
      await tester.pumpAndSettle();
      expect(audio.playing, isTrue);
      await tester.tap(find.byKey(const ValueKey('game-mute')));
      await tester.pumpAndSettle();
      expect(audio.playing, isFalse);
      await game.saveNow();
      expect(game.repository.load()!.audioMuted, isTrue);
      await tester.tap(find.byKey(const ValueKey('game-mute')));
      await tester.pumpAndSettle();
      expect(audio.playing, isTrue);
      expect(audio.unlocks, greaterThan(0));
      game.setSettings(soundEnabled: false);
      expect(audio.playing, isTrue);
      final attempt = game.enhance();
      await tester.pump(const Duration(milliseconds: 900));
      await attempt;
      expect(audio.hits, 0);
      game.didChangeAppLifecycleState(AppLifecycleState.hidden);
      expect(audio.playing, isFalse);
      game.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(audio.playing, isTrue);
      game.setSettings(musicEnabled: false);
      expect(audio.playing, isFalse);
      await game.saveNow();
      final restored = game.repository.load()!;
      expect(restored.soundEnabled, isFalse);
      expect(restored.musicEnabled, isFalse);
      expect(restored.audioMuted, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      game.dispose();
    },
  );
}
