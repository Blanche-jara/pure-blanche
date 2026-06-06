import 'package:flutter/foundation.dart';

/// 토너먼트 한 명의 플레이어. 이름은 선택, 칩 스택은 필수.
@immutable
class Player {
  const Player({required this.id, this.name = '', required this.stack});

  /// 안정적 고유키. 리스트 재정렬·동기화에도 보존된다(추후 클라우드 동기화 대비).
  final String id;

  /// 표시 이름(선택). 비어 있으면 UI에서 "P1" 등 인덱스 라벨로 대체.
  final String name;

  /// 칩 스택(0 이상의 정수).
  final int stack;

  Player copyWith({String? name, int? stack}) =>
      Player(id: id, name: name ?? this.name, stack: stack ?? this.stack);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'stack': stack};

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'] as String,
    name: (json['name'] as String?) ?? '',
    stack: (json['stack'] as num).toInt(),
  );

  @override
  bool operator ==(Object other) =>
      other is Player &&
      other.id == id &&
      other.name == name &&
      other.stack == stack;

  @override
  int get hashCode => Object.hash(id, name, stack);

  @override
  String toString() => 'Player($id, "$name", $stack)';
}
