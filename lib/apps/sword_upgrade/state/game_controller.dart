import 'dart:async';
import 'package:flutter/widgets.dart';
import '../audio/forge_audio.dart';
import '../data/save_repository.dart';
import '../engine/balance.dart';
import '../engine/models.dart';
import '../engine/rules.dart';

class GameController extends ChangeNotifier with WidgetsBindingObserver {
  GameState state;
  final SaveRepository repository;
  final double Function()? roll;
  final ForgeAudio audio;
  late GameRules rules;
  bool busy = false;
  bool autoRunning = false;
  bool _active = true;
  bool _disposed = false;
  bool _replacingState = false;
  int _autoGeneration = 0;
  int actionSequence = 0;
  Outcome? outcome;
  String message = '한 번 더 강화할까, 지금 팔까?';
  String? saveError;
  DateTime? lastSaved;
  Timer? _playTimer;
  Timer? _saveTimer;
  final List<Timer> _soundTimers = [];
  Future<void>? _animationDone;
  Future<void> get idle => _animationDone ?? Future<void>.value();
  DateTime _lastAutoSave = DateTime.fromMillisecondsSinceEpoch(0);
  GameController(
    this.repository, {
    GameState? state,
    this.roll,
    ForgeAudio? audio,
    bool trackTime = true,
  }) : state = state ?? GameState(),
       audio = audio ?? const SilentForgeAudio() {
    rules = GameRules(this.state, roll: roll);
    if (this.state.protectionRefund > 0) {
      message = '보유 보호권을 골드로 환급했습니다. 보호비는 강화할 때 결제합니다.';
    }
    WidgetsBinding.instance.addObserver(this);
    if (trackTime) {
      _playTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!_active || _replacingState) return;
        this.state.playSeconds++;
        if (this.state.playSeconds % 15 == 0) unawaited(saveNow());
      });
    }
  }
  static Future<GameController> load(
    SaveRepository repository, {
    ForgeAudio? audio,
  }) async {
    try {
      return GameController(repository, state: repository.load(), audio: audio);
    } catch (_) {
      await repository.preserveInvalidSave();
      return GameController(repository, audio: audio)
        ..saveError = '기존 저장을 읽지 못했습니다. 복구 사본을 보존하고 새 대장간을 열었습니다.';
    }
  }

  Duration get animationDuration {
    final special =
        outcome?.kind == OutcomeKind.breakthrough ||
        outcome?.kind == OutcomeKind.rareFound ||
        outcome?.kind == OutcomeKind.ending;
    return Duration(
      milliseconds: special
          ? (state.shortAnimation ? 600 : 1200)
          : autoRunning
          ? (state.shortAnimation ? 150 : 300)
          : (state.shortAnimation ? 400 : 900),
    );
  }

  void notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> saveNow() async {
    if (_replacingState) return;
    _saveTimer?.cancel();
    try {
      await repository.save(state);
      if (_disposed) return;
      lastSaved = DateTime.now();
      saveError = null;
    } catch (_) {
      if (_disposed) return;
      saveError = '자동 저장에 실패했습니다. 설정에서 백업 코드를 복사하세요.';
    }
    notify();
  }

  void _save({bool urgent = false}) {
    if (urgent ||
        !autoRunning ||
        DateTime.now().difference(_lastAutoSave).inMilliseconds >= 500) {
      _lastAutoSave = DateTime.now();
      unawaited(saveNow());
    } else {
      _saveTimer?.cancel();
      _saveTimer = Timer(
        const Duration(milliseconds: 500),
        () => unawaited(saveNow()),
      );
    }
  }

  void act(void Function(GameRules) action, String successMessage) {
    if (busy || _disposed || _replacingState) return;
    stopAuto(silent: true);
    try {
      action(rules);
      outcome = null;
      message = successMessage;
      _save(urgent: true);
    } on RuleException catch (error) {
      message = error.message;
    }
    notify();
  }

  void chooseProtection(int option) {
    if (busy ||
        autoRunning ||
        _replacingState ||
        option < 0 ||
        option > 3 ||
        state.sword.isRare) {
      return;
    }
    state.protection = option;
    _save();
    notify();
  }

  void setAutoTarget(int target) {
    if (busy ||
        autoRunning ||
        _replacingState ||
        target < 1 ||
        target > Balance.maxLevel) {
      return;
    }
    state.autoTarget = target;
    _save();
    notify();
  }

  Future<void> enhance({List<int>? materials}) async {
    if (busy || _disposed || _replacingState) return;
    unlockAudio();
    try {
      final result = rules.enhance(materials: materials);
      outcome = result;
      message = result.message;
      actionSequence++;
      busy = true;
      final duration = animationDuration;
      _scheduleSounds(result, duration);
      _save(
        urgent:
            result.kind == OutcomeKind.ending ||
            result.kind == OutcomeKind.rareFound ||
            result.kind == OutcomeKind.breakthrough,
      );
      notify();
      _animationDone = Future<void>.delayed(duration);
      await _animationDone;
      if (_disposed) return;
      busy = false;
      notify();
    } on RuleException catch (error) {
      stopAuto(silent: true);
      message = error.message;
      notify();
    }
  }

  Future<void> startAuto() async {
    if (busy ||
        autoRunning ||
        state.sword.isRare ||
        _disposed ||
        _replacingState) {
      return;
    }
    unlockAudio();
    if (state.sword.level >= state.autoTarget) {
      message = '현재 단계보다 높은 목표를 선택하세요.';
      notify();
      return;
    }
    autoRunning = true;
    final generation = ++_autoGeneration;
    notify();
    while (!_disposed && autoRunning && generation == _autoGeneration) {
      if (state.sword.isRare ||
          state.sword.level >= state.autoTarget ||
          rules.gate != null ||
          state.gold < rules.totalCost ||
          !_active) {
        final reason = state.sword.isRare
            ? '희귀 무기는 수동으로 강화하세요.'
            : state.sword.level >= state.autoTarget
            ? '목표 +${state.autoTarget}에 도달했습니다.'
            : rules.gate != null
            ? '돌파 재료를 확인하세요.'
            : !_active
            ? '대장간을 벗어나 자동 강화를 멈췄습니다.'
            : '골드가 부족합니다.';
        stopAuto(silent: true);
        message = '$reason 자동 강화 정지.';
        notify();
        break;
      }
      await enhance();
    }
    if (!_disposed) _save(urgent: true);
  }

  void stopAuto({bool silent = false}) {
    if (!autoRunning) return;
    autoRunning = false;
    _autoGeneration++;
    if (!silent) message = '자동 강화를 멈췄습니다.';
    _save(urgent: true);
    notify();
  }

  Future<void> importBackup(String code) async {
    final imported = SaveRepository.decode(code);
    await _replaceState(imported, '백업을 불러왔습니다.');
  }

  Future<void> resetGame() =>
      _replaceState(GameState(), '게임을 초기화했습니다. 새로운 대장간을 열었습니다.');

  Future<void> _replaceState(GameState next, String resultMessage) async {
    if (busy || _replacingState || _disposed) {
      throw const RuleException('현재 작업이 끝난 뒤 다시 시도하세요.');
    }
    stopAuto(silent: true);
    _replacingState = true;
    _saveTimer?.cancel();
    try {
      // Queue after existing writes, and replace live progress only after saving.
      await repository.save(next);
      _cancelSounds();
      state = next;
      rules = GameRules(state, roll: roll);
      outcome = null;
      message = next.protectionRefund > 0
          ? '$resultMessage 보유 보호권을 골드로 환급했습니다.'
          : resultMessage;
      saveError = null;
      lastSaved = DateTime.now();
    } finally {
      _replacingState = false;
      notify();
    }
  }

  void setSettings({
    bool? shortAnimation,
    bool? confirmHigh,
    bool? soundEnabled,
  }) {
    if (_replacingState) return;
    state.shortAnimation = shortAnimation ?? state.shortAnimation;
    state.confirmHigh = confirmHigh ?? state.confirmHigh;
    state.soundEnabled = soundEnabled ?? state.soundEnabled;
    if (soundEnabled == false) _cancelSounds();
    if (soundEnabled == true) unlockAudio();
    _save(urgent: true);
    notify();
  }

  /// Call directly from a user action, before confirmation/material dialogs.
  void unlockAudio() {
    if (!_disposed && _active && state.soundEnabled) audio.unlock();
  }

  void _scheduleSounds(Outcome result, Duration duration) {
    for (final timer in _soundTimers) {
      timer.cancel();
    }
    _soundTimers.clear();
    if (!state.soundEnabled || !_active) return;
    final quiet = autoRunning;
    void at(double progress, void Function() play) {
      _soundTimers.add(
        Timer(
          Duration(microseconds: (duration.inMicroseconds * progress).round()),
          () {
            if (!_disposed && _active && state.soundEnabled) play();
          },
        ),
      );
    }

    // The hammer lands at .18 in ForgeStage; fracture follows the impact.
    at(.18, () => audio.hammer(quiet: quiet));
    if (result.kind == OutcomeKind.destroyed ||
        result.kind == OutcomeKind.rareFound) {
      at(.28, () => audio.shatter(quiet: quiet));
    }
  }

  void _cancelSounds() {
    for (final timer in _soundTimers) {
      timer.cancel();
    }
    _soundTimers.clear();
    audio.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (!_active) {
      _cancelSounds();
      stopAuto();
      unawaited(saveNow());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _autoGeneration++;
    _playTimer?.cancel();
    _saveTimer?.cancel();
    _cancelSounds();
    audio.dispose();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(repository.save(state).catchError((Object _) {}));
    super.dispose();
  }
}
