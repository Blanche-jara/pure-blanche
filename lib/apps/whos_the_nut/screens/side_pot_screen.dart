import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SidePotScreen extends StatefulWidget {
  const SidePotScreen({super.key});

  @override
  State<SidePotScreen> createState() => _SidePotScreenState();
}

class _SidePotScreenState extends State<SidePotScreen> {
  final _rng = Random();

  List<_Player> _players = const [];
  Set<int> _winners = const {};
  Map<int, TextEditingController> _answerCtrls = {};

  /// null = not yet submitted
  _GradeResult? _grade;

  bool _hardMode = false;

  // Theme-derived colors based on hard mode
  Color get _accent =>
      _hardMode ? Colors.red.shade300 : Colors.amber.shade300;
  Color get _feltBg =>
      _hardMode ? const Color(0xFF2E0E0E) : const Color(0xFF0E2E0E);
  Color get _feltBorder =>
      _hardMode ? Colors.red.shade900 : Colors.green.shade900;
  Color get _feltLabel =>
      _hardMode ? Colors.red.shade300 : Colors.green.shade300;

  @override
  void initState() {
    super.initState();
    _newScenario();
  }

  @override
  void dispose() {
    for (final c in _answerCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Generate a random side-pot scenario.
  /// - 2~4 players
  /// - Each player's chip-in is a multiple of 100 (5..50 → ×100 = 500..5000)
  /// - At least one winner is NOT the chip leader (so the puzzle is non-trivial:
  ///   if the chip leader were the only winner, the answer would just be the total pot).
  /// - 1 winner most of the time, 2-way chop occasionally.
  void _newScenario() {
    final n = 2 + _rng.nextInt(3); // 2..4
    final players = List.generate(n, (i) {
      final chips = (5 + _rng.nextInt(46)) * 100; // 500..5000 step 100
      return _Player(name: 'P${i + 1}', chips: chips);
    });

    // Make sure not all players have identical chips.
    final unique = players.map((p) => p.chips).toSet();
    if (unique.length == 1) {
      players[0] = _Player(
        name: players[0].name,
        chips: players[0].chips + 100 * (1 + _rng.nextInt(5)),
      );
    }

    // Indices of players whose stack is strictly less than the leader.
    final maxChips =
        players.map((p) => p.chips).reduce((a, b) => a > b ? a : b);
    final shortStackIdxs = [
      for (int i = 0; i < players.length; i++)
        if (players[i].chips < maxChips) i
    ];

    final winners = <int>{};
    // Force one winner to be a short stack (avoids "leader sweeps everything")
    winners.add(shortStackIdxs[_rng.nextInt(shortStackIdxs.length)]);

    // Optional 2-way chop
    final allowChop = _rng.nextDouble() < 0.25 && n >= 3;
    if (allowChop) {
      while (winners.length < 2) {
        winners.add(_rng.nextInt(n));
      }
    }

    // Dispose old controllers
    if (mounted) {
      for (final c in _answerCtrls.values) {
        c.dispose();
      }
    }

    setState(() {
      _players = players;
      _winners = winners;
      _answerCtrls = {
        for (int i = 0; i < players.length; i++)
          i: TextEditingController(),
      };
      _grade = null;
    });
  }

  void _submit() {
    final correct = _resolveAwards(_players, _winners);
    final user = <int, int>{};
    for (final entry in _answerCtrls.entries) {
      user[entry.key] = int.tryParse(entry.value.text.trim()) ?? 0;
    }
    final perPlayer = <int, bool>{
      for (int i = 0; i < _players.length; i++)
        i: (user[i] ?? 0) == (correct[i] ?? 0),
    };
    final allCorrect = perPlayer.values.every((v) => v);
    setState(() {
      _grade = _GradeResult(
        userAwards: user,
        correctAwards: correct,
        perPlayer: perPlayer,
        allCorrect: allCorrect,
        pots: _computePots(_players),
      );
    });
  }

  // Pot algorithm — same as before.
  List<_Pot> _computePots(List<_Player> players) {
    final levels =
        players.map((p) => p.chips).where((c) => c > 0).toSet().toList()..sort();
    int prev = 0;
    final pots = <_Pot>[];
    for (final level in levels) {
      final contributors =
          players.where((p) => p.chips >= level).toList(growable: false);
      final amount = (level - prev) * contributors.length;
      pots.add(_Pot(amount: amount, eligible: contributors.toList()));
      prev = level;
    }
    return pots;
  }

  /// For each player, total awarded chips given winners + scenario.
  /// If a pot has no eligible winners, the contribution is returned
  /// to each contributing player (real-poker uncontested return).
  Map<int, int> _resolveAwards(List<_Player> players, Set<int> winners) {
    final pots = _computePots(players);
    final winnerSet = winners.map((i) => players[i]).toSet();
    final awards = <int, int>{for (int i = 0; i < players.length; i++) i: 0};
    for (final pot in pots) {
      final eligibleWinners =
          pot.eligible.where((p) => winnerSet.contains(p)).toList();
      if (eligibleWinners.isEmpty) {
        // Uncontested → each eligible contributor gets their stake back.
        final per = pot.amount ~/ pot.eligible.length;
        for (final p in pot.eligible) {
          final idx = players.indexOf(p);
          awards[idx] = (awards[idx] ?? 0) + per;
        }
        continue;
      }
      final share = pot.amount ~/ eligibleWinners.length;
      final remainder = pot.amount - share * eligibleWinners.length;
      for (int j = 0; j < eligibleWinners.length; j++) {
        final extra = j < remainder ? 1 : 0;
        final idx = players.indexOf(eligibleWinners[j]);
        awards[idx] = (awards[idx] ?? 0) + share + extra;
      }
    }
    return awards;
  }

  @override
  Widget build(BuildContext context) {
    final totalPot = _players.fold<int>(0, (s, p) => s + p.chips);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: SCENARIO label + HARD MODE toggle
          Row(
            children: [
              _label('SCENARIO'),
              const Spacer(),
              _HardModeToggle(
                value: _hardMode,
                onChanged: (v) => setState(() {
                  _hardMode = v;
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '각 플레이어가 얻는 칩 수를 입력하세요 (단위: 칩)',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '· WIN이 여러 명이면 쇼다운 동률(chop) → 자격 있는 팟을 분배\n'
            '· 자격 있는 승자가 없는 팟은 컨트리뷰터에게 환급',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 11,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),

          // Total pot (read-only)
          _totalPotBanner(totalPot),

          const SizedBox(height: 16),

          // Player rows
          ..._players.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            final isWinner = _winners.contains(i);
            final ctrl = _answerCtrls[i]!;
            final result = _grade?.perPlayer[i];
            final correct = _grade?.correctAwards[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PlayerQuizRow(
                player: p,
                isWinner: isWinner,
                controller: ctrl,
                graded: result,
                correctAward: correct,
                locked: _grade != null,
              ),
            );
          }),

          const SizedBox(height: 18),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: 'NEW SCENARIO',
                  icon: Icons.shuffle,
                  primary: false,
                  onTap: _newScenario,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: _ActionBtn(
                  label: _grade == null ? 'SUBMIT' : 'GRADED',
                  icon: Icons.check,
                  primary: true,
                  onTap: _grade == null ? _submit : null,
                ),
              ),
            ],
          ),

          // Verdict + breakdown
          if (_grade != null) ...[
            const SizedBox(height: 24),
            _VerdictPanel(grade: _grade!),
            const SizedBox(height: 16),
            _BreakdownPanel(grade: _grade!, players: _players),
          ],
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.orbitron(
        color: _accent,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 3,
      ),
    );
  }

