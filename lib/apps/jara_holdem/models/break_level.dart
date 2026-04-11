class BreakLevel {
  final int durationMinutes;
  final bool colorUp;

  const BreakLevel({
    this.durationMinutes = 10,
    this.colorUp = false,
  });

  int get durationSeconds => durationMinutes * 60;

  Map<String, dynamic> toJson() => {
        'type': 'break',
        'durationMinutes': durationMinutes,
        'colorUp': colorUp,
      };

  factory BreakLevel.fromJson(Map<String, dynamic> json) => BreakLevel(
        durationMinutes: json['durationMinutes'] as int? ?? 10,
        colorUp: json['colorUp'] as bool? ?? false,
      );

  BreakLevel copyWith({
    int? durationMinutes,
    bool? colorUp,
  }) =>
      BreakLevel(
        durationMinutes: durationMinutes ?? this.durationMinutes,
        colorUp: colorUp ?? this.colorUp,
      );
}
