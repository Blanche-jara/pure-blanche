import 'package:flutter/material.dart';
import '../providers/tournament_provider.dart';
import 'package:provider/provider.dart';

class CountdownDisplay extends StatelessWidget {
  const CountdownDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final timerFontSize = (screenWidth * 0.15).clamp(48.0, 180.0).clamp(48.0, screenHeight * 0.18);

    if (provider.structure.levels.isEmpty) {
      return Text(
        'No levels configured',
        style: TextStyle(
          fontSize: (screenWidth * 0.04).clamp(18.0, 48.0),
          color: Colors.white38,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Level indicator
        Text(
          _getLevelLabel(provider),
          style: TextStyle(
            fontSize: (screenWidth * 0.04).clamp(18.0, 48.0),
            fontWeight: FontWeight.w300,
            color: Colors.white70,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        // Big timer
        Text(
          provider.formattedTime,
          style: TextStyle(
            fontSize: timerFontSize,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: _getTimerColor(provider),
            shadows: [
              Shadow(
                color: _getTimerColor(provider).withValues(alpha: 0.5),
                blurRadius: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Progress bar (hidden for cash game)
        if (!provider.isInfiniteLevel)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: provider.progress,
                minHeight: 6,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  provider.isBreak ? Colors.amber : Colors.green,
                ),
              ),
            ),
          ),
        if (provider.isInfiniteLevel)
          Text(
            'ELAPSED',
            style: TextStyle(
              fontSize: (screenWidth * 0.02).clamp(10.0, 20.0),
              color: Colors.white24,
              letterSpacing: 6,
            ),
          ),
      ],
    );
  }

  String _getLevelLabel(TournamentProvider provider) {
    if (provider.isBreak) return 'BREAK';
    if (provider.isCashGame) return 'CASH GAME';
    return 'LEVEL ${provider.displayLevelNumber}';
  }

  Color _getTimerColor(TournamentProvider provider) {
    if (provider.isInfiniteLevel) return Colors.cyan;
    if (provider.isBreak) return Colors.amber;
    if (provider.remainingSeconds <= 10) return Colors.red;
    if (provider.remainingSeconds <= 60) return Colors.orange;
    return Colors.white;
  }
}