  Widget _totalPotBanner(int total) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _feltBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _feltBorder),
        boxShadow: _hardMode
            ? [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.2),
                  blurRadius: 18,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance, color: _feltLabel, size: 18),
          const SizedBox(width: 10),
          Text(
            'TOTAL POT',
            style: GoogleFonts.orbitron(
              color: _feltLabel,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            _hardMode ? '????' : _fmt(total),
            style: TextStyle(
              color: _hardMode ? Colors.red.shade300 : Colors.white,
              fontSize: 22,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              letterSpacing: _hardMode ? 4 : 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Hard mode toggle ─────────────────────────

class _HardModeToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _HardModeToggle({required this.value, required this.onChanged});

  @override
  State<_HardModeToggle> createState() => _HardModeToggleState();
}

class _HardModeToggleState extends State<_HardModeToggle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.value;
    final color = on ? Colors.red.shade300 : Colors.white38;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.onChanged(!on),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: on
                ? Colors.red.shade900.withValues(alpha: 0.35)
                : (_hovered
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.transparent),
            border: Border.all(
              color: on
                  ? Colors.red.shade400
                  : (_hovered ? Colors.white24 : Colors.white12),
              width: on ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: on
                ? [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                on
                    ? Icons.local_fire_department
                    : Icons.local_fire_department_outlined,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'HARD MODE',
                style: GoogleFonts.orbitron(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Models ─────────────────────────

class _Player {
  final String name;
  final int chips;
  _Player({required this.name, required this.chips});
}

class _Pot {
  final int amount;
  final List<_Player> eligible;
  _Pot({required this.amount, required this.eligible});
}

class _GradeResult {
  final Map<int, int> userAwards;
  final Map<int, int> correctAwards;
  final Map<int, bool> perPlayer;
  final bool allCorrect;
  final List<_Pot> pots;
  _GradeResult({
    required this.userAwards,
    required this.correctAwards,
    required this.perPlayer,
    required this.allCorrect,
    required this.pots,
  });
}

// ───────────────────────── Player quiz row ─────────────────────────

class _PlayerQuizRow extends StatelessWidget {
  final _Player player;
  final bool isWinner;
  final TextEditingController controller;
  final bool? graded;
  final int? correctAward;
  final bool locked;

  const _PlayerQuizRow({
    required this.player,
    required this.isWinner,
    required this.controller,
    required this.graded,
    required this.correctAward,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isWinner ? Colors.green : Colors.white24;
    Color resultColor = Colors.transparent;
    IconData? resultIcon;
    if (graded != null) {
      resultColor = graded! ? Colors.green.shade400 : Colors.red.shade400;
      resultIcon = graded! ? Icons.check_circle_outline : Icons.cancel_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: graded == null
              ? (isWinner ? Colors.green.shade700 : Colors.white12)
              : resultColor.withValues(alpha: 0.5),
          width: graded == null ? (isWinner ? 1.5 : 1) : 1.5,
        ),
      ),
      child: Row(
        children: [
          // Name
          SizedBox(
            width: 48,
            child: Text(
              player.name,
              style: GoogleFonts.rajdhani(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Chips in pot
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.savings_outlined, color: Colors.white38, size: 14),
                const SizedBox(width: 6),
                Text(
                  _fmt(player.chips),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Winner badge (read-only)
          if (isWinner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.emoji_events, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'WIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'LOSE',
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const Spacer(),
          // Award input
          SizedBox(
            width: 120,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              enabled: !locked,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: graded == null
                    ? Colors.white
                    : resultColor,
                fontSize: 18,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                hintText: '?',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: graded == null
                        ? Colors.white12
                        : resultColor.withValues(alpha: 0.5),
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: resultColor.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.amber.shade300),
                ),
                suffixText: ' chips',
                suffixStyle: TextStyle(
                  color: Colors.white24,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          // Result icon + correct value
          if (graded != null) ...[
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(resultIcon, color: resultColor, size: 22),
                if (graded == false)
                  Text(
                    _fmt(correctAward ?? 0),
                    style: TextStyle(
                      color: Colors.green.shade300,
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────── Verdict ─────────────────────────

class _VerdictPanel extends StatelessWidget {
  final _GradeResult grade;
  const _VerdictPanel({required this.grade});

  @override
  Widget build(BuildContext context) {
    final color =
        grade.allCorrect ? Colors.green.shade400 : Colors.red.shade400;
    final correctCount = grade.perPlayer.values.where((v) => v).length;
    final total = grade.perPlayer.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            grade.allCorrect
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 10),
          Text(
            grade.allCorrect ? 'CORRECT!' : 'INCORRECT',
            style: GoogleFonts.orbitron(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          Text(
            '$correctCount / $total',
            style: GoogleFonts.rajdhani(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Breakdown (explanation) ─────────────────────────

class _BreakdownPanel extends StatelessWidget {
  final _GradeResult grade;
  final List<_Player> players;
  const _BreakdownPanel({required this.grade, required this.players});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BREAKDOWN',
            style: GoogleFonts.orbitron(
              color: Colors.amber.shade300,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          ..._buildPotRows(),
        ],
      ),
    );
  }

  List<Widget> _buildPotRows() {
    final rows = <Widget>[];
    for (int i = 0; i < grade.pots.length; i++) {
      final pot = grade.pots[i];
      final isMain = i == 0;
      final label = isMain ? 'MAIN POT' : 'SIDE POT $i';

      final eligibleNames = pot.eligible.map((p) => p.name).join(', ');

      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text(
                label,
                style: GoogleFonts.orbitron(
                  color: isMain ? Colors.amber.shade300 : Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Text(
              _fmt(pot.amount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'eligible: $eligibleNames',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ));
    }
    return rows;
  }
}

// ───────────────────────── Action button ─────────────────────────

class _ActionBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback? onTap;
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onTap,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    final accent = widget.primary ? Colors.green : Colors.amber.shade700;
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: widget.primary
                ? (disabled
                    ? Colors.white12
                    : (_hovered ? Colors.green.shade600 : Colors.green.shade700))
                : Colors.transparent,
            border: Border.all(
              color: disabled
                  ? Colors.white24
                  : (_hovered ? accent : accent.withValues(alpha: 0.6)),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: disabled
                    ? Colors.white24
                    : (widget.primary ? Colors.white : accent),
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: GoogleFonts.orbitron(
                  color: disabled
                      ? Colors.white24
                      : (widget.primary ? Colors.white : accent),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Helpers ─────────────────────────

String _fmt(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
