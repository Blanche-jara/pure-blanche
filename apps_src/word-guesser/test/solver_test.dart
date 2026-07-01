// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:word_guesser/hangul.dart';
import 'package:word_guesser/solver.dart';

List<String> _loadWords(String path) => File(path)
    .readAsStringSync()
    .split('\n')
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .toList();

List<Mark> _decodePattern(int p, int len) {
  final m = List<Mark>.filled(len, Mark.absent);
  for (var i = len - 1; i >= 0; i--) {
    m[i] = Mark.values[p % 3];
    p ~/= 3;
  }
  return m;
}

void main() {
  group('한글 분해 (쌍자음·복합모음·겹받침 → 기본자모)', () {
    test('기본', () {
      expect(decomposeWord('사람'), ['ㅅ', 'ㅏ', 'ㄹ', 'ㅏ', 'ㅁ']);
      expect(decomposeWord('가방'), ['ㄱ', 'ㅏ', 'ㅂ', 'ㅏ', 'ㅇ']);
    });
    test('복합모음 (ㅐ→ㅏㅣ, ㅘ→ㅗㅏ)', () {
      expect(decomposeWord('사과'), ['ㅅ', 'ㅏ', 'ㄱ', 'ㅗ', 'ㅏ']);
      expect(decomposeWord('노래'), ['ㄴ', 'ㅗ', 'ㄹ', 'ㅏ', 'ㅣ']);
    });
    test('쌍자음 (ㄲ→ㄱㄱ, ㅉ→ㅈㅈ)', () {
      expect(decomposeWord('꼬들'), ['ㄱ', 'ㄱ', 'ㅗ', 'ㄷ', 'ㅡ', 'ㄹ']);
      expect(decomposeWord('낚시'), ['ㄴ', 'ㅏ', 'ㄱ', 'ㄱ', 'ㅅ', 'ㅣ']);
      expect(decomposeWord('공짜'), ['ㄱ', 'ㅗ', 'ㅇ', 'ㅈ', 'ㅈ', 'ㅏ']);
    });
    test('겹받침 (ㄺ→ㄹㄱ)', () {
      expect(decomposeWord('닭'), ['ㄷ', 'ㅏ', 'ㄹ', 'ㄱ']);
    });
    test('유효 후보 (길이별)', () {
      expect(isValidCandidate('사람', length: 5), isTrue);
      expect(isValidCandidate('꼬들', length: 6), isTrue);
      expect(isValidCandidate('꼬들', length: 5), isFalse);
      expect(isValidCandidate('대중문화', length: 12), isTrue); // ㄷㅐㅈㅜㅇㅁㅜㄴㅎㅘ
    });
  });

  group('피드백 패턴 (중복 자모)', () {
    final buf = Int32List(24);
    int patt(String g, String a) => wordlePattern(
        WordEntry.tryParse(g, 5)!.jamo, WordEntry.tryParse(a, 5)!.jamo, buf);

    test('초록/노랑/회색', () {
      final p = patt('가발', '사람'); // 가발=ㄱㅏㅂㅏㄹ vs 사람=ㅅㅏㄹㅏㅁ
      expect(_decodePattern(p, 5),
          [Mark.absent, Mark.correct, Mark.absent, Mark.correct, Mark.present]);
    });
    test('정답=모두 초록', () {
      expect(_decodePattern(patt('사람', '사람'), 5), List.filled(5, Mark.correct));
    });
  });

  group('변형별 시도 횟수 내 수렴 시뮬레이션', () {
    // (변형, answers, guesses, wordLen, maxGuesses)
    final cases = [
      ('카카오톡', 'kakao5', 5, 5),
      ('꼬들', 'kordle6', 6, 6),
      ('꼬오오오오들', 'kordle12', 12, 6),
    ];

    for (final c in cases) {
      final (name, prefix, len, maxG) = c;
      test('$name ($len자모, $maxG시도): 표본 정답 전부 수렴', () {
        final solver = Solver.fromWords(
          wordLen: len,
          maxGuesses: maxG,
          answerWords: _loadWords('assets/${prefix}_answers.txt'),
          guessWords: _loadWords('assets/${prefix}_guesses.txt'),
        );
        final buf = Int32List(24);
        int simulate(String target) {
          final t = solver.entryOf(target)!;
          solver.reset();
          var guess = solver.randomOpener().word;
          for (var turn = 1; turn <= maxG; turn++) {
            final ge = solver.entryOf(guess)!;
            final marks =
                _decodePattern(wordlePattern(ge.jamo, t.jamo, buf), len);
            solver.applyResult(guess, marks);
            if (marks.every((m) => m == Mark.correct)) return turn;
            final sug = solver.suggest(topN: 1);
            if (sug.isEmpty) return maxG + 1;
            guess = sug.first.word;
          }
          return maxG + 1;
        }

        final answers = _loadWords('assets/${prefix}_answers.txt');
        final targets = [
          for (var k = 0; k < 10; k++) answers[(k * 97) % answers.length]
        ];
        var worst = 0, fail = 0;
        for (final tw in targets) {
          final n = simulate(tw);
          if (n > worst) worst = n;
          if (n > maxG) fail++;
        }
        print('$name: 표본 ${targets.length}개, 최악 $worst, 실패 $fail');
        expect(fail, 0, reason: '$name 일부 표본이 $maxG시도 초과');
      }, timeout: const Timeout(Duration(minutes: 5)));
    }
  });
}
