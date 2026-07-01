// 생성된 사전에 ㅙ(중성 10)·ㅞ(중성 15)를 포함한 단어가 있는지 실측 점검.
// (5자모 제약상 이런 단어는 존재할 수 없어야 한다.)
//
// 실행: dart run build_tools/check_vowels.dart
//
// ignore_for_file: avoid_print

import 'dart:io';

List<String> _load(String p) => File(p)
    .readAsStringSync()
    .split('\n')
    .map((e) => e.trim())
    .where((e) => e.isNotEmpty)
    .toList();

bool _hasTripleVowel(String word) {
  for (final code in word.runes) {
    if (code < 0xAC00 || code > 0xD7A3) continue;
    final jung = ((code - 0xAC00) % 588) ~/ 28;
    if (jung == 10 || jung == 15) return true; // ㅙ, ㅞ
  }
  return false;
}

void main() {
  final root = File.fromUri(Platform.script).parent.parent.path;
  for (final name in ['answers.txt', 'guesses.txt']) {
    final words = _load('$root/assets/$name');
    final offenders = words.where(_hasTripleVowel).toList();
    print('$name: 전체 ${words.length}개 중 ㅙ/ㅞ 포함 단어 ${offenders.length}개'
        '${offenders.isEmpty ? '' : ' -> ${offenders.take(20).join(', ')}'}');
  }
}
