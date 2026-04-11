import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/tournament_provider.dart';
import 'screens/timer_screen.dart';

/// Entry widget for Jara Holdem Timer.
/// Wraps the app in its own Provider scope so it's self-contained.
class JaraHoldemApp extends StatelessWidget {
  const JaraHoldemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TournamentProvider()..initialize(),
      child: Theme(
        data: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0A1A0A),
        ),
        child: const TimerScreen(),
      ),
    );
  }
}
