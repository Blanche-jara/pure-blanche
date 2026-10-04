import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pure_blanche/apps/sword_upgrade/data/save_repository.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/models.dart';
import 'package:pure_blanche/apps/sword_upgrade/engine/checkpoints.dart';
import 'package:pure_blanche/apps/sword_upgrade/state/game_controller.dart';
import 'package:pure_blanche/apps/sword_upgrade/ui/design_tokens.dart';

class FailingResetRepository extends SaveRepository {
  bool reject = false;
  FailingResetRepository(super.preferences);
  @override
  Future<void> save(GameState state) =>
      reject ? Future.error(StateError('storage denied')) : super.save(state);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'backup roundtrip includes rare base, storage locks, pity and settings',
    () {
      final state = GameState()
        ..gold = 1.11e17
        ..rareChanceLevel = 4
        ..protection = 3
        ..sword = const Sword(level: 8)
        ..bestLevel = 15
        ..storage = [
          const Sword(
            rareId: 'softshell',
            rareBase: 9000,
            hearts: 2,
            locked: true,
          ),
        ]
        ..discovered['softshell'] = 0
        ..rareFinds = 1
        ..failures[12] = 8
        ..soundEnabled = false
        ..shortAnimation = true;
      expect(
        SaveRepository.decode(SaveRepository.encode(state)).toJson(),
        state.toJson(),
      );
    },
  );
  test('checksum and version reject damaged or unsupported backups', () {
    final code = SaveRepository.encode(GameState());
    final envelope =
        jsonDecode(utf8.decode(base64Url.decode(code.substring(4))))
            as Map<String, dynamic>;
    envelope['payload'] = (envelope['payload'] as String).replaceFirst(
      '500.0',
      '900.0',
    );
    final damaged =
        'SU1.${base64Url.encode(utf8.encode(jsonEncode(envelope)))}';
    expect(() => SaveRepository.decode(damaged), throwsFormatException);
    expect(() => SaveRepository.decode('wrong'), throwsFormatException);
    final unsupported = GameState().toJson()..['schemaVersion'] = 99;
    expect(() => GameState.fromJson(unsupported), throwsFormatException);
  });
  test(
    'strict save validation rejects nonfinite money, wrong levels, hearts and slot counts',
    () {
      for (final corrupt in [
        GameState().toJson()..['gold'] = double.infinity,
        GameState().toJson()..['gold'] = -1,
        GameState().toJson()..['failures'] = [],
        GameState().toJson()..['storage'] = List.filled(6, null),
        GameState().toJson()
          ..['sword'] = (const Sword().toJson()..['level'] = 39),
        GameState().toJson()
          ..['sword'] = const Sword(
            rareId: 'alexandros',
            rareBase: 7690,
            hearts: 0,
          ).toJson(),
      ]) {
        expect(() => GameState.fromJson(corrupt), throwsFormatException);
      }
    },
  );
  test('legacy saves migrate with free +0 and no purchased checkpoints', () {
    final old = GameState().toJson()
      ..['schemaVersion'] = 1
      ..remove('unlockedStartLevel')
      ..remove('startLevel')
      ..remove('rareStarts')
      ..remove('startRareId');
    (old['sword'] as Map<String, Object?>).remove('starterValue');
    final restored = GameState.fromJson(old);
    expect(restored.gold, 500);
    expect(restored.startLevel, 0);
    expect(restored.unlockedStartLevel, 0);
    expect(restored.rareStarts, isEmpty);
    expect(restored.toJson()['schemaVersion'], 4);
  });
  test('old saves default sound on; invalid audio settings are rejected', () {
    for (final version in [1, 2]) {
      final old = GameState().toJson()
        ..['schemaVersion'] = version
        ..remove('soundEnabled');
      expect(GameState.fromJson(old).soundEnabled, isTrue);
    }
    for (final value in [null, 'false', 0]) {
      expect(
        () =>
            GameState.fromJson(GameState().toJson()..['soundEnabled'] = value),
        throwsFormatException,
      );
    }
  });
  test(
    'previous saves default discovery upgrade to zero; invalid levels are rejected',
    () {
      for (final version in [1, 2]) {
        final old = GameState().toJson()
          ..['schemaVersion'] = version
          ..remove('rareChanceLevel');
        expect(GameState.fromJson(old).rareChance, .005);
      }
      final restored = SaveRepository.decode(
        SaveRepository.encode(GameState()..rareChanceLevel = 5),
      );
      expect(restored.rareChanceLevel, 5);
      expect(restored.rareChance, .05);
      for (final invalid in [null, -1, 6, 1.0, '5']) {
        expect(
          () => GameState.fromJson(
            GameState().toJson()..['rareChanceLevel'] = invalid,
          ),
          throwsFormatException,
        );
      }
    },
  );
  test('checkpoint ownership, choice and sword basis survive a backup', () {
    final state = GameState()
      ..bestLevel = 30
      ..unlockedStartLevel = 31
      ..startLevel = 0
      ..rareStarts = ['softshell']
      ..startRareId = 'softshell'
      ..discovered['softshell'] = 1
      ..rareFinds = 1
      ..sword = Sword(
        rareId: 'softshell',
        level: 1,
        rareBase: Checkpoints.rareBase,
        starterValue: Checkpoints.rareBase,
        hearts: 2,
      );
    expect(
      SaveRepository.decode(SaveRepository.encode(state)).toJson(),
      state.toJson(),
    );
    for (final invalid in [
      state.toJson()..['unlockedStartLevel'] = 15,
      state.toJson()..['startLevel'] = 5,
      state.toJson()..['rareStarts'] = [],
      state.toJson()..['rareStarts'] = ['softshell', 'softshell'],
      state.toJson()..['startRareId'] = 'muramasa',
      state.toJson()..['discovered'] = <String, int>{},
      state.toJson()..['bestLevel'] = 20,
      state.toJson()
        ..['sword'] = (state.sword.toJson()..['starterValue'] = 123),
    ]) {
      expect(() => GameState.fromJson(invalid), throwsFormatException);
    }
  });
  test(
    'serialized writes restore latest snapshot and failed import preserves current save',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = SaveRepository(await SharedPreferences.getInstance());
      final state = GameState();
      final first = repository.save(state);
      state.gold = 400;
      final second = repository.save(state);
      await Future.wait([first, second]);
      expect(repository.load()?.gold, 400);
      final controller = GameController(
        repository,
        state: state,
        trackTime: false,
      );
      await expectLater(
        controller.importBackup('broken'),
        throwsFormatException,
      );
      expect(controller.state.gold, 400);
      expect(repository.load()?.gold, 400);
      final imported = GameState()..gold = 1234;
      await controller.importBackup(SaveRepository.encode(imported));
      expect(controller.state.gold, 1234);
      expect(repository.load()?.gold, 1234);
      controller.dispose();
    },
  );
  test('Korean money units retain integer trailing zeroes at high levels', () {
    expect(money(1e6), '100만');
    expect(money(1e7), '1000만');
    expect(money(1.11e17), '11.1경');
    expect(money(1234), '1,234');
    expect(money(1e100), '최대');
  });
  test(
    'legacy selections stay selected; old ticket stock refunds once and preserves progress',
    () {
      for (final version in [1, 2]) {
        final old = GameState().toJson()
          ..['schemaVersion'] = version
          ..['protection'] = 3;
        final restored = GameState.fromJson(old);
        expect(restored.protection, 3);
        expect(restored.gold, 500);
      }
      final old =
          (GameState()
                ..bestLevel = 8
                ..failures[8] = 2
                ..protection = 3
                ..spent = 1000)
              .toJson()
            ..['schemaVersion'] = 2
            ..['protectionTickets'] = [2, 3, 4];
      final restored = GameState.fromJson(old);
      expect(restored.gold, 4559);
      expect(restored.protectionRefund, 4059);
      expect(restored.protection, 3);
      expect(restored.bestLevel, 8);
      expect(restored.failures[8], 2);
      expect(restored.spent, 1000);
      final again = SaveRepository.decode(SaveRepository.encode(restored));
      expect(again.gold, restored.gold);
      expect(again.protectionRefund, 0);
      expect(again.toJson()['schemaVersion'], 4);
      expect(again.toJson().containsKey('protectionTickets'), isFalse);
      for (final invalid in [
        null,
        [],
        [0, 0],
        [0, 0, 0, 0],
        [-1, 0, 0],
        [0, 0, 21],
        [0, 0, 1.0],
      ]) {
        expect(
          () => GameState.fromJson(
            GameState().toJson()
              ..['schemaVersion'] = 2
              ..['protectionTickets'] = invalid,
          ),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'refund saturates at maximum gold and also accepts old cheat backups',
    () {
      final old =
          SaveRepository.decode(
              File('test/sword_upgrade/fixtures/CHEAT_BACKUP.txt').readAsStringSync(),
            ).toJson()
            ..['schemaVersion'] = 2
            ..['unlockedStartLevel'] = 30
            ..['protectionTickets'] = [20, 20, 20];
      final restored = GameState.fromJson(old);
      expect(restored.gold, 1e100);
      expect(restored.protectionRefund, 0);
      expect(restored.storage.length, 8);
      expect(restored.failures.every((n) => n == 10), isTrue);
    },
  );
  test(
    'delivered cheat backup unlocks every feature and contains all max-level weapons',
    () {
      final cheat = SaveRepository.decode(
        File('test/sword_upgrade/fixtures/CHEAT_BACKUP.txt').readAsStringSync(),
      );
      expect(cheat.gold, 1e100);
      expect(cheat.testAccount, isTrue);
      expect(cheat.storage.length, 8);
      expect(
        cheat.storage.whereType<Sword>().where((s) => !s.isRare).single.level,
        38,
      );
      final rares = cheat.storage
          .whereType<Sword>()
          .where((s) => s.isRare)
          .toList();
      expect(rares.length, 7);
      expect(rares.map((s) => s.rareId).toSet().length, 7);
      expect(
        rares.every((s) => s.level == 10 && s.hearts == 3 && s.locked),
        isTrue,
      );
      expect(cheat.negotiation, 5);
      expect(cheat.rareChance, .05);
      expect(cheat.unlockedStartLevel, 31);
      expect(cheat.rareStarts.length, 7);
      expect(cheat.discovered.values.every((level) => level == 10), isTrue);
      expect(cheat.bestLevel, 38);
      expect(cheat.ending, isNotNull);
      expect(cheat.failures.every((n) => n == 10), isTrue);
      expect(
        SaveRepository.decode(SaveRepository.encode(cheat)).toJson(),
        cheat.toJson(),
      );
      final invalid = cheat.toJson()..['testAccount'] = false;
      expect(() => GameState.fromJson(invalid), throwsFormatException);
    },
  );
  test(
    'reset replaces all progress and queued saves with a persistent fresh account',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = SaveRepository(await SharedPreferences.getInstance());
      final cheat = SaveRepository.decode(
        File('test/sword_upgrade/fixtures/CHEAT_BACKUP.txt').readAsStringSync(),
      );
      final controller = GameController(
        repository,
        state: cheat,
        trackTime: false,
      );
      final oldSave = controller.saveNow();
      await controller.resetGame();
      await oldSave;
      expect(controller.state.toJson(), GameState().toJson());
      expect(repository.load()!.toJson(), GameState().toJson());
      expect(controller.rules.state, same(controller.state));
      expect(controller.autoRunning, isFalse);
      expect(controller.outcome, isNull);
      controller.dispose();
    },
  );
  test(
    'failed reset keeps the live account and its previous persisted backup',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = FailingResetRepository(
        await SharedPreferences.getInstance(),
      );
      final state = GameState()
        ..gold = 12345
        ..protection = 3;
      await repository.save(state);
      final controller = GameController(
        repository,
        state: state,
        trackTime: false,
      );
      repository.reject = true;
      await expectLater(controller.resetGame(), throwsStateError);
      expect(controller.state, same(state));
      expect(repository.load()!.toJson(), state.toJson());
      repository.reject = false;
      controller.dispose();
    },
  );
}
