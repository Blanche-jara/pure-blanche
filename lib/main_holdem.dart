import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'apps/jara_holdem/jara_holdem_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock landscape + hide all system UI
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const BHTApp());
}

class BHTApp extends StatelessWidget {
  const BHTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blanche Holdem Timer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A1A0A),
      ),
      home: const JaraHoldemApp(),
    );
  }
}
