import 'blind_level.dart';
import 'break_level.dart';

class TournamentStructure {
  final String name;
  final List<dynamic> levels; // BlindLevel or BreakLevel
  final bool isCashGame;

  const TournamentStructure({
    required this.name,
    required this.levels,
    this.isCashGame = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'isCashGame': isCashGame,
        'levels': levels.map((l) {
          if (l is BlindLevel) return l.toJson();
          if (l is BreakLevel) return l.toJson();
          return {};
        }).toList(),
      };

  factory TournamentStructure.fromJson(Map<String, dynamic> json) {
    final levelsList = (json['levels'] as List).map((l) {
      final map = l as Map<String, dynamic>;
      if (map['type'] == 'break') return BreakLevel.fromJson(map);
      return BlindLevel.fromJson(map);
    }).toList();

    return TournamentStructure(
      name: json['name'] as String,
      levels: levelsList,
      isCashGame: json['isCashGame'] as bool? ?? false,
    );
  }

  TournamentStructure copyWith({
    String? name,
    List<dynamic>? levels,
    bool? isCashGame,
  }) =>
      TournamentStructure(
        name: name ?? this.name,
        levels: levels ?? this.levels,
        isCashGame: isCashGame ?? this.isCashGame,
      );

  /// Returns the blind level number for display (skipping breaks)
  int getBlindLevelNumber(int index) {
    int blindCount = 0;
    for (int i = 0; i <= index && i < levels.length; i++) {
      if (levels[i] is BlindLevel) blindCount++;
    }
    return blindCount;
  }
}
