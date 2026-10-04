import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio/forge_audio_factory.dart';
import 'data/save_repository.dart';
import 'state/game_controller.dart';
import 'ui/design_tokens.dart' as design;
import 'ui/forge_screen.dart';
import 'ui/widgets/forge_stage.dart';

class SwordUpgradeApp extends StatefulWidget {
  final Color? backgroundColor;
  const SwordUpgradeApp({super.key, this.backgroundColor});
  @override
  State<SwordUpgradeApp> createState() => _SwordUpgradeAppState();
}

class _SwordUpgradeAppState extends State<SwordUpgradeApp> {
  GameController? game;
  late final Future<GameController> loading = _load();
  Future<GameController> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final audio = createForgeAudio();
    if (mounted) {
      await Future.wait([
        ...forgeEffectAssets.map(
          (path) => precacheImage(AssetImage(path), context),
        ),
        audio.load(),
      ]);
    }
    final controller = await GameController.load(
      SaveRepository(preferences),
      audio: audio,
    );
    if (!mounted) {
      controller.dispose();
    } else {
      game = controller;
    }
    return controller;
  }

  @override
  void dispose() {
    game?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: swordTheme,
    child: FutureBuilder<GameController>(
      future: loading,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            backgroundColor: design.Ink.background,
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '저장을 불러오지 못했습니다. 기존 진행을 초기화하거나 덮어쓰지 않았습니다. 새로고침한 뒤에도 계속되면 저장 복구가 필요합니다.',
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: design.Ink.background,
            body: Center(
              child: CircularProgressIndicator(color: design.Ink.orange),
            ),
          );
        }
        return ForgeScreen(
          controller: snapshot.data!,
          backgroundColor: widget.backgroundColor,
        );
      },
    ),
  );
}

final swordTheme = ThemeData(
  brightness: Brightness.dark,
  fontFamily: 'NeoDunggeunmo',
  scaffoldBackgroundColor: design.Ink.background,
  colorScheme: const ColorScheme.dark(
    primary: design.Ink.orange,
    secondary: design.Ink.gold,
    surface: design.Ink.panel,
    onSurface: design.Ink.text,
    onPrimary: design.Ink.background,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontSize: 16, color: design.Ink.text),
    bodySmall: TextStyle(fontSize: 12, color: design.Ink.muted),
  ),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: design.Ink.border,
    contentTextStyle: TextStyle(
      fontFamily: 'NeoDunggeunmo',
      color: design.Ink.text,
    ),
  ),
);
