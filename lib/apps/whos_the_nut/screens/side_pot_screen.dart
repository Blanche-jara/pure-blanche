import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SidePotScreen extends StatefulWidget {
  const SidePotScreen({super.key});

  @override
  State<SidePotScreen> createState() => _SidePotScreenState();
}

class _SidePotScreenState extends State<SidePotScreen> {
  final List<_PlayerInput> _players = [
    _PlayerInput(name: 'P1', chips: 1000),
    _PlayerInput(name: 'P2', chips: 3000),
    _PlayerInput(name: 'P3', chips: 5000),
  ];

  /// Indices of winning players (allows multi-winner = chop)
  final Set<int> _winners = {2};

  List<_Pot>? _pots;

  void _addPlayer() {
    setState(() {
      final n = _players.length + 1;
      _players.add(_PlayerInput(name: 'P$n', chips: 0));
      _pots = null;
    });
  }

  void _removePlayer(int index) {
    setState(() {
      _players.removeAt(index);
      // Reindex winners
      final newWinners = <int>{};
      for (final w in _winners) {
        if (w < index) newWinners.add(w);
        if (w > index) newWinners.add(w - 1);
      }
      _winners
        ..clear()
        ..addAll(newWinners);
      _pots = null;
    });
  }

  void _toggleWinner(int index) {
    setState(() {
      if (_winners.contains(index)) {
        _winners.remove(index);
      } else {
        _winners.add(index);
      }
      _pots = null;
    });
  }

  void _calculate() {
    if (_players.isEmpty || _winners.isEmpty) return;
    final pots = _computePots(_players);
    setState(() {
      _pots = pots;
    });
  }

  /// Side-pot algorithm:
  /// Sort players by chip-in ascending. Each unique level creates a pot
  /// containing (level − prev) × (count of players who reached that level).
  /// Eligible winners for that pot are the players whose chip-in ≥ level.
  List<_Pot> _computePots(List<_PlayerInput> players) {
    final levels = players.map((p) => p.chips).where((c) => c > 0).toSet().toList()
      ..sort();
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('PLAYERS (ALL-IN AMOUNTS)'),
          const SizedBox(height: 12),
          ..._players.asMap().entries.map((entry) {
            final i = entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PlayerRow(
                input: entry.value,
                isWinner: _winners.contains(i),
                onWinnerTap: () => _toggleWinner(i),
                onRemove: _players.length > 2 ? () => _removePlayer(i) : null,
                onChanged: () => setState(() => _pots = null),
              ),
            );
          }),
          const SizedBox(height: 8),
          _AddButton(onTap: _addPlayer),

          const SizedBox(height: 24),

          _ActionBtn(
            label: 'CALCULATE',
            icon: Icons.calculate,
            onTap: _winners.isNotEmpty ? _calculate : null,
          ),

          if (_pots != null) ...[
            const SizedBox(height: 28),
            _label('RESULT'),
            const SizedBox(height: 12),
            _ResultBoard(
              players: _players,
              pots: _pots!,
              winners: _winners,
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.orbitron(
        color: Colors.amber.shade300,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 3,
      ),
    );
  }
}

// ───────────────────────── Player row ─────────────────────────

class _PlayerInput {
  String name;
  int chips;
  _PlayerInput({required this.name, required this.chips});
}

class _PlayerRow extends StatefulWidget {
  final _PlayerInput input;
  final bool isWinner;
  final VoidCallback onWinnerTap;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const _PlayerRow({
    required this.input,
    required this.isWinner,
    required this.onWinnerTap,
    required this.onChanged,
    this.onRemove,
  });

  @override
  State<_PlayerRow> createState() => _PlayerRowState();
}

