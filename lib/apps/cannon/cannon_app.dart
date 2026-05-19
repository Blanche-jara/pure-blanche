import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

/// THE CANNON — dice-themed random number drawer.
///
/// Flow:
///   setup → enter max number (≥2) → START
///   ready → DRAW
///   rolling → dice tumble + number flickers (~1.5s)
///   result → final number shown big; can DRAW again
///
/// Dice count scales with max:
///   2~6:1, 7~12:2, 13~18:3, 19~24:4, ...  (one die per 6 max)
class CannonApp extends StatefulWidget {
  const CannonApp({super.key});

  @override
  State<CannonApp> createState() => _CannonAppState();
}

class _CannonAppState extends State<CannonApp> {
  final _rng = Random();

  /// null = on setup screen
  int? _maxNumber;

  /// Latest result. null = not yet drawn (this session).
  int? _result;

  bool _rolling = false;
  Timer? _rollTimer;

  /// Per-die transient state
  List<int> _diceFaces = const [];
  List<double> _diceAngles = const [];

  int get _numDice {
    if (_maxNumber == null) return 0;
    return ((_maxNumber! - 1) ~/ 6) + 1;
  }

  /// Number to display in the huge result area.
  /// Always equals the sum of currently-rendered dice faces.
  String _displayedNumber() {
    if (_diceFaces.isEmpty) return '?';
    if (_result == null && !_rolling) return '?';
    final sum = _diceFaces.fold<int>(0, (a, b) => a + b);
    return '$sum';
  }

  void _startWithMax(int n) {
    if (n < 2) return;
    setState(() {
      _maxNumber = n;
      _result = null;
      // Initial faces: first die shows 1, others blank (0)
      _diceFaces = List.generate(_numDice, (i) => i == 0 ? 1 : 0);
      _diceAngles = List.generate(_numDice, (_) => 0.0);
    });
  }

  void _resetSetup() {
    _rollTimer?.cancel();
    _rollTimer = null;
    setState(() {
      _maxNumber = null;
      _result = null;
      _rolling = false;
      _diceFaces = const [];
      _diceAngles = const [];
    });
  }

  /// First die rolls 1..6, others roll 0..6.
  /// This way: sum range = 1..6n, every value reachable.
  List<int> _rollOnce(int n) => List.generate(
        n,
        (i) => i == 0 ? (1 + _rng.nextInt(6)) : _rng.nextInt(7),
      );

