import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'hangul.dart';
import 'report.dart';
import 'solver.dart';

void main() => runApp(const SolverApp());

// ---- 색상 팔레트 (워들 표준) ----
const _correct = Color(0xFF6AAA64); // 초록: 위치 맞음
const _present = Color(0xFFC9B458); // 노랑: 있지만 위치 틀림
const _absent = Color(0xFF787C7E); // 회색: 없음
const _empty = Color(0xFFF3F3F3); // 흰색/빈칸
const _emptyBorder = Color(0xFFD3D6DA);
const _maxWidth = 560.0;

Color _markColor(Mark m) => switch (m) {
      Mark.correct => _correct,
      Mark.present => _present,
      Mark.absent => _absent,
    };

// 세 게임 모두 동일한 24 기본자모 키보드 (스크린샷과 동일 배열, 백스페이스 제외).
const List<List<String>> _kbLayout = [
  ['ㅂ', 'ㅈ', 'ㄷ', 'ㄱ', 'ㅅ', 'ㅛ', 'ㅕ', 'ㅑ'],
  ['ㅁ', 'ㄴ', 'ㅇ', 'ㄹ', 'ㅎ', 'ㅗ', 'ㅓ', 'ㅏ', 'ㅣ'],
  ['ㅋ', 'ㅌ', 'ㅊ', 'ㅍ', 'ㅠ', 'ㅜ', 'ㅡ'],
];

/// 게임 변형 설정.
class GameVariant {
  final String tabLabel; // 탭 이름
  final String fullTitle; // 상단 제목
  final int wordLen; // 자모 칸 수
  final int maxGuesses; // 시도 횟수
  final String answersAsset;
  final String guessesAsset;
  final String slug; // 통계 보고용: kakao5 / kordle6 / kordle12
  const GameVariant({
    required this.tabLabel,
    required this.fullTitle,
    required this.wordLen,
    required this.maxGuesses,
    required this.answersAsset,
    required this.guessesAsset,
    required this.slug,
  });
}

const List<GameVariant> kVariants = [
  GameVariant(
    tabLabel: '오늘의 단어',
    fullTitle: '카카오톡 오늘의 단어 · 5자모',
    wordLen: 5,
    maxGuesses: 5,
    answersAsset: 'assets/kakao5_answers.txt',
    guessesAsset: 'assets/kakao5_guesses.txt',
    slug: 'kakao5',
  ),
  GameVariant(
    tabLabel: '꼬들',
    fullTitle: '꼬들 · 6자모',
    wordLen: 6,
    maxGuesses: 6,
    answersAsset: 'assets/kordle6_answers.txt',
    guessesAsset: 'assets/kordle6_guesses.txt',
    slug: 'kordle6',
  ),
  GameVariant(
    tabLabel: '꼬오오오오들',
    fullTitle: '꼬오오오오들 · 12자모',
    wordLen: 12,
    maxGuesses: 6,
    answersAsset: 'assets/kordle12_answers.txt',
    guessesAsset: 'assets/kordle12_guesses.txt',
    slug: 'kordle12',
  ),
];

class SolverApp extends StatelessWidget {
  const SolverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '한글 워들 필승법',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _correct,
        fontFamily: 'Apple SD Gothic Neo',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const _Loader(),
    );
  }
}

Future<Solver> _loadSolver(GameVariant v) async {
  final a = await rootBundle.loadString(v.answersAsset);
  final g = await rootBundle.loadString(v.guessesAsset);
  List<String> lines(String s) => s
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  return Solver.fromWords(
    wordLen: v.wordLen,
    maxGuesses: v.maxGuesses,
    answerWords: lines(a),
    guessWords: lines(g),
  );
}

class _Loader extends StatefulWidget {
  const _Loader();
  @override
  State<_Loader> createState() => _LoaderState();
}

class _LoaderState extends State<_Loader> {
  late final Future<List<Solver>> _future =
      Future.wait(kVariants.map(_loadSolver));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Solver>>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(body: Center(child: Text('로딩 오류: ${snap.error}')));
        }
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return _TabsHome(solvers: snap.data!);
      },
    );
  }
}

class _TabsHome extends StatelessWidget {
  final List<Solver> solvers;
  const _TabsHome({required this.solvers});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: kVariants.length,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('한글 워들 필승법',
              style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: TabBar(
            tabs: [for (final v in kVariants) Tab(text: v.tabLabel)],
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < kVariants.length; i++)
              WordleBoard(solver: solvers[i], variant: kVariants[i]),
          ],
        ),
      ),
    );
  }
}

