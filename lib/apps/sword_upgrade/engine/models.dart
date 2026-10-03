import 'dart:math';
import 'balance.dart';
import 'checkpoints.dart';
import 'rare.dart';

class Sword {
  final int level;
  final String? rareId;
  final int hearts;
  final double rareBase;
  final bool locked;
  final double starterValue;
  const Sword({
    this.level = 0,
    this.rareId,
    this.hearts = 3,
    this.rareBase = 0,
    this.locked = false,
    this.starterValue = 0,
  });
  bool get isRare => rareId != null;
  int get maximum => isRare ? Balance.rareMaxLevel : Balance.maxLevel;
  String get name => isRare
      ? rareWeapons.firstWhere((weapon) => weapon.id == rareId).name
      : Balance.normalNames[level];
  bool get canSell =>
      value > starterValue && (isRare || level < Balance.maxLevel);
  bool get canStore => value > starterValue;
  double get value => isRare
      ? rareBase * Balance.rareMultipliers[level]
      : Balance.salePrices[level];
  String image({bool thumbnail = false}) =>
      'assets/sword_upgrade/${thumbnail ? 'thumbnails' : 'weapons'}/${isRare ? 'rare/$rareId' : 'normal/${level.toString().padLeft(2, '0')}'}.png';
  Sword copyWith({int? level, int? hearts, bool? locked}) => Sword(
    level: level ?? this.level,
    rareId: rareId,
    hearts: hearts ?? this.hearts,
    rareBase: rareBase,
    locked: locked ?? this.locked,
    starterValue: starterValue,
  );
  Map<String, Object?> toJson() => {
    'level': level,
    'rareId': rareId,
    'hearts': hearts,
    'rareBase': rareBase,
    'locked': locked,
    'starterValue': starterValue,
  };
  factory Sword.fromJson(Object? source) {
    final json = checkedMap(source);
    final rareId = json['rareId'];
    if (rareId != null && !rareWeapons.any((weapon) => weapon.id == rareId)) {
      throw const FormatException('알 수 없는 희귀 무기입니다.');
    }
    final level = checkedInt(
      json['level'],
      0,
      rareId == null ? Balance.maxLevel : Balance.rareMaxLevel,
    );
    final hearts = checkedInt(json['hearts'], 1, 3);
    final base = checkedMoney(json['rareBase']);
    final starterValue = checkedMoney(json['starterValue'] ?? 0);
    if ((rareId != null && base < Balance.salePrices[10]) ||
        (rareId == null && (base != 0 || hearts != 3))) {
      throw const FormatException('검 정보가 올바르지 않습니다.');
    }
    final value = rareId == null
        ? Balance.salePrices[level]
        : base * Balance.rareMultipliers[level];
    if (starterValue > value ||
        (starterValue != 0 &&
            (rareId == null
                ? !Checkpoints.normalLevels.any(
                    (n) => n <= level && Balance.salePrices[n] == starterValue,
                  )
                : starterValue != base || base != Checkpoints.rareBase))) {
      throw const FormatException('시작 검의 가치가 올바르지 않습니다.');
    }
    return Sword(
      level: level,
      rareId: rareId as String?,
      hearts: hearts,
      rareBase: base,
      locked: checkedBool(json['locked']),
      starterValue: starterValue,
    );
  }
}

