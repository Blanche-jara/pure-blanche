import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/tournament_provider.dart';
import 'screens/timer_screen.dart';

/// Entry widget for Jara Holdem Timer.
/// Wraps the app in its own Provider scope so it's self-contained.
/// On mobile, forces landscape orientation for optimal timer display.
class JaraHoldemApp extends StatefulWidget {
  const JaraHoldemApp({super.key});

  @override
  State<JaraHoldemApp> createState() => _JaraHoldemAppState();
}

class _JaraHoldemAppState extends State<JaraHoldemApp> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

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