  void _roll() {
    if (_rolling || _maxNumber == null) return;
    final maxNum = _maxNumber!;
    final n = _numDice;

    // Pre-pick the final dice with rejection sampling: sum must be ≤ maxNum.
    List<int> finalFaces;
    int finalSum;
    int safety = 0;
    do {
      finalFaces = _rollOnce(n);
      finalSum = finalFaces.fold(0, (a, b) => a + b);
      safety++;
    } while (finalSum > maxNum && safety < 2000);

    setState(() {
      _rolling = true;
      _result = null;
    });

    final start = DateTime.now();
    const totalMs = 1700;
    const tickMs = 70;

    _rollTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      if (elapsed >= totalMs) {
        timer.cancel();
        _rollTimer = null;
        setState(() {
          _rolling = false;
          _diceFaces = finalFaces;
          _diceAngles = List.generate(n, (_) => 0.0);
          _result = finalSum;
        });
        return;
      }
      // Tumble: random faces (using the same rule for visual consistency)
      setState(() {
        _diceFaces = _rollOnce(n);
        _diceAngles = List.generate(
          n,
          (_) => (_rng.nextDouble() - 0.5) * 0.6, // ±0.3 rad ≈ ±17°
        );
      });
    });
  }

  @override
  void dispose() {
    _rollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.abyss,
      ),
      child: Scaffold(
        backgroundColor: AppColors.abyss,
        body: SafeArea(
          child: _maxNumber == null ? _buildSetup() : _buildDrawScreen(),
        ),
      ),
    );
  }

  // ───────────────────────── Setup ─────────────────────────

  Widget _buildSetup() {
    return _SetupScreen(
      onStart: _startWithMax,
    );
  }

  // ───────────────────────── Draw ─────────────────────────

  Widget _buildDrawScreen() {
    final size = MediaQuery.sizeOf(context);
    final minDim = min(size.width, size.height);
    final isPortrait = size.height >= size.width;
    final diceSize =
        ((size.width * 0.9 - 24 * (_numDice - 1)) / _numDice).clamp(60.0, 220.0);
    final resultFontSize = isPortrait ? minDim * 0.45 : minDim * 0.55;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Top bar: range label + change-max button
          _topBar(),
          const SizedBox(height: 8),

          // Dice row
          Expanded(
            flex: 4,
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_numDice, (i) {
                    final face = i < _diceFaces.length ? _diceFaces[i] : 1;
                    final angle = i < _diceAngles.length ? _diceAngles[i] : 0.0;
                    return Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: diceSize * 0.08),
                      child: _DiceFace(
                        face: face,
                        size: diceSize,
                        angleRad: angle,
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),

          // Result number (huge) — always equals sum of dice faces
          Expanded(
            flex: 6,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _displayedNumber(),
                  style: GoogleFonts.bebasNeue(
                    fontSize: resultFontSize,
                    fontWeight: FontWeight.w900,
                    color: _rolling
                        ? AppColors.steel
                        : (_result != null
                            ? AppColors.signalGreen
                            : AppColors.warmCharcoal),
                    height: 1.0,
                    shadows: _result != null && !_rolling
                        ? [
                            Shadow(
                              color: AppColors.signalGreen
                                  .withValues(alpha: 0.5),
                              blurRadius: resultFontSize * 0.1,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // DRAW button
          _DrawButton(
            onTap: _rolling ? null : _roll,
            isRolling: _rolling,
            height: minDim * 0.13,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        // Range badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.carbon,
            border: Border.all(color: AppColors.warmCharcoal),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.casino, size: 14, color: AppColors.signalGreen),
              const SizedBox(width: 6),
              Text(
                '1 — ${_maxNumber!}',
                style: GoogleFonts.inter(
                  color: AppColors.snow,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '· ${_numDice}D',
                style: GoogleFonts.inter(
                  color: AppColors.steel,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Change max
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _resetSetup,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.warmCharcoal),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune, size: 12, color: AppColors.steel),
                  const SizedBox(width: 4),
                  Text(
                    'CHANGE',
                    style: GoogleFonts.inter(
                      color: AppColors.steel,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Setup Screen ─────────────────────────

class _SetupScreen extends StatefulWidget {
  final ValueChanged<int> onStart;
  const _SetupScreen({required this.onStart});

  @override
  State<_SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<_SetupScreen> {
  final _controller = TextEditingController(text: '6');
  String? _error;

  void _submit() {
    final n = int.tryParse(_controller.text.trim());
    if (n == null || n < 2) {
      setState(() => _error = '2 이상의 정수를 입력하세요');
      return;
    }
    if (n > 9999) {
      setState(() => _error = '너무 큰 숫자입니다 (최대 9999)');
      return;
    }
    widget.onStart(n);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final minDim = min(size.width, size.height);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.casino,
                  size: minDim * 0.18, color: AppColors.signalGreen),
              const SizedBox(height: 20),
              Text(
                'THE CANNON',
                style: GoogleFonts.bebasNeue(
                  color: AppColors.snow,
                  fontSize: minDim * 0.08,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '추첨 상한을 정하세요 (2 이상)',
                style: GoogleFonts.inter(
                  color: AppColors.steel,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // Max number input
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: GoogleFonts.bebasNeue(
                  color: AppColors.snow,
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  height: 1.0,
                ),
                cursorColor: AppColors.signalGreen,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.carbon,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.warmCharcoal),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.signalGreen, width: 2),
                  ),
                ),
              ),

              // Quick presets
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: const [2, 6, 10, 20, 50, 100]
                    .map((n) => _PresetChip(
                          value: n,
                          onTap: () {
                            _controller.text = '$n';
                            setState(() => _error = null);
                          },
                        ))
                    .toList(),
              ),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 13,
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // START button
              SizedBox(
                width: double.infinity,
                child: _BigButton(
                  label: 'START',
                  onTap: _submit,
                ),
              ),

              const SizedBox(height: 18),
              Text(
                '주사위는 6단위로 추가  ·  2~6:1개  ·  7~12:2개  ·  13~18:3개\n'
                '첫 주사위 1~6, 나머지는 0(빈 면)~6 → 결과 = 합',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.warmCharcoal,
                  fontSize: 11,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatefulWidget {
  final int value;
  final VoidCallback onTap;
  const _PresetChip({required this.value, required this.onTap});

  @override
  State<_PresetChip> createState() => _PresetChipState();
}

class _PresetChipState extends State<_PresetChip> {
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.carbon : Colors.transparent,
            border: Border.all(
              color: _hovered ? AppColors.signalGreen : AppColors.warmCharcoal,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${widget.value}',
            style: GoogleFonts.inter(
              color: _hovered ? AppColors.signalGreen : AppColors.steel,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _BigButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _BigButton({required this.label, required this.onTap});

  @override
  State<_BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<_BigButton> {
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
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.signalGreen : AppColors.carbon,
            border: Border.all(color: AppColors.signalGreen, width: 2),
            borderRadius: BorderRadius.circular(10),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.signalGreen.withValues(alpha: 0.4),
                      blurRadius: 18,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: GoogleFonts.bebasNeue(
              color: _hovered ? Colors.black : AppColors.signalGreen,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Draw button ─────────────────────────

class _DrawButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isRolling;
  final double height;

  const _DrawButton({
    required this.onTap,
    required this.isRolling,
    required this.height,
  });

  @override
  State<_DrawButton> createState() => _DrawButtonState();
}

class _DrawButtonState extends State<_DrawButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    final h = widget.height.clamp(64.0, 140.0);
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: h,
          decoration: BoxDecoration(
            color: disabled
                ? AppColors.carbon
                : (_hovered ? AppColors.signalGreen : AppColors.carbon),
            border: Border.all(
              color: disabled
                  ? AppColors.warmCharcoal
                  : AppColors.signalGreen,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: !disabled && _hovered
                ? [
                    BoxShadow(
                      color: AppColors.signalGreen.withValues(alpha: 0.5),
                      blurRadius: 22,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.isRolling ? 'ROLLING…' : 'DRAW',
            style: GoogleFonts.bebasNeue(
              color: disabled
                  ? AppColors.steel
                  : (_hovered ? Colors.black : AppColors.signalGreen),
              fontSize: h * 0.42,
              fontWeight: FontWeight.w900,
              letterSpacing: h * 0.08,
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Dice rendering ─────────────────────────

class _DiceFace extends StatelessWidget {
  final int face; // 1..6
  final double size;
  final double angleRad;

  const _DiceFace({
    required this.face,
    required this.size,
    this.angleRad = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      duration: const Duration(milliseconds: 70),
      turns: angleRad / (2 * pi),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(size * 0.18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: size * 0.12,
              offset: Offset(0, size * 0.04),
            ),
          ],
          gradient: LinearGradient(
            colors: const [Color(0xFFFFFFFF), Color(0xFFE0E0E0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: CustomPaint(painter: _DicePainter(face: face)),
      ),
    );
  }
}

class _DicePainter extends CustomPainter {
  final int face;
  _DicePainter({required this.face});

  // Dot positions in fractional coords (xPct, yPct), per face 0..6
  // Face 0 = blank (no dots) — used for non-first dice when result is in lower range.
  static const Map<int, List<List<double>>> _dotMap = {
    0: [],
    1: [
      [0.5, 0.5]
    ],
    2: [
      [0.27, 0.27],
      [0.73, 0.73],
    ],
    3: [
      [0.27, 0.27],
      [0.5, 0.5],
      [0.73, 0.73],
    ],
    4: [
      [0.27, 0.27],
      [0.73, 0.27],
      [0.27, 0.73],
      [0.73, 0.73],
    ],
    5: [
      [0.27, 0.27],
      [0.73, 0.27],
      [0.5, 0.5],
      [0.27, 0.73],
      [0.73, 0.73],
    ],
    6: [
      [0.27, 0.25],
      [0.73, 0.25],
      [0.27, 0.5],
      [0.73, 0.5],
      [0.27, 0.75],
      [0.73, 0.75],
    ],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF0E0E0E);
    final r = size.width * 0.085;
    final dots = _dotMap[face] ?? const [];
    for (final pos in dots) {
      canvas.drawCircle(
        Offset(pos[0] * size.width, pos[1] * size.height),
        r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DicePainter oldDelegate) => oldDelegate.face != face;
}
