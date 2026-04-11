class BlindLevel {
  final int level;
  final int smallBlind;
  final int bigBlind;
  final int ante;
  final int durationMinutes;

  const BlindLevel({
    required this.level,
    required this.smallBlind,
    required this.bigBlind,
    this.ante = 0,
    this.durationMinutes = 15,
  });

  int get durationSeconds => durationMinutes * 60;

  Map<String, dynamic> toJson() => {
        'type': 'blind',
        'level': level,
        'smallBlind': smallBlind,
        'bigBlind': bigBlind,
        'ante': ante,
        'durationMinutes': durationMinutes,
      };

  factory BlindLevel.fromJson(Map<String, dynamic> json) => BlindLevel(
        level: json['level'] as int,
        smallBlind: json['smallBlind'] as int,
        bigBlind: json['bigBlind'] as int,
        ante: json['ante'] as int? ?? 0,
        durationMinutes: json['durationMinutes'] as int? ?? 15,
      );

  BlindLevel copyWith({
    int? level,
    int? smallBlind,
    int? bigBlind,
    int? ante,
    int? durationMinutes,
  }) =>
      BlindLevel(
        level: level ?? this.level,
        smallBlind: smallBlind ?? this.smallBlind,
        bigBlind: bigBlind ?? this.bigBlind,
        ante: ante ?? this.ante,
        durationMinutes: durationMinutes ?? this.durationMinutes,
      );
}
