import 'package:flutter/foundation.dart';

import 'payout_structure.dart';
import 'player.dart';

/// 저장 가능한 시나리오(플레이어 + 상금 구조 스냅샷).
///
/// [id]는 안정적 고유키, [updatedAt]은 정렬·동기화용. 추후 클라우드 동기화 대비. (Handoff 8장)
@immutable
class Scenario {
  const Scenario({
    required this.id,
    required this.title,
    required this.players,
    required this.payout,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final List<Player> players;
  final PayoutStructure payout;
  final DateTime updatedAt;

  Scenario copyWith({
    String? title,
    List<Player>? players,
    PayoutStructure? payout,
    DateTime? updatedAt,
  }) => Scenario(
    id: id,
    title: title ?? this.title,
    players: players ?? this.players,
    payout: payout ?? this.payout,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'players': players.map((p) => p.toJson()).toList(),
    'payout': payout.toJson(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Scenario.fromJson(Map<String, dynamic> json) => Scenario(
    id: json['id'] as String,
    title: (json['title'] as String?) ?? '',
    players: (json['players'] as List<dynamic>)
        .map((e) => Player.fromJson(e as Map<String, dynamic>))
        .toList(),
    payout: PayoutStructure.fromJson(json['payout'] as Map<String, dynamic>),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  @override
  bool operator ==(Object other) =>
      other is Scenario &&
      other.id == id &&
      other.title == title &&
      listEquals(other.players, players) &&
      other.payout == payout &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      Object.hash(id, title, Object.hashAll(players), payout, updatedAt);
}