class WordleBoard extends StatefulWidget {
  final Solver solver;
  final GameVariant variant;
  const WordleBoard({super.key, required this.solver, required this.variant});

  @override
  State<WordleBoard> createState() => _WordleBoardState();
}

class _WordleBoardState extends State<WordleBoard>
    with AutomaticKeepAliveClientMixin {
  Solver get solver => widget.solver;
  int get wordLen => solver.wordLen;

  late String _word;
  late List<Mark> _marks;
  late List<Suggestion> _recos;
  bool _solved = false;
  bool _noCandidates = false;
  bool _reported = false; // 이번 세션에서 정답을 백엔드로 보고했는가.

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _startNew();
  }

  void _startNew() {
    solver.reset();
    _solved = false;
    _noCandidates = false;
    _reported = false;
    _word = solver.randomOpener().word;
    _marks = List.filled(wordLen, Mark.absent);
    _recos = solver.topOpeners;
    setState(() {});
  }

  void _setActiveWord(String w) {
    setState(() {
      _word = w;
      _marks = List.filled(wordLen, Mark.absent);
    });
  }

  void _cycle(int i) {
    setState(() {
      _marks[i] = Mark.values[(_marks[i].index + 1) % Mark.values.length];
    });
  }

  void _apply() {
    solver.applyResult(_word, _marks);
    _maybeReport();
    if (solver.isSolved) {
      setState(() => _solved = true);
      return;
    }
    if (solver.candidateCount == 0) {
      setState(() => _noCandidates = true);
      return;
    }
    final next = solver.suggest(topN: 12);
    setState(() {
      _recos = next;
      if (next.isNotEmpty) {
        _word = next.first.word;
        _marks = List.filled(wordLen, Mark.absent);
      }
    });
  }

  /// 정답이 하나로 수렴(후보 1개)하거나 맞혔으면 세션당 1회 백엔드로 보고.
  void _maybeReport() {
    if (_reported) return;
    String? answer;
    if (solver.isSolved) {
      answer = solver.history.isNotEmpty ? solver.history.last.word : null;
    } else if (solver.candidateCount == 1) {
      answer = solver.candidates.first.text;
    }
    if (answer != null && answer.isNotEmpty) {
      _reported = true;
      reportAnswer(widget.variant.slug, answer);
    }
  }

  void _undo() {
    solver.undo();
    _solved = false;
    _noCandidates = false;
    _reported = false;
    if (solver.history.isEmpty) {
      _startNew();
      return;
    }
    final next = solver.suggest(topN: 12);
    setState(() {
      _recos = next;
      if (next.isNotEmpty) {
        _word = next.first.word;
        _marks = List.filled(wordLen, Mark.absent);
      }
    });
  }

  Future<void> _manualEntry() async {
    final controller = TextEditingController(text: _word);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('직접 입력한 단어'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('추천과 다른 단어를 쳤다면 여기에 입력하세요.\n'
                '(자모 ${widget.variant.wordLen}개로 분해되는 단어만 가능)'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '예: 사람',
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final entry = WordEntry.tryParse(result, wordLen);
    if (entry == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('자모 ${widget.variant.wordLen}개로 분해되는 단어가 아니에요.')),
      );
      return;
    }
    _setActiveWord(entry.text);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _statusBar(),
            const SizedBox(height: 12),
            _grid(),
            const SizedBox(height: 16),
            if (_solved)
              _solvedCard()
            else if (_noCandidates)
              _noCandidatesCard()
            else if (solver.guessesLeft > 0)
              _inputControls()
            else
              _outOfTurnsCard(),
            const SizedBox(height: 20),
            if (!_solved && !_noCandidates && solver.guessesLeft > 0)
              _recommendations(),
            const SizedBox(height: 20),
            _candidatesPanel(),
            const SizedBox(height: 24),
            _keyboardHeatmap(),
          ],
        ),
      ),
    );
  }

  Widget _statusBar() {
    final turn = solver.turnsUsed + (_solved ? 0 : 1);
    return Row(
      children: [
        Expanded(
          child: Text(
            _solved
                ? '${solver.turnsUsed}턴 만에 정답!'
                : '$turn / ${solver.maxGuesses} 턴 · ${widget.variant.fullTitle}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '후보 ${solver.candidateCount}개${solver.wideMode ? '(확장)' : ''}',
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
      ],
    );
  }

  // ---- 그리드 (반응형, 임의 길이) ----
  Widget _grid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = wordLen >= 9 ? 2.0 : 3.0; // 칸당 좌우 패딩
        final cellSize = (((constraints.maxWidth - gap * 2 * wordLen) / wordLen)
                .clamp(16.0, 54.0))
            .toDouble();
        final rows = <Widget>[];
        for (final h in solver.history) {
          rows.add(_GuessRow(
              jamo: decomposeWord(h.word),
              marks: h.marks,
              cellSize: cellSize,
              gap: gap));
        }
        final activeShown =
            !_solved && !_noCandidates && solver.guessesLeft > 0;
        if (activeShown) {
          rows.add(_GuessRow(
            jamo: decomposeWord(_word),
            marks: _marks,
            editable: true,
            onTapCell: _cycle,
            cellKeyPrefix: 'active',
            cellSize: cellSize,
            gap: gap,
          ));
        }
        while (rows.length < solver.maxGuesses) {
          rows.add(_GuessRow(
              jamo: List.filled(wordLen, ''),
              marks: null,
              cellSize: cellSize,
              gap: gap));
        }
        return Column(
          children: [
            for (final r in rows)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3), child: r),
          ],
        );
      },
    );
  }

  Widget _inputControls() {
    final isOpener = solver.history.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _emptyBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(isOpener ? Icons.flag : Icons.keyboard,
                      size: 18, color: _correct),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(isOpener ? '추천 스타팅 단어' : '이번에 입력할 단어',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  Text(_word,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '① 게임에서 위 단어를 입력하세요.\n'
                '② 나온 색을 위 그리드의 칸마다 탭해서 맞추세요. (탭: 회색→노랑→초록)\n'
                '③ 아래 "결과 적용"을 누르면 다음 추천이 나옵니다.',
                style: TextStyle(
                    fontSize: 12.5, color: Colors.black87, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _apply,
            icon: const Icon(Icons.check),
            style: FilledButton.styleFrom(
              backgroundColor: _correct,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            label: const Text('결과 적용', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _manualEntry,
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                child: const Text('직접 입력'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _startNew,
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                child: const Text('초기화'),
              ),
            ),
            if (solver.history.isNotEmpty) ...[
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _undo,
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: const Text('취소'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _recommendations() {
    final isOpener = solver.history.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isOpener ? '다른 스타팅 단어' : '다음 추천 단어',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          isOpener
              ? '초기화를 누르면 무작위로 다른 단어를 추천합니다. 아래에서 골라도 됩니다.'
              : '엔트로피(정보량)가 높은 순. "정답 가능"은 그 자체가 답일 수 있는 단어입니다.',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        ..._recos.take(8).map((s) {
          final selected = s.word == _word;
          return Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 3),
            color: selected ? const Color(0xFFE8F2E5) : const Color(0xFFFAFAFA),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                  color: selected ? _correct : _emptyBorder,
                  width: selected ? 1.5 : 1),
            ),
            child: ListTile(
              dense: true,
              onTap: () => _setActiveWord(s.word),
              title: Row(
                children: [
                  Flexible(
                    child: Text(s.word,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  if (s.isCandidate)
                    _badge('정답 가능', _correct)
                  else
                    _badge('탐색용', Colors.blueGrey),
                ],
              ),
              subtitle: Text(
                '정보량 ${s.entropy.toStringAsFixed(2)} bit'
                '${s.worstBucket > 1 ? ' · 최악 ${s.worstBucket}개' : ''}',
                style: const TextStyle(fontSize: 11.5),
              ),
              trailing: selected
                  ? const Icon(Icons.check_circle, color: _correct, size: 20)
                  : const Icon(Icons.touch_app, color: Colors.black26, size: 18),
            ),
          );
        }),
      ],
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 10.5, color: color, fontWeight: FontWeight.w600)),
      );

  Widget _candidatesPanel() {
    final n = solver.candidateCount;
    if (n == 0) return const SizedBox.shrink();
    const chipThreshold = 36;
    final showChips = n <= chipThreshold;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _emptyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(n == 1 ? '정답 확정!' : '남은 정답 후보 $n개',
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (showChips)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final w in solver.candidates.map((e) => e.text))
                  Chip(
                    label: Text(w, style: const TextStyle(fontSize: 13)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: _emptyBorder),
                  ),
              ],
            )
          else
            const Text('후보가 36개 이하로 좁혀지면 가능한 단어 목록이 여기에 표시됩니다.',
                style: TextStyle(fontSize: 12.5, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _keyboardHeatmap() {
    final marks = solver.keyboardMarks();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('키보드 현황',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        const Text('초록=위치맞음 · 노랑=있음 · 회색=없음 · 흰색=미사용',
            style: TextStyle(fontSize: 11, color: Colors.black54)),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            const maxKeys = 9;
            final keyWidth = (((constraints.maxWidth - 4 * maxKeys) / maxKeys)
                    .clamp(24.0, 40.0))
                .toDouble();
            return Column(
              children: [
                for (final row in _kbLayout)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final j in row)
                          _KbKey(jamo: j, mark: marks[j], width: keyWidth),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _solvedCard() {
    final answer = solver.history.isNotEmpty ? solver.history.last.word : '';
    return _resultCard(
      icon: Icons.celebration,
      color: _correct,
      title: '정답: $answer 🎉',
      body: '${solver.turnsUsed}턴 만에 맞혔습니다! 초기화를 눌러 새 게임을 시작하세요.',
      action: _resetButton(),
    );
  }

  Widget _noCandidatesCard() {
    return _resultCard(
      icon: Icons.error_outline,
      color: Colors.redAccent,
      title: '맞는 단어가 없어요',
      body: '입력한 색 조합과 일치하는 단어가 사전에 없습니다. '
          '색을 잘못 지정했을 수 있어요. "취소"로 마지막 입력을 되돌리거나 초기화하세요.',
      action: Row(
        children: [
          Expanded(
              child: OutlinedButton(
                  onPressed: _undo, child: const Text('마지막 입력 취소'))),
          const SizedBox(width: 8),
          Expanded(
              child:
                  FilledButton(onPressed: _startNew, child: const Text('초기화'))),
        ],
      ),
    );
  }

  Widget _outOfTurnsCard() {
    return _resultCard(
      icon: Icons.flag_outlined,
      color: Colors.orange,
      title: '시도를 모두 사용했어요',
      body: '아래 남은 후보 중에 정답이 있습니다. 초기화로 다시 시도하세요.',
      action: _resetButton(),
    );
  }

  Widget _resetButton() => SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _startNew,
          icon: const Icon(Icons.refresh),
          style: FilledButton.styleFrom(backgroundColor: _correct),
          label: const Text('초기화 (새 게임)'),
        ),
      );

  Widget _resultCard({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: color.withValues(alpha: 0.9))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 13, height: 1.5)),
          if (action != null) ...[const SizedBox(height: 12), action],
        ],
      ),
    );
  }
}

