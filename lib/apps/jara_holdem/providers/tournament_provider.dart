import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/blind_level.dart';
import '../models/break_level.dart';
import '../models/tournament_structure.dart';
import '../presets/default_presets.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';

class TournamentProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final SoundService _sound = SoundService();
  Timer? _timer;

  TournamentStructure _structure = classicTournament;
  int _currentLevelIndex = 0;
  int _remainingSeconds = 0;
  int _elapsedSeconds = 0; // for cash game elapsed time
  bool _isRunning = false;
  bool _soundEnabled = true;

  // Getters
  TournamentStructure get structure => _structure;
  int get currentLevelIndex => _currentLevelIndex;
  int get remainingSeconds => _remainingSeconds;
  int get elapsedSeconds => _elapsedSeconds;
  bool get isRunning => _isRunning;
  bool get soundEnabled => _soundEnabled;
  bool get isCashGame => _structure.isCashGame;

  dynamic get currentLevel =>
      _structure.levels.isNotEmpty ? _structure.levels[_currentLevelIndex] : null;
  bool get isBreak => currentLevel is BreakLevel;
  bool get isBlind => currentLevel is BlindLevel;

  bool get isInfiniteLevel {
    final level = currentLevel;
    if (level is BlindLevel) return level.durationMinutes == 0;
    return false;
  }

  int get totalSeconds {
    final level = currentLevel;
    if (level is BlindLevel) return level.durationSeconds;
    if (level is BreakLevel) return level.durationSeconds;
    return 0;
  }

  int get displayLevelNumber => _structure.getBlindLevelNumber(_currentLevelIndex);

  dynamic get nextLevel {
    final nextIdx = _currentLevelIndex + 1;
    if (nextIdx < _structure.levels.length) return _structure.levels[nextIdx];
    return null;
  }

  BlindLevel? get nextBlindLevel {
    for (int i = _currentLevelIndex + 1; i < _structure.levels.length; i++) {
      if (_structure.levels[i] is BlindLevel) return _structure.levels[i];
    }
    return null;
  }

  bool get isLastLevel => _currentLevelIndex >= _structure.levels.length - 1;

  String get formattedTime {
    if (isInfiniteLevel) {
      // Show elapsed time for cash game
      final hours = _elapsedSeconds ~/ 3600;
      final minutes = (_elapsedSeconds % 3600) ~/ 60;
      final seconds = _elapsedSeconds % 60;
      if (hours > 0) {
        return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progress {
    if (isInfiniteLevel) return 0;
    if (totalSeconds == 0) return 0;
    return 1.0 - (_remainingSeconds / totalSeconds);
  }

  // Initialization
  Future<void> initialize() async {
    final savedStructure = await _storage.loadStructure();
    if (savedStructure != null) {
      _structure = savedStructure;
    }

    if (_structure.levels.isEmpty) {
      notifyListeners();
      return;
    }

    final savedState = await _storage.loadState();
    if (savedState != null) {
      _currentLevelIndex = savedState['currentLevelIndex'] as int;
      _remainingSeconds = savedState['remainingSeconds'] as int;
      _elapsedSeconds = savedState['elapsedSeconds'] as int? ?? 0;
      if (_currentLevelIndex >= _structure.levels.length) {
        _currentLevelIndex = 0;
        _resetCurrentLevelTime();
      }
    } else {
      _resetCurrentLevelTime();
    }
    notifyListeners();
  }

  // Timer controls
  void start() {
    if (_isRunning) return;
    if (_structure.levels.isEmpty) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    notifyListeners();
  }

  void pause() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    _saveCurrentState();
    notifyListeners();
  }

  void toggleStartPause() {
    if (_isRunning) {
      pause();
    } else {
      start();
    }
  }

  void _tick(Timer timer) {
    if (isInfiniteLevel) {
      // Cash game: count up
      _elapsedSeconds++;
      notifyListeners();
      return;
    }

    if (_remainingSeconds > 0) {
      _remainingSeconds--;

      if (_remainingSeconds == 10 && _soundEnabled) {
        _sound.playWarning();
      }

      notifyListeners();
    } else {
      _onLevelEnd();
    }
  }

  void _onLevelEnd() {
    if (_soundEnabled) {
      if (isBreak) {
        _sound.playBreakEnd();
      } else {
        _sound.playLevelEnd();
      }
    }

    if (!isLastLevel) {
      _currentLevelIndex++;
      _resetCurrentLevelTime();
      notifyListeners();
    } else {
      pause();
    }
  }

  // Navigation
  void nextLevelManual() {
    if (isLastLevel) return;
    _currentLevelIndex++;
    _resetCurrentLevelTime();
    _saveCurrentState();
    notifyListeners();
  }

  void previousLevel() {
    if (_currentLevelIndex <= 0) return;
    _currentLevelIndex--;
    _resetCurrentLevelTime();
    _saveCurrentState();
    notifyListeners();
  }

  // Time adjustment
  void addMinute() {
    if (isInfiniteLevel) return;
    _remainingSeconds += 60;
    notifyListeners();
  }

  void subtractMinute() {
    if (isInfiniteLevel) return;
    _remainingSeconds = (_remainingSeconds - 60).clamp(0, _remainingSeconds);
    notifyListeners();
  }

  // Sound toggle
  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    notifyListeners();
  }

  // Structure management
  void setStructure(TournamentStructure newStructure) {
    _structure = newStructure;
    _currentLevelIndex = 0;
    _elapsedSeconds = 0;
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    if (newStructure.levels.isNotEmpty) {
      _resetCurrentLevelTime();
    } else {
      _remainingSeconds = 0;
    }
    _storage.saveStructure(newStructure);
    _storage.clearState();
    notifyListeners();
  }

  void resetTournament() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    _currentLevelIndex = 0;
    _elapsedSeconds = 0;
    if (_structure.levels.isNotEmpty) {
      _resetCurrentLevelTime();
    }
    _storage.clearState();
    notifyListeners();
  }

  // Private helpers
  void _resetCurrentLevelTime() {
    final level = currentLevel;
    if (level is BlindLevel) {
      _remainingSeconds = level.durationSeconds;
    } else if (level is BreakLevel) {
      _remainingSeconds = level.durationSeconds;
    }
    _elapsedSeconds = 0;
  }

  void _saveCurrentState() {
    _storage.saveState(
      currentLevelIndex: _currentLevelIndex,
      remainingSeconds: _remainingSeconds,
      elapsedSeconds: _elapsedSeconds,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sound.dispose();
    super.dispose();
  }
}
