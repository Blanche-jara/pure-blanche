import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

class SoundService {
  final AudioPlayer _player = AudioPlayer();

  /// Play a short warning beep (10 seconds before level ends)
  Future<void> playWarning() async {
    await _playTone(800, 200);
  }

  /// Play level-end sound
  Future<void> playLevelEnd() async {
    await _playTone(1000, 500);
    await Future.delayed(const Duration(milliseconds: 100));
    await _playTone(1200, 500);
  }

  /// Play break-end sound
  Future<void> playBreakEnd() async {
    for (int i = 0; i < 3; i++) {
      await _playTone(1000, 300);
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  Future<void> _playTone(int frequency, int durationMs) async {
    // Generate a simple sine wave WAV
    final sampleRate = 44100;
    final numSamples = (sampleRate * durationMs / 1000).round();
    final samples = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      // Apply fade in/out envelope to avoid clicks
      double envelope = 1.0;
      final fadeLength = (sampleRate * 0.01).round(); // 10ms fade
      if (i < fadeLength) {
        envelope = i / fadeLength;
      } else if (i > numSamples - fadeLength) {
        envelope = (numSamples - i) / fadeLength;
      }
      samples[i] = (sin(2 * pi * frequency * t) * 32767 * 0.5 * envelope).round().clamp(-32768, 32767);
    }

    final wavData = _createWav(samples, sampleRate);
    await _player.play(BytesSource(wavData));
  }

  Uint8List _createWav(Int16List samples, int sampleRate) {
    final dataSize = samples.length * 2;
    final fileSize = 44 + dataSize;
    final buffer = ByteData(fileSize);

    // RIFF header
    buffer.setUint8(0, 0x52); // R
    buffer.setUint8(1, 0x49); // I
    buffer.setUint8(2, 0x46); // F
    buffer.setUint8(3, 0x46); // F
    buffer.setUint32(4, fileSize - 8, Endian.little);
    buffer.setUint8(8, 0x57); // W
    buffer.setUint8(9, 0x41); // A
    buffer.setUint8(10, 0x56); // V
    buffer.setUint8(11, 0x45); // E

    // fmt chunk
    buffer.setUint8(12, 0x66); // f
    buffer.setUint8(13, 0x6D); // m
    buffer.setUint8(14, 0x74); // t
    buffer.setUint8(15, 0x20); // (space)
    buffer.setUint32(16, 16, Endian.little); // chunk size
    buffer.setUint16(20, 1, Endian.little); // PCM
    buffer.setUint16(22, 1, Endian.little); // mono
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    buffer.setUint16(32, 2, Endian.little); // block align
    buffer.setUint16(34, 16, Endian.little); // bits per sample

    // data chunk
    buffer.setUint8(36, 0x64); // d
    buffer.setUint8(37, 0x61); // a
    buffer.setUint8(38, 0x74); // t
    buffer.setUint8(39, 0x61); // a
    buffer.setUint32(40, dataSize, Endian.little);

    for (int i = 0; i < samples.length; i++) {
      buffer.setInt16(44 + i * 2, samples[i], Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  void dispose() {
    _player.dispose();
  }
}
