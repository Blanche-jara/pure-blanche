import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/playing_card.dart';

/// Visual playing card matching the help_screen aesthetic.
///
/// [size] = "small" | "medium" | "large"
/// Selectable variant with selected/disabled states for the deck grid.
class PokerCardView extends StatelessWidget {
  final PlayingCard card;
  final double width;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  const PokerCardView({
    super.key,
    required this.card,
    this.width = 38,
    this.selected = false,
    this.disabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final height = width * 1.42;
    final color = card.isRed ? Colors.red.shade600 : Colors.grey.shade900;
    final cardFace = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: disabled ? Colors.white12 : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: selected
              ? Colors.amber.shade300
              : disabled
                  ? Colors.white12
                  : Colors.transparent,
          width: selected ? 3 : 1,
        ),
        boxShadow: [
          if (!disabled)
            BoxShadow(
              color: selected
                  ? Colors.amber.withValues(alpha: 0.4)
                  : Colors.black26,
              blurRadius: selected ? 10 : 3,
              offset: const Offset(1, 1),
            ),
        ],
      ),
      child: Opacity(
        opacity: disabled ? 0.18 : 1.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              card.rankSymbol,
              style: GoogleFonts.inter(
                color: color,
                fontSize: width * 0.42,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            Text(
              card.suitSymbol,
              style: TextStyle(
                color: color,
                fontSize: width * 0.36,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null || disabled) return cardFace;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: cardFace),
    );
  }
}

/// A blank "slot" for an empty hole card.
class EmptyCardSlot extends StatelessWidget {
  final double width;
  const EmptyCardSlot({super.key, this.width = 56});

  @override
  Widget build(BuildContext context) {
    final height = width * 1.42;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.white24,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Icon(Icons.add, color: Colors.white24, size: width * 0.4),
    );
  }
}