/// 한 행. [marks]==null 이면 빈 행.
class _GuessRow extends StatelessWidget {
  final List<String> jamo;
  final List<Mark>? marks;
  final bool editable;
  final void Function(int index)? onTapCell;
  final String? cellKeyPrefix;
  final double cellSize;
  final double gap;

  const _GuessRow({
    required this.jamo,
    required this.marks,
    required this.cellSize,
    required this.gap,
    this.editable = false,
    this.onTapCell,
    this.cellKeyPrefix,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < jamo.length; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gap),
            child: _Cell(
              key: cellKeyPrefix == null
                  ? null
                  : ValueKey('${cellKeyPrefix}_$i'),
              text: jamo[i],
              mark: marks == null ? null : marks![i],
              editable: editable,
              onTap: onTapCell == null ? null : () => onTapCell!(i),
              size: cellSize,
            ),
          ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final Mark? mark;
  final bool editable;
  final VoidCallback? onTap;
  final double size;

  const _Cell({
    super.key,
    required this.text,
    required this.mark,
    required this.size,
    this.editable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final filled = mark != null;
    final bg = filled ? _markColor(mark!) : _empty;
    final fg = filled ? Colors.white : Colors.black87;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(size * 0.18),
          border: Border.all(
            color: editable
                ? _correct.withValues(alpha: 0.6)
                : (filled ? bg : _emptyBorder),
            width: editable ? 2 : 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(text,
            style: TextStyle(
                fontSize: size * 0.45,
                fontWeight: FontWeight.bold,
                color: fg)),
      ),
    );
  }
}

class _KbKey extends StatelessWidget {
  final String jamo;
  final Mark? mark;
  final double width;
  const _KbKey({required this.jamo, required this.mark, this.width = 30});

  @override
  Widget build(BuildContext context) {
    final filled = mark != null;
    final bg = filled ? _markColor(mark!) : Colors.white;
    final fg = filled ? Colors.white : Colors.black54;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: width,
      height: width * 1.25,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: filled ? bg : _emptyBorder),
      ),
      alignment: Alignment.center,
      child: Text(jamo,
          style: TextStyle(
              fontSize: width * 0.5, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
