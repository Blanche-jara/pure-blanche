import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/nut_hand_screen.dart';
import 'screens/side_pot_screen.dart';

/// Entry widget for "Who's the Nut?" — poker mini-games.
///
/// HARD MODE is a global toggle that affects both screens:
///   - Nut Hand: must input top 1st/2nd/3rd nut hands
///   - Side Pot: TOTAL POT hidden, theme tinted red
class WhosTheNutApp extends StatefulWidget {
  const WhosTheNutApp({super.key});

  @override
  State<WhosTheNutApp> createState() => _WhosTheNutAppState();
}

class _WhosTheNutAppState extends State<WhosTheNutApp> {
  int _mode = 0; // 0 = Nut Hand, 1 = Side Pot
  bool _hardMode = false;
  bool _extraHardUnlocked = false;
  bool _extraHardActive = false;

  Future<void> _setHard(bool v) async {
    // Confirm before turning HARD off while EXTRA HARD is active.
    if (!v && _extraHardActive) {
      final confirmed = await _confirmExitExtraHard();
      if (confirmed != true) return;
    }
    setState(() {
      _hardMode = v;
      if (!v) {
        _extraHardActive = false;
        _extraHardUnlocked = false;
      }
    });
  }

  Future<bool?> _confirmExitExtraHard() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.red.shade700, width: 1.5),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.red.shade300, size: 22),
            const SizedBox(width: 10),
            Text(
              'EXIT EXTRA HARD?',
              style: GoogleFonts.orbitron(
                color: Colors.red.shade300,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
        content: const Text(
          'EXTRA HARD MODE가 활성화되어 있습니다.\n그래도 HARD MODE를 종료하시겠습니까?',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.orbitron(
                color: Colors.white54,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'EXIT',
              style: GoogleFonts.orbitron(
                color: Colors.red.shade300,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setUnlocked() {
    setState(() => _extraHardUnlocked = true);
  }

  void _setExtraActive(bool v) {
    setState(() {
      _extraHardActive = v;
      if (v) _extraHardUnlocked = true;
    });
  }

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
                    ? NutHandScreen(
                        key: ValueKey('nut_$_hardMode'),
                        hardMode: _hardMode,
                        extraHardUnlocked: _extraHardUnlocked,
                        extraHardActive: _extraHardActive,
                        onUnlock: _setUnlocked,
                        onSetExtraActive: _setExtraActive,
                      )
                    : SidePotScreen(
                        key: ValueKey('pot_$_hardMode'),
                        hardMode: _hardMode,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final accent = _hardMode ? Colors.red.shade300 : Colors.amber.shade300;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _hardMode ? Icons.local_fire_department : Icons.casino,
              color: accent,
              size: 22,
              key: ValueKey(_hardMode),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "WHO'S THE NUT?",
            style: GoogleFonts.orbitron(
              color: accent,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          HardModeToggle(value: _hardMode, onChanged: _setHard),
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

// ───────────────────────── Global hard-mode toggle ─────────────────────────

class HardModeToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const HardModeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<HardModeToggle> createState() => _HardModeToggleState();
}

class _HardModeToggleState extends State<HardModeToggle> {
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
