import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/playing_card.dart';
import '../models/hand_evaluator.dart';
import '../models/restriction.dart';
import '../widgets/poker_card.dart';

class NutHandScreen extends StatefulWidget {
  final bool hardMode;
  const NutHandScreen({super.key, this.hardMode = false});

  @override
  State<NutHandScreen> createState() => _NutHandScreenState();
}

class _NutHandScreenState extends State<NutHandScreen> {
  final _rng = Random();

  /// 5 community cards
  late List<PlayingCard> _community;

  /// Easy mode: up to 2 cards.
  /// Hard mode: 3 rows × up to 2 cards each (1st, 2nd, 3rd nut).
  /// Each row is independent — the same card can appear in multiple rows
  /// (each represents a separate hypothetical hand).
  late List<List<PlayingCard>> _slots;

  /// Index of the row receiving new card additions.
  int _activeRow = 0;

  /// Hard mode only — top 3 distinct hand ranks possible.
  List<HandRank>? _topNutRanks;

  /// Easy result.
  _Result? _result;

  /// Hard result.
  _HardResult? _hardResult;

  // ── EXTRA HARD MODE state ──
  /// Consecutive perfect submissions in hard mode.
  int _streak = 0;
  static const _streakUnlock = 5;

  /// Once unlocked, the EXTRA HARD button is visible for the whole session.
  bool _extraHardUnlocked = false;

  /// Whether EXTRA HARD is currently active (toggleable after unlock).
  bool _extraHardActive = false;

  /// Active restrictions for the current hand (empty in normal hard mode).
  List<Restriction> _activeRestrictions = const [];

  bool get _hard => widget.hardMode;
  int get _slotCount => _hard ? 3 : 1;

  @override
  void initState() {
    super.initState();
    _newHand();
  }

  void _newHand() {
    // Try generating a scenario; if EXTRA HARD restrictions yield <3 distinct
    // nut ranks (or zero feasible holes), retry up to a few times with new
    // restrictions / community.
    List<PlayingCard> community = [];
    List<HandRank> topNuts = const [];
    List<Restriction> restrictions = const [];

    for (int attempt = 0; attempt < 20; attempt++) {
      final deck = [...kAllCards]..shuffle(_rng);
      community = deck.take(5).toList();
      restrictions =
          _extraHardActive ? pickRandomRestrictions(_rng, maxCount: 3) : const [];
      if (!_hard) {
        topNuts = const [];
        break;
      }
      topNuts = _computeTopNutRanks(community, restrictions);
      if (topNuts.length >= 3) break;
    }

    setState(() {
      _community = community;
      _activeRestrictions = restrictions;
      _slots = List.generate(_slotCount, (_) => <PlayingCard>[]);
      _activeRow = 0;
      _topNutRanks = _hard ? topNuts : null;
      _result = null;
      _hardResult = null;
    });
  }

  /// Returns the top 3 distinct HandRanks achievable with any hole-card pair,
  /// filtered by the given restrictions.
  List<HandRank> _computeTopNutRanks(
    List<PlayingCard> community,
    List<Restriction> restrictions,
  ) {
    final flopOnly = restrictions.any((r) => r.flopOnly);
    final available =
        kAllCards.where((c) => !community.contains(c)).toList();
    final allRanks = <HandRank>{};
    for (int i = 0; i < available.length; i++) {
      for (int j = i + 1; j < available.length; j++) {
        final hole = [available[i], available[j]];
        // Hole-card filter
        if (!restrictions.every((r) => r.allowsHole(hole))) continue;
        final rank = evaluateWithBoard(hole, community, flopOnly: flopOnly);
        // Made-hand filter
        if (!restrictions.every((r) => r.allowsHand(rank))) continue;
        allRanks.add(rank);
      }
    }
    final sorted = allRanks.toList()..sort((a, b) => b.compareTo(a));
    return sorted.take(3).toList();
  }

  /// Tap a card in the deck. Toggles within the ACTIVE row only.
  /// Each row is independent — same card can be in multiple rows.
  void _toggle(PlayingCard card) {
    if (_community.contains(card)) return;
    if (_result != null || _hardResult != null) return;

    setState(() {
      final activeSlot = _slots[_activeRow];
      if (activeSlot.contains(card)) {
        activeSlot.remove(card);
      } else if (activeSlot.length < 2) {
        activeSlot.add(card);
        // Auto-advance to next non-full row (forward only)
        if (activeSlot.length == 2) {
          for (int r = _activeRow + 1; r < _slots.length; r++) {
            if (_slots[r].length < 2) {
              _activeRow = r;
              break;
            }
          }
        }
      }
    });
  }

  void _setActiveRow(int row) {
    setState(() => _activeRow = row);
  }

