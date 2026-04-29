import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/playing_card.dart';
import '../models/hand_evaluator.dart';
import '../widgets/poker_card.dart';

class NutHandScreen extends StatefulWidget {
  const NutHandScreen({super.key});

  @override
  State<NutHandScreen> createState() => _NutHandScreenState();
}

class _NutHandScreenState extends State<NutHandScreen> {
  final _rng = Random();

  /// 5 community cards
  late List<PlayingCard> _community;

  /// Up to 2 selected hole cards
  final List<PlayingCard> _selected = [];

  _Result? _result;

  @override
  void initState() {
    super.initState();
    _newHand();
  }

  void _newHand() {
    final deck = [...kAllCards]..shuffle(_rng);
    setState(() {
      _community = deck.take(5).toList();
      _selected.clear();
      _result = null;
    });
  }

  void _toggle(PlayingCard card) {
    if (_community.contains(card)) return;
    if (_result != null) return;
    setState(() {
      if (_selected.contains(card)) {
        _selected.remove(card);
      } else if (_selected.length < 2) {
        _selected.add(card);
      }
    });
  }

  void _submit() {
    if (_selected.length != 2) return;
    final userRank = bestOfSeven([..._selected, ..._community]);
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isNarrow = size.width < 720;
    final cardW = isNarrow ? 36.0 : 44.0;
    final heroW = isNarrow ? 52.0 : 64.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('COMMUNITY'),
          const SizedBox(height: 12),
          _felt(
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

          _sectionLabel('YOUR HAND'),
          const SizedBox(height: 4),
          Text(
            'Pick 2 cards to make the nuts',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (int i = 0; i < 2; i++) ...[
                if (i < _selected.length)
                  PokerCardView(
                    card: _selected[i],
                    width: heroW,
                    selected: true,
                    onTap: () => _toggle(_selected[i]),
                  )
                else
                  EmptyCardSlot(width: heroW),
                const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 28),

          _sectionLabel('SELECT FROM DECK'),
          const SizedBox(height: 12),
          _DeckGrid(
            cardWidth: cardW,
            community: _community,
            selected: _selected,
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
                  label: _selected.length == 2
                      ? 'SUBMIT'
                      : 'PICK ${2 - _selected.length} MORE',
                  icon: Icons.check,
                  primary: true,
                  onTap: _selected.length == 2 && _result == null ? _submit : null,
                ),
              ),
            ],
          ),

          // Result panel
          if (_result != null) ...[
            const SizedBox(height: 24),
            _ResultPanel(result: _result!),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
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

  Widget _felt({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2E0E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade900),
      ),
      child: child,
    );
  }
}

// ───────────────────────── Deck grid ─────────────────────────

class _DeckGrid extends StatelessWidget {
  final double cardWidth;
  final List<PlayingCard> community;
  final List<PlayingCard> selected;
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

// ───────────────────────── Result panel ─────────────────────────

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
          _resultRow(
            'YOUR HAND',
            result.userRank.category.label,
            Colors.white,
          ),
          const SizedBox(height: 6),
          _resultRow(
            'BEST POSSIBLE',
            result.nutRank.category.label,
            Colors.amber.shade300,
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value, Color valueColor) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(
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
