import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/nut_hand_screen.dart';
import 'screens/side_pot_screen.dart';

/// Entry widget for "Who's the Nut?" — poker mini-games.
class WhosTheNutApp extends StatefulWidget {
  const WhosTheNutApp({super.key});

  @override
  State<WhosTheNutApp> createState() => _WhosTheNutAppState();
}

class _WhosTheNutAppState extends State<WhosTheNutApp> {
  int _mode = 0; // 0 = Nut Hand, 1 = Side Pot

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A1A0A),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A1A0A),
        body: Column(
          children: [
            _buildHeader(),
            _buildModeTabs(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _mode == 0
                    ? const NutHandScreen(key: ValueKey('nut'))
                    : const SidePotScreen(key: ValueKey('pot')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(
        children: [
          Icon(Icons.casino, color: Colors.amber.shade300, size: 22),
          const SizedBox(width: 10),
          Text(
            "WHO'S THE NUT?",
            style: GoogleFonts.orbitron(
              color: Colors.amber.shade300,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _ModeTab(
              label: 'NUT HAND',
              hint: '커뮤니티 5장 → 너트 핸드 맞히기',
              selected: _mode == 0,
              onTap: () => setState(() => _mode = 0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ModeTab(
              label: 'SIDE POT',
              hint: '올인 칩양 → 분배 계산',
              selected: _mode == 1,
              onTap: () => setState(() => _mode = 1),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatefulWidget {
  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;
  const _ModeTab({
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ModeTab> createState() => _ModeTabState();
}

class _ModeTabState extends State<_ModeTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? Colors.green.shade800.withValues(alpha: 0.4)
                : (_hovered
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? Colors.green.shade500
                  : (_hovered ? Colors.white24 : Colors.white12),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: GoogleFonts.orbitron(
                  color: selected ? Colors.green.shade300 : Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.hint,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