  void _removeFromRow(int row, PlayingCard card) {
    if (_result != null || _hardResult != null) return;
    setState(() {
      _slots[row].remove(card);
      _activeRow = row;
    });
  }

  bool get _allSlotsFull =>
      _slots.every((s) => s.length == 2);

  int get _filledCount =>
      _slots.fold(0, (n, s) => n + s.length);

  void _submit() {
    if (!_allSlotsFull) return;

    if (_hard) {
      final flopOnly = _activeRestrictions.any((r) => r.flopOnly);
      final results = <bool>[];
      final userRanks = <HandRank>[];
      final violations = <bool>[]; // true = restriction violated
      for (int i = 0; i < 3; i++) {
        final hole = _slots[i];
        // Check restrictions on the hole itself
        final holeOK =
            _activeRestrictions.every((r) => r.allowsHole(hole));
        final r =
            evaluateWithBoard(hole, _community, flopOnly: flopOnly);
        final handOK =
            _activeRestrictions.every((rr) => rr.allowsHand(r));
        userRanks.add(r);
        violations.add(!holeOK || !handOK);
        results.add(holeOK &&
            handOK &&
            _topNutRanks != null &&
            r == _topNutRanks![i]);
      }
      final allCorrect = results.every((v) => v);

      setState(() {
        // Streak tracking — only counts when not in EXTRA HARD,
        // since restrictions make scenarios easier-to-fail.
        if (!_extraHardActive) {
          if (allCorrect) {
            _streak++;
            if (_streak >= _streakUnlock) _extraHardUnlocked = true;
          } else {
            _streak = 0;
          }
        }
        _hardResult = _HardResult(
          userRanks: userRanks,
          topRanks: _topNutRanks!,
          perRow: results,
          violations: violations,
        );
      });
    } else {
      final userRank = bestOfSeven([..._slots[0], ..._community]);
      final nutRank = findNutRank(_community);
      final isNut = userRank.compareTo(nutRank) == 0;
      setState(() {
        _result = _Result(
          userRank: userRank,
          nutRank: nutRank,
          isNut: isNut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isNarrow = size.width < 720;
    final cardW = isNarrow ? 36.0 : 44.0;
    final heroW = isNarrow ? 52.0 : 64.0;
    final accent =
        _extraHardActive ? Colors.red.shade300 : Colors.amber.shade300;
    final feltBg = _extraHardActive
        ? const Color(0xFF2E0E0E)
        : const Color(0xFF0E2E0E);
    final feltBorder = _extraHardActive
        ? Colors.red.shade900
        : Colors.green.shade900;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hard-mode HUD (streak + EXTRA HARD unlock/toggle)
          if (_hard) ...[
            _StreakHud(
              streak: _streak,
              max: _streakUnlock,
              unlocked: _extraHardUnlocked,
              extraActive: _extraHardActive,
              onToggleExtra: _extraHardUnlocked
                  ? () {
                      setState(() => _extraHardActive = !_extraHardActive);
                      _newHand();
                    }
                  : null,
            ),
            const SizedBox(height: 16),
          ],

          // Active restrictions chips (EXTRA HARD only)
          if (_extraHardActive && _activeRestrictions.isNotEmpty) ...[
            _sectionLabel('SPECIAL RESTRICTIONS', accent),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _activeRestrictions
                  .map((r) => _RestrictionChip(label: r.label))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

          _sectionLabel('COMMUNITY', accent),
          const SizedBox(height: 12),
          _felt(
            bg: feltBg,
            border: feltBorder,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: _community
                  .map((c) => PokerCardView(card: c, width: heroW))
                  .toList(),
            ),
          ),
          const SizedBox(height: 28),

          _sectionLabel(_hard ? 'TOP 3 NUT HANDS' : 'YOUR HAND', accent),
          const SizedBox(height: 4),
          Text(
            _hard
                ? 'Pick 1st, 2nd, 3rd nut hands (2 cards each, total 6)'
                : 'Pick 2 cards to make the nuts',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),

          // Slot rows
          for (int row = 0; row < _slotCount; row++) ...[
            _SlotRow(
              label: _hard ? _placeLabel(row) : null,
              cards: _slots[row],
              cardWidth: heroW,
              isActive: _hard && row == _activeRow,
              showActiveStyle: _hard,
              onActivate: _hard ? () => _setActiveRow(row) : null,
              onRemove: (c) => _removeFromRow(row, c),
              graded: _hardResult?.perRow[row],
            ),
            if (row < _slotCount - 1) const SizedBox(height: 10),
          ],

          const SizedBox(height: 28),

          _sectionLabel('SELECT FROM DECK', accent),
          const SizedBox(height: 12),
          _DeckGrid(
            cardWidth: cardW,
            community: _community,
            // Only the ACTIVE row's selections are highlighted in the deck.
            selected: _slots[_activeRow].toSet(),
            onTap: _toggle,
          ),

          const SizedBox(height: 28),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: 'NEW HAND',
                  icon: Icons.shuffle,
                  primary: false,
                  onTap: _newHand,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: _ActionBtn(
                  label: _allSlotsFull
                      ? 'SUBMIT'
                      : 'PICK ${_slotCount * 2 - _filledCount} MORE',
                  icon: Icons.check,
                  primary: true,
                  onTap: _allSlotsFull &&
                          _result == null &&
                          _hardResult == null
                      ? _submit
                      : null,
                ),
              ),
            ],
          ),

          // Result panels
          if (_result != null) ...[
            const SizedBox(height: 24),
            _ResultPanel(result: _result!),
          ],
          if (_hardResult != null) ...[
            const SizedBox(height: 24),
            _HardResultPanel(result: _hardResult!),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, Color accent) {
    return Text(
      text,
      style: GoogleFonts.orbitron(
        color: accent,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 3,
      ),
    );
  }

  Widget _felt({required Widget child, required Color bg, required Color border}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}

// ───────────────────────── Slot row ─────────────────────────

class _SlotRow extends StatelessWidget {
  final String? label;
  final List<PlayingCard> cards;
  final double cardWidth;
  final bool isActive;
  final bool showActiveStyle;
  final VoidCallback? onActivate;
  final ValueChanged<PlayingCard> onRemove;
  final bool? graded;

  const _SlotRow({
    required this.label,
    required this.cards,
    required this.cardWidth,
    required this.isActive,
    required this.showActiveStyle,
    required this.onActivate,
    required this.onRemove,
    required this.graded,
  });

  @override
  Widget build(BuildContext context) {
    Color resultColor = Colors.transparent;
    IconData? resultIcon;
    if (graded != null) {
      resultColor = graded! ? Colors.green.shade400 : Colors.red.shade400;
      resultIcon = graded! ? Icons.check_circle_outline : Icons.cancel_outlined;
    }

    final labelColor = graded != null
        ? resultColor
        : (isActive ? Colors.amber.shade300 : Colors.white38);

    Widget rowChild = Row(
      children: [
        if (label != null) ...[
          SizedBox(
            width: 64,
            child: Text(
              label!,
              style: GoogleFonts.orbitron(
                color: labelColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ],
        for (int i = 0; i < 2; i++) ...[
          if (i < cards.length)
            PokerCardView(
              card: cards[i],
              width: cardWidth,
              selected: true,
              onTap: graded == null ? () => onRemove(cards[i]) : null,
            )
          else
            EmptyCardSlot(width: cardWidth),
          const SizedBox(width: 10),
        ],
        if (resultIcon != null) Icon(resultIcon, color: resultColor, size: 24),
      ],
    );

    if (showActiveStyle) {
      rowChild = AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.amber.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? Colors.amber.shade300 : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: rowChild,
      );
    }

    if (onActivate != null) {
      rowChild = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onActivate,
          child: rowChild,
        ),
      );
    }

    return rowChild;
  }
}

// ───────────────────────── Deck grid ─────────────────────────

class _DeckGrid extends StatelessWidget {
  final double cardWidth;
  final List<PlayingCard> community;
  final Set<PlayingCard> selected;
  final ValueChanged<PlayingCard> onTap;

  const _DeckGrid({
    required this.cardWidth,
    required this.community,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: Suit.values.map((suit) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (int rank = 2; rank <= 14; rank++)
                  _gridCell(PlayingCard(rank, suit)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _gridCell(PlayingCard card) {
    final inCommunity = community.contains(card);
    final isSelected = selected.contains(card);
    return PokerCardView(
      card: card,
      width: cardWidth,
      selected: isSelected,
      disabled: inCommunity,
      onTap: () => onTap(card),
    );
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

// ───────────────────────── Easy result ─────────────────────────

class _Result {
  final HandRank userRank;
  final HandRank nutRank;
  final bool isNut;
  const _Result({
    required this.userRank,
    required this.nutRank,
    required this.isNut,
  });
}

class _ResultPanel extends StatelessWidget {
  final _Result result;
  const _ResultPanel({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.isNut ? Colors.green.shade400 : Colors.red.shade400;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.isNut
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                color: color,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                result.isNut ? 'NUTS!' : 'NOT THE NUTS',
                style: GoogleFonts.orbitron(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _row('YOUR HAND', result.userRank.category.label, Colors.white),
          const SizedBox(height: 6),
          _row(
            'BEST POSSIBLE',
            result.nutRank.category.label,
            Colors.amber.shade300,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color valueColor) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Hard result ─────────────────────────

class _HardResult {
  final List<HandRank> userRanks;
  final List<HandRank> topRanks;
  final List<bool> perRow;
  final List<bool> violations; // true = pair violates a restriction
  const _HardResult({
    required this.userRanks,
    required this.topRanks,
    required this.perRow,
    this.violations = const [false, false, false],
  });

  bool get allCorrect => perRow.every((v) => v);
  int get score => perRow.where((v) => v).length;
}

class _HardResultPanel extends StatelessWidget {
  final _HardResult result;
  const _HardResultPanel({required this.result});

  @override
  Widget build(BuildContext context) {
    final color =
        result.allCorrect ? Colors.green.shade400 : Colors.red.shade400;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.allCorrect
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                color: color,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                result.allCorrect ? 'PERFECT!' : 'INCORRECT',
                style: GoogleFonts.orbitron(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Text(
                '${result.score} / 3',
                style: GoogleFonts.rajdhani(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _hardRow(
                place: i,
                userRank: result.userRanks[i],
                topRank: result.topRanks[i],
                correct: result.perRow[i],
              ),
            ),
        ],
      ),
    );
  }

  Widget _hardRow({
    required int place,
    required HandRank userRank,
    required HandRank topRank,
    required bool correct,
  }) {
    final c = correct ? Colors.green.shade400 : Colors.red.shade400;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            _placeLabel(place),
            style: GoogleFonts.orbitron(
              color: c,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
        ),
        Icon(
          correct ? Icons.check : Icons.close,
          color: c,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOU: ${userRank.category.label}',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              if (!correct)
                Text(
                  'CORRECT: ${topRank.category.label}',
                  style: TextStyle(
                    color: Colors.amber.shade300,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Helpers ─────────────────────────

String _placeLabel(int placeIndex) {
  switch (placeIndex) {
    case 0:
      return '1ST NUT';
    case 1:
      return '2ND NUT';
    case 2:
      return '3RD NUT';
    default:
      return '${placeIndex + 1}TH';
  }
}

// ───────────────────────── Streak HUD ─────────────────────────

class _StreakHud extends StatelessWidget {
  final int streak;
  final int max;
  final bool unlocked;
  final bool extraActive;
  final VoidCallback? onToggleExtra;

  const _StreakHud({
    required this.streak,
    required this.max,
    required this.unlocked,
    required this.extraActive,
    required this.onToggleExtra,
  });

  @override
  Widget build(BuildContext context) {
    final cappedStreak = streak.clamp(0, max);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: extraActive
            ? Colors.red.shade900.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: extraActive ? Colors.red.shade400 : Colors.white12,
          width: extraActive ? 1.5 : 1,
        ),
        boxShadow: extraActive
            ? [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Streak flames
          if (!extraActive) ...[
            Text(
              'STREAK',
              style: GoogleFonts.orbitron(
                color: Colors.amber.shade300,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(width: 10),
            Row(
              children: List.generate(max, (i) {
                final lit = i < cappedStreak;
                return Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(
                    lit
                        ? Icons.local_fire_department
                        : Icons.local_fire_department_outlined,
                    size: 16,
                    color: lit ? Colors.amber.shade300 : Colors.white24,
                  ),
                );
              }),
            ),
            const SizedBox(width: 8),
            Text(
              '$cappedStreak / $max',
              style: GoogleFonts.rajdhani(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else ...[
            Icon(Icons.warning_amber_rounded,
                color: Colors.red.shade300, size: 18),
            const SizedBox(width: 8),
            Text(
              'EXTRA HARD ACTIVE',
              style: GoogleFonts.orbitron(
                color: Colors.red.shade300,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
              ),
            ),
          ],
          const Spacer(),
          // EXTRA HARD button (visible after unlock)
          if (unlocked) _ExtraHardBtn(active: extraActive, onTap: onToggleExtra),
        ],
      ),
    );
  }
}

class _ExtraHardBtn extends StatefulWidget {
  final bool active;
  final VoidCallback? onTap;
  const _ExtraHardBtn({required this.active, required this.onTap});

  @override
  State<_ExtraHardBtn> createState() => _ExtraHardBtnState();
}

class _ExtraHardBtnState extends State<_ExtraHardBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.active;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: on
                ? Colors.red.shade700
                : (_hovered
                    ? Colors.red.shade900.withValues(alpha: 0.4)
                    : Colors.transparent),
            border: Border.all(color: Colors.red.shade400, width: 1.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.whatshot,
                size: 14,
                color: on ? Colors.white : Colors.red.shade300,
              ),
              const SizedBox(width: 6),
              Text(
                on ? 'EXIT EXTRA' : 'EXTRA HARD',
                style: GoogleFonts.orbitron(
                  color: on ? Colors.white : Colors.red.shade300,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Restriction chip ─────────────────────────

class _RestrictionChip extends StatelessWidget {
  final String label;
  const _RestrictionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.3),
        border: Border.all(color: Colors.red.shade400),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.orbitron(
          color: Colors.red.shade200,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