class GameState {
  double gold = Balance.startGold;
  Sword sword = const Sword();
  List<Sword?> storage = [];
  int negotiation = 0;
  int rareChanceLevel = 0;
  int protection = 0;
  // Transient migration notice; the next save contains the refunded gold only.
  double protectionRefund = 0;
  // The supplied cheat backup has room for all seven rares and the ending sword.
  bool testAccount = false;
  List<int> failures = List.filled(Balance.maxLevel, 0);
  int attempts = 0;
  int destructions = 0;
  int bestLevel = 0;
  int rareFinds = 0;
  double spent = 0;
  int playSeconds = 0;
  Map<String, int> discovered = {};
  Map<String, Object?>? ending;
  bool shortAnimation = false;
  bool confirmHigh = true;
  bool soundEnabled = true;
  int autoTarget = 5;
  int unlockedStartLevel = 0;
  int startLevel = 0;
  List<String> rareStarts = [];
  String? startRareId;
  double get fee => Balance.fees[negotiation];
  double get rareChance => Balance.rareChanceLevels[rareChanceLevel];
  int get maxStorageSlots =>
      testAccount ? rareWeapons.length + 1 : Balance.slotPrices.length;
  Map<String, Object?> toJson() => {
    'schemaVersion': 3,
    'balanceVersion': Balance.version,
    'gold': gold,
    'sword': sword.toJson(),
    'storage': storage.map((s) => s?.toJson()).toList(),
    'negotiation': negotiation,
    'rareChanceLevel': rareChanceLevel,
    'protection': protection,
    'testAccount': testAccount,
    'failures': failures,
    'attempts': attempts,
    'destructions': destructions,
    'bestLevel': bestLevel,
    'rareFinds': rareFinds,
    'spent': spent,
    'playSeconds': playSeconds,
    'discovered': discovered,
    'ending': ending,
    'shortAnimation': shortAnimation,
    'confirmHigh': confirmHigh,
    'soundEnabled': soundEnabled,
    'autoTarget': autoTarget,
    'unlockedStartLevel': unlockedStartLevel,
    'startLevel': startLevel,
    'rareStarts': rareStarts,
    'startRareId': startRareId,
  };
  factory GameState.fromJson(Object? source) {
    final j = checkedMap(source);
    final schemaVersion = checkedInt(j['schemaVersion'], 1, 3);
    final legacy = schemaVersion == 1;
    if (j['balanceVersion'] != Balance.version) {
      throw const FormatException('지원하지 않는 저장 버전입니다.');
    }
    final storage = j['storage'];
    final failures = j['failures'];
    final testAccount = j.containsKey('testAccount')
        ? checkedBool(j['testAccount'])
        : false;
    if (storage is! List ||
        storage.length >
            (testAccount
                ? rareWeapons.length + 1
                : Balance.slotPrices.length) ||
        failures is! List ||
        failures.length != Balance.maxLevel) {
      throw const FormatException('보관함 또는 강화 기록이 올바르지 않습니다.');
    }
    final state = GameState()
      ..gold = checkedMoney(j['gold'])
      ..sword = Sword.fromJson(j['sword'])
      ..storage = storage
          .map((s) => s == null ? null : Sword.fromJson(s))
          .toList()
      ..negotiation = checkedInt(j['negotiation'], 0, 5)
      ..rareChanceLevel = j.containsKey('rareChanceLevel')
          ? checkedInt(j['rareChanceLevel'], 0, Balance.rareChancePrices.length)
          : 0
      ..protection = checkedInt(j['protection'], 0, 3)
      ..testAccount = testAccount
      ..failures = failures.map((f) => checkedInt(f, 0, 1000000000)).toList()
      ..attempts = checkedInt(j['attempts'], 0, 1000000000)
      ..destructions = checkedInt(j['destructions'], 0, 1000000000)
      ..bestLevel = checkedInt(j['bestLevel'], 0, Balance.maxLevel)
      ..rareFinds = checkedInt(j['rareFinds'], 0, 1000000000)
      ..spent = checkedMoney(j['spent'])
      ..playSeconds = checkedInt(j['playSeconds'], 0, 1000000000)
      ..shortAnimation = checkedBool(j['shortAnimation'])
      ..confirmHigh = checkedBool(j['confirmHigh'])
      ..soundEnabled = j.containsKey('soundEnabled')
          ? checkedBool(j['soundEnabled'])
          : true
      ..autoTarget = checkedInt(j['autoTarget'], 1, Balance.maxLevel);
    var ticketRefund = 0.0;
    if (schemaVersion < 3 && j.containsKey('protectionTickets')) {
      final tickets = j['protectionTickets'];
      if (tickets is! List || tickets.length != 3) {
        throw const FormatException('보호권 보유 수량이 올바르지 않습니다.');
      }
      final priceLevel = state.bestLevel.clamp(1, Balance.maxLevel - 1);
      for (var option = 1; option <= 3; option++) {
        final count = checkedInt(tickets[option - 1], 0, 20);
        ticketRefund +=
            count *
            max(1, Balance.protectionCost(priceLevel, option).roundToDouble());
      }
    }
    if (!legacy) {
      state.unlockedStartLevel = checkedInt(j['unlockedStartLevel'], 0, 30);
      state.startLevel = checkedInt(j['startLevel'], 0, 30);
      final starts = j['rareStarts'];
      if (starts is! List ||
          starts.length > rareWeapons.length ||
          starts.any((id) => !rareWeapons.any((w) => w.id == id)) ||
          starts.toSet().length != starts.length ||
          (j['startRareId'] != null && !starts.contains(j['startRareId']))) {
        throw const FormatException('희귀 시작점이 올바르지 않습니다.');
      }
      state.rareStarts = starts.cast<String>().toList();
      state.startRareId = j['startRareId'] as String?;
      if (!Checkpoints.isNormalLevel(state.unlockedStartLevel) ||
          !Checkpoints.isNormalLevel(state.startLevel) ||
          state.startLevel > state.unlockedStartLevel ||
          state.unlockedStartLevel > state.bestLevel) {
        throw const FormatException('구매하지 않은 시작점입니다.');
      }
    }
    final found = checkedMap(j['discovered']);
    for (final entry in found.entries) {
      if (!rareWeapons.any((weapon) => weapon.id == entry.key)) {
        throw const FormatException('알 수 없는 도감 기록입니다.');
      }
      state.discovered[entry.key] = checkedInt(
        entry.value,
        0,
        Balance.rareMaxLevel,
      );
    }
    if (j['ending'] != null) {
      final ending = checkedMap(j['ending']);
      state.ending = {
        'attempts': checkedInt(ending['attempts'], 0, state.attempts),
        'destructions': checkedInt(
          ending['destructions'],
          0,
          state.destructions,
        ),
        'playSeconds': checkedInt(ending['playSeconds'], 0, state.playSeconds),
        'rareFinds': checkedInt(ending['rareFinds'], 0, state.rareFinds),
        'spent': checkedMoney(ending['spent']),
      };
      if (state.bestLevel != Balance.maxLevel) {
        throw const FormatException('엔딩 기록이 올바르지 않습니다.');
      }
    }
    final swords = [state.sword, ...state.storage.whereType<Sword>()];
    if (swords.any((s) => !s.isRare && s.level > state.bestLevel) ||
        swords.any(
          (s) =>
              s.isRare &&
              (!state.discovered.containsKey(s.rareId) ||
                  state.discovered[s.rareId]! < s.level),
        ) ||
        state.destructions > state.attempts ||
        state.rareFinds < state.discovered.length ||
        (state.bestLevel == Balance.maxLevel && state.ending == null) ||
        state.rareStarts.any((id) => !state.discovered.containsKey(id)) ||
        swords.any(
          (s) =>
              s.starterValue > 0 &&
              (s.isRare
                  ? !state.rareStarts.contains(s.rareId)
                  : s.starterValue >
                        Balance.salePrices[state.unlockedStartLevel]),
        ) ||
        state.storage.whereType<Sword>().any((s) => !s.canStore)) {
      throw const FormatException('저장 데이터의 기록이 일치하지 않습니다.');
    }
    final refundedGold = min(Balance.maxGold, state.gold + ticketRefund);
    state.protectionRefund = refundedGold - state.gold;
    state.gold = refundedGold;
    return state;
  }
  GameState();
}

Map<String, dynamic> checkedMap(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('저장 형식이 올바르지 않습니다.');
  }
  return value;
}

int checkedInt(Object? value, int min, int max) {
  if (value is! int || value < min || value > max) {
    throw const FormatException('저장 수치가 허용 범위를 벗어났습니다.');
  }
  return value;
}

double checkedMoney(Object? value) {
  if (value is! num ||
      !value.isFinite ||
      value < 0 ||
      value > Balance.maxGold) {
    throw const FormatException('저장 금액이 올바르지 않습니다.');
  }
  return value.toDouble();
}

bool checkedBool(Object? value) {
  if (value is! bool) throw const FormatException('설정 형식이 올바르지 않습니다.');
  return value;
}
