import 'dart:async';
import 'dart:js_interop';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;
import 'forge_audio.dart';

ForgeAudio createForgeAudio() => WebForgeAudio();

class WebForgeAudio extends ForgeAudio {
  static const _names = [
    'hammer_1',
    'hammer_2',
    'hammer_3',
    'break_1',
    'break_2',
  ];
  final _bytes = <String, Uint8List>{};
  final _buffers = <String, web.AudioBuffer>{};
  final _voices = <({web.AudioBufferSourceNode source, web.GainNode gain})>[];
  final _random = Random();
  web.AudioContext? _context;
  web.GainNode? _master;
  Future<void>? _decoding;
  int _generation = 0;
  int _hammerIndex = 0;
  int _breakIndex = 0;
  bool _disposed = false;
  web.HTMLAudioElement? _music;
  bool _musicRequested = false;

  @override
  void setMusic({required bool playing}) {
    _musicRequested = playing;
    if (playing) {
      _playMusic();
    } else {
      _music?.pause();
    }
  }

  void _playMusic() {
    if (_disposed || !_musicRequested) return;
    final music = _music ??=
        (web.document.createElement('audio') as web.HTMLAudioElement)
          ..src = 'assets/assets/sword_upgrade/audio/bgm.mp3'
          ..loop = true
          ..preload = 'metadata'
          ..volume = .18
          ..setAttribute('data-sword-bgm', '')
          ..setAttribute('aria-hidden', 'true')
          ..setAttribute('hidden', '');
    if (!music.isConnected) web.document.body?.appendChild(music);
    // Stream the song independently; a blocked autoplay never delays the game.
    // Retry synchronously on the next click/touch/key, preserving playback time.
    if (music.paused) {
      unawaited(music.play().toDart.catchError((Object _) => null));
    }
  }

  @override
  Future<void> load() async {
    // Fetch once without opening an audio device before the first user gesture.
    await Future.wait(
      _names.map((name) async {
        try {
          final data = await rootBundle.load(
            'assets/sword_upgrade/audio/$name.wav',
          );
          if (!_disposed) _bytes[name] = Uint8List.sublistView(data);
        } catch (_) {
          // Audio must never prevent loading the game or resolving an enhancement.
        }
      }),
    );
  }

  @override
  void unlock() {
    if (_disposed) return;
    _playMusic();
    try {
      if (_context == null) {
        final context = web.AudioContext(
          web.AudioContextOptions(latencyHint: 'interactive'.toJS),
        );
        _context = context;
        _master = context.createGain()..gain.value = .65;
        _master!.connect(context.destination);
        _decoding = Future.wait(
          _bytes.entries.map((entry) async {
            try {
              final buffer = await context
                  .decodeAudioData(Uint8List.fromList(entry.value).buffer.toJS)
                  .toDart;
              if (!_disposed) _buffers[entry.key] = buffer;
            } catch (_) {}
          }),
        );
      }
      if (_context!.state == 'suspended') {
        unawaited(_context!.resume().toDart.catchError((Object _) => null));
      }
    } catch (_) {}
  }

  @override
  void hammer({bool quiet = false}) =>
      unawaited(_play('hammer_${++_hammerIndex % 3 + 1}', quiet ? .48 : 1));

  @override
  void shatter({bool quiet = false}) =>
      unawaited(_play('break_${++_breakIndex % 2 + 1}', quiet ? .60 : .90));

  Future<void> _play(String name, double volume) async {
    final generation = _generation;
    try {
      await _decoding;
      final context = _context;
      final buffer = _buffers[name];
      if (_disposed ||
          generation != _generation ||
          context == null ||
          context.state != 'running' ||
          buffer == null) {
        return;
      }
      if (_voices.length >= 8) _fadeOut(_voices.removeAt(0));
      final source = context.createBufferSource()
        ..buffer = buffer
        ..playbackRate.value = .975 + _random.nextDouble() * .05;
      final gain = context.createGain()..gain.value = volume;
      source.connect(gain);
      gain.connect(_master!);
      final voice = (source: source, gain: gain);
      _voices.add(voice);
      source.onended = ((web.Event _) {
        _voices.remove(voice);
        source.disconnect();
        gain.disconnect();
      }).toJS;
      source.start();
    } catch (_) {}
  }

  void _fadeOut(({web.AudioBufferSourceNode source, web.GainNode gain}) voice) {
    try {
      final now = _context!.currentTime;
      voice.gain.gain.setValueAtTime(voice.gain.gain.value, now);
      voice.gain.gain.linearRampToValueAtTime(0, now + .008);
      voice.source.stop(now + .01);
    } catch (_) {}
  }

  @override
  void stop() {
    _music?.pause();
    _generation++;
    for (final voice in _voices.toList()) {
      _fadeOut(voice);
    }
    _voices.clear();
  }

  @override
  void dispose() {
    stop();
    _disposed = true;
    _music?.remove();
    _music?.removeAttribute('src');
    _music?.load();
    _music = null;
    final context = _context;
    if (context != null) {
      unawaited(context.close().toDart.catchError((Object _) => null));
    }
    _buffers.clear();
    _bytes.clear();
  }
}
