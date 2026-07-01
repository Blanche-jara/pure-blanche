import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_guesser/main.dart';
import 'package:word_guesser/solver.dart';

List<String> _load(String p) => File(p)
    .readAsStringSync()
    .split('\n')
    .map((e) => e.trim())
    .where((e) => e.isNotEmpty)
    .toList();

Solver _solverFor(GameVariant v) => Solver.fromWords(
      wordLen: v.wordLen,
      maxGuesses: v.maxGuesses,
      answerWords: _load(v.answersAsset),
      guessWords: _load(v.guessesAsset),
    );

Widget _board(GameVariant v) => MaterialApp(
      home: Scaffold(body: WordleBoard(solver: _solverFor(v), variant: v)),
    );

void main() {
  final kakao = kVariants[0];
  final kordle12 = kVariants[2];

  testWidgets('보드가 스타팅 추천을 표시한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(520, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_board(kakao));
    await tester.pump();
    expect(find.text('추천 스타팅 단어'), findsOneWidget);
    expect(find.text('결과 적용'), findsOneWidget);
    expect(find.text('키보드 현황'), findsOneWidget);
  });

  testWidgets('5칸 모두 초록 → 정답 처리', (tester) async {
    await tester.binding.setSurfaceSize(const Size(520, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_board(kakao));
    await tester.pump();
    for (var i = 0; i < kakao.wordLen; i++) {
      await tester.tap(find.byKey(ValueKey('active_$i')));
      await tester.pump();
      await tester.tap(find.byKey(ValueKey('active_$i')));
      await tester.pump();
    }
    await tester.tap(find.text('결과 적용'));
    await tester.pumpAndSettle();
    expect(find.textContaining('정답:'), findsOneWidget);
  });

  testWidgets('12자모 보드도 좁은 폭(320)에서 오버플로 없음', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 2000));
    await tester.pumpWidget(_board(kordle12));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('결과 적용'), findsOneWidget);
  });

  testWidgets('전체 앱이 3개 탭을 띄운다(로딩 스피너)', (tester) async {
    await tester.pumpWidget(const SolverApp());
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
