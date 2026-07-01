// 단어 사전 빌드 스크립트.
//
// build_tools/raw/CommonNouns.js, AllNouns.js 를 읽어
//  - assets/answers.txt : 상용 명사 중 "기본 자모 5개"로 분해되는 단어 (정답 후보 풀)
//  - assets/guesses.txt : 전체 명사 중 "기본 자모 5개"로 분해되는 단어 (유효 추측 풀, answers 포함)
// 을 생성한다.
//
// 앱과 동일한 lib/hangul.dart 의 분해/필터 규칙을 사용하므로 결과가 100% 일치한다.
//
// 실행:  dart run build_tools/build_wordlist.dart   (프로젝트 루트에서)
//
// ignore_for_file: avoid_print

import 'dart:io';
import 'package:word_guesser/hangul.dart';

final _wordRe = RegExp(r"'([가-힣]+)'");

Set<String> _extractValid(String path) {
  final text = File(path).readAsStringSync();
  final result = <String>{};
  for (final m in _wordRe.allMatches(text)) {
    final word = m.group(1)!;
    if (isValidCandidate(word, length: 5)) {
      result.add(word);
    }
  }
  return result;
}

void main() {
  // 스크립트(build_tools/build_wordlist.dart) 위치 기준으로 프로젝트 루트 산출.
  final scriptDir = File.fromUri(Platform.script).parent; // build_tools
  final root = scriptDir.parent.path;
  final rawDir = '$root/build_tools/raw';
  final assetsDir = Directory('$root/assets');
  if (!assetsDir.existsSync()) assetsDir.createSync(recursive: true);

  print('CommonNouns.js 파싱...');
  final answers = _extractValid('$rawDir/CommonNouns.js');
  print('  -> 5자모 상용 단어: ${answers.length}개');

  print('AllNouns.js 파싱...');
  final allValid = _extractValid('$rawDir/AllNouns.js');
  print('  -> 5자모 전체 단어: ${allValid.length}개');

  // 추측 풀 = 전체 ∪ 상용 (answers 가 반드시 포함되도록)
  final guesses = {...allValid, ...answers};

  final answersSorted = answers.toList()..sort();
  final guessesSorted = guesses.toList()..sort();

  File('${assetsDir.path}/kakao5_answers.txt')
      .writeAsStringSync(answersSorted.join('\n'));
  File('${assetsDir.path}/kakao5_guesses.txt')
      .writeAsStringSync(guessesSorted.join('\n'));

  print('생성 완료:');
  print('  assets/kakao5_answers.txt : ${answersSorted.length}개');
  print('  assets/kakao5_guesses.txt : ${guessesSorted.length}개');

  // 참고: 정답 풀 기준 자모 빈도(초성/중성/종성 무시, 위치별 단순 카운트) 출력
  final freq = <String, int>{};
  for (final w in answersSorted) {
    for (final j in decomposeWord(w)) {
      freq[j] = (freq[j] ?? 0) + 1;
    }
  }
  final ranked = freq.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  print('\n정답 풀 자모 빈도 상위 24개:');
  print(ranked.take(24).map((e) => '${e.key}:${e.value}').join('  '));

  // 샘플: 5자모 모두 서로 다른 상용 단어 몇 개(좋은 스타팅 후보 감각용)
  final distinct = answersSorted.where((w) {
    final j = decomposeWord(w);
    return j.toSet().length == 5;
  }).toList();
  print('\n5자모가 모두 다른 상용 단어 수: ${distinct.length}개');
  print('예시 20개: ${distinct.take(20).join(', ')}');
}
