import '../models/blind_level.dart';
import '../models/break_level.dart';
import '../models/tournament_structure.dart';

// Preset 1: Classic Jara Tournament
final classicTournament = TournamentStructure(
  name: 'Classic Jara Tournament',
  levels: [
    const BlindLevel(level: 1, smallBlind: 100, bigBlind: 200, ante: 0, durationMinutes: 15),
    const BlindLevel(level: 2, smallBlind: 200, bigBlind: 300, ante: 0, durationMinutes: 15),
    const BlindLevel(level: 3, smallBlind: 200, bigBlind: 400, ante: 0, durationMinutes: 15),
    const BlindLevel(level: 4, smallBlind: 300, bigBlind: 600, ante: 0, durationMinutes: 15),
    const BreakLevel(durationMinutes: 10),
    const BlindLevel(level: 5, smallBlind: 500, bigBlind: 1000, ante: 1000, durationMinutes: 10),
    const BlindLevel(level: 6, smallBlind: 1000, bigBlind: 1500, ante: 1500, durationMinutes: 10),
    const BlindLevel(level: 7, smallBlind: 1000, bigBlind: 2000, ante: 2000, durationMinutes: 10),
    const BreakLevel(durationMinutes: 10),
    const BlindLevel(level: 8, smallBlind: 2000, bigBlind: 3000, ante: 3000, durationMinutes: 10),
  ],
);

// Preset 2: Classic Jara Cash (infinite time, single level, no add/delete)
final classicCash = TournamentStructure(
  name: 'Classic Jara Cash',
  isCashGame: true,
  levels: [
    const BlindLevel(level: 0, smallBlind: 100, bigBlind: 200, ante: 0, durationMinutes: 0),
  ],
);

// Preset 3: Empty Slate (user builds from scratch)
const emptySlate = TournamentStructure(
  name: 'Empty Slate',
  levels: [],
);

// All presets list
final allPresets = [classicTournament, classicCash, emptySlate];
