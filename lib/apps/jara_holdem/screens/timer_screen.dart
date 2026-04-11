import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/tournament_provider.dart';
import '../widgets/countdown_display.dart';
import '../widgets/blind_info_display.dart';
import '../widgets/control_buttons.dart';
import 'help_screen.dart';
import 'setup_screen.dart';
import '../services/fullscreen_service.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  bool _isFullscreen = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final isBreak = provider.isBreak;

    return Scaffold(
      backgroundColor: provider.isCashGame
          ? const Color(0xFF0A1520)
          : isBreak
              ? const Color(0xFF1A1500)
              : const Color(0xFF0A1A0A),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar: tournament name + current time
            _buildTopBar(provider),
            // Main content
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final h = constraints.maxHeight;
                  final gap1 = (h * 0.04).clamp(8.0, 32.0);
                  final gap2 = (h * 0.05).clamp(10.0, 40.0);
                  return Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CountdownDisplay(),
                            SizedBox(height: gap1),
                            const BlindInfoDisplay(),
                            SizedBox(height: gap2),
                            ControlButtons(
                              onSettingsTap: () => _openSettings(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(TournamentProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          // Tournament name
          Expanded(
            child: Text(
              provider.structure.name,
              style: GoogleFonts.orbitron(
                color: Colors.amber.shade300,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Current time
          StreamBuilder(
            stream: Stream.periodic(const Duration(seconds: 1)),
            builder: (context, _) => Text(
              DateFormat('HH:mm:ss').format(DateTime.now()),
              style: GoogleFonts.rajdhani(
                color: Colors.cyan.shade300,
                fontSize: 26,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Help button
          IconButton(
            icon: const Icon(
              Icons.help_outline_rounded,
              color: Colors.white54,
              size: 26,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpScreen()),
            ),
            tooltip: 'Holdem Guide',
          ),
          // Fullscreen toggle (web only)
          if (kIsWeb)
            IconButton(
              icon: Icon(
                _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                color: Colors.white54,
                size: 28,
              ),
              onPressed: _toggleFullscreen,
              tooltip: 'Fullscreen',
            ),
        ],
      ),
    );
  }

  void _toggleFullscreen() {
    if (_isFullscreen) {
      FullscreenService.exitFullscreen();
    } else {
      FullscreenService.enterFullscreen();
    }
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }

  void _openSettings(BuildContext context) {
    final provider = context.read<TournamentProvider>();
    if (provider.isRunning) {
      provider.pause();
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const SetupScreen(),
        ),
      ),
    );
  }
}