class _PlayerRowState extends State<_PlayerRow> {
  late TextEditingController _nameCtrl;
  late TextEditingController _chipsCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.input.name);
    _chipsCtrl = TextEditingController(text: widget.input.chips.toString());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _chipsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.isWinner
              ? Colors.green.shade600
              : Colors.white.withValues(alpha: 0.08),
          width: widget.isWinner ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Name
          SizedBox(
            width: 80,
            child: TextField(
              controller: _nameCtrl,
              style: GoogleFonts.rajdhani(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
                border: InputBorder.none,
              ),
              onChanged: (v) {
                widget.input.name = v;
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),
          // Chips
          Expanded(
            child: TextField(
              controller: _chipsCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                hintText: 'chips',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) {
                widget.input.chips = int.tryParse(v) ?? 0;
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: 12),
          // Winner toggle
          GestureDetector(
            onTap: widget.onWinnerTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isWinner
                    ? Colors.green.shade700
                    : Colors.transparent,
                border: Border.all(
                  color: widget.isWinner
                      ? Colors.green.shade600
                      : Colors.white24,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isWinner
                        ? Icons.emoji_events
                        : Icons.emoji_events_outlined,
                    size: 16,
                    color:
                        widget.isWinner ? Colors.white : Colors.white38,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'WIN',
                    style: TextStyle(
                      color: widget.isWinner ? Colors.white : Colors.white38,
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Remove
          if (widget.onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.white24),
              onPressed: widget.onRemove,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────── Add button ─────────────────────────

class _AddButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: _hovered
                  ? Colors.amber.shade300
                  : Colors.white24,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                color: _hovered ? Colors.amber.shade300 : Colors.white38,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'ADD PLAYER',
                style: TextStyle(
                  color: _hovered ? Colors.amber.shade300 : Colors.white38,
                  fontSize: 12,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Action button ─────────────────────────

class _ActionBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const _ActionBtn({
    required this.label,
    required this.icon,
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
    return MouseRegion(
      cursor:
          disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: disabled
                ? Colors.white12
                : (_hovered ? Colors.green.shade600 : Colors.green.shade700),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: disabled ? Colors.white24 : Colors.white,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: GoogleFonts.orbitron(
                  color: disabled ? Colors.white24 : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Result board ─────────────────────────

class _Pot {
  final int amount;
  final List<_PlayerInput> eligible;
  _Pot({required this.amount, required this.eligible});
}

class _ResultBoard extends StatelessWidget {
  final List<_PlayerInput> players;
  final List<_Pot> pots;
  final Set<int> winners;

  const _ResultBoard({
    required this.players,
    required this.pots,
    required this.winners,
  });

  @override
  Widget build(BuildContext context) {
    final winnerSet = winners.map((i) => players[i]).toSet();
    final awards = <_PlayerInput, int>{};

    final rows = <Widget>[];
    for (int i = 0; i < pots.length; i++) {
      final pot = pots[i];
      final eligibleWinners =
          pot.eligible.where((p) => winnerSet.contains(p)).toList();
      final isMain = i == 0;
      final label = isMain ? 'MAIN POT' : 'SIDE POT $i';

      String distribution;
      if (eligibleWinners.isEmpty) {
        distribution = 'no eligible winner';
      } else if (eligibleWinners.length == 1) {
        final winner = eligibleWinners.first;
        awards[winner] = (awards[winner] ?? 0) + pot.amount;
        distribution = '${winner.name} +${_fmt(pot.amount)}';
      } else {
        // Split (chop)
        final share = pot.amount ~/ eligibleWinners.length;
        final remainder = pot.amount - share * eligibleWinners.length;
        for (int j = 0; j < eligibleWinners.length; j++) {
          final extra = j < remainder ? 1 : 0;
          final w = eligibleWinners[j];
          awards[w] = (awards[w] ?? 0) + share + extra;
        }
        distribution = eligibleWinners
            .map((w) => '${w.name} +${_fmt(share)}')
            .join(' / ');
        if (remainder > 0) {
          distribution += ' (+$remainder odd chip)';
        }
      }

      rows.add(_potRow(
        label: label,
        amount: pot.amount,
        eligible: pot.eligible.map((p) => p.name).join(', '),
        distribution: distribution,
        isMain: isMain,
      ));
    }

    final totalPot = pots.fold<int>(0, (s, p) => s + p.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...rows.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: r,
            )),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0E2E0E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade600),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance,
                      color: Colors.green.shade300, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'TOTAL POT',
                    style: GoogleFonts.orbitron(
                      color: Colors.green.shade300,
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _fmt(totalPot),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...awards.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Icon(Icons.emoji_events,
                            color: Colors.amber.shade300, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          e.key.name,
                          style: GoogleFonts.rajdhani(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '+${_fmt(e.value)}',
                          style: TextStyle(
                            color: Colors.amber.shade300,
                            fontSize: 18,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _potRow({
    required String label,
    required int amount,
    required String eligible,
    required String distribution,
    required bool isMain,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMain
              ? Colors.amber.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.orbitron(
                  color: isMain ? Colors.amber.shade300 : Colors.white60,
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                _fmt(amount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'eligible: $eligible',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            '→ $distribution',
            style: TextStyle(
              color: Colors.green.shade300,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
