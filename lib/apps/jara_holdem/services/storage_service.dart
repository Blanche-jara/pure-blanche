import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tournament_structure.dart';

class StorageService {
  static const _structureKey = 'tournament_structure';
  static const _stateKey = 'tournament_state';

  Future<void> saveStructure(TournamentStructure structure) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_structureKey, jsonEncode(structure.toJson()));
  }

  Future<TournamentStructure?> loadStructure() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_structureKey);
    if (data == null) return null;
    return TournamentStructure.fromJson(jsonDecode(data));
  }

  Future<void> saveState({
    required int currentLevelIndex,
    required int remainingSeconds,
    int elapsedSeconds = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _stateKey,
      jsonEncode({
        'currentLevelIndex': currentLevelIndex,
        'remainingSeconds': remainingSeconds,
        'elapsedSeconds': elapsedSeconds,
        'savedAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  Future<Map<String, dynamic>?> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_stateKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<void> clearState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stateKey);
  }
}
