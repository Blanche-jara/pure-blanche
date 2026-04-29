import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'pages/main_page.dart';
import 'pages/code_projects_page.dart';
import 'pages/video_projects_page.dart';
import 'pages/guestbook_page.dart';
import 'apps/app_wrapper.dart';
import 'apps/jara_holdem/jara_holdem_app.dart';
import 'apps/roulette/roulette_main.dart';
import 'apps/web_embed/html_app_page.dart';
import 'apps/whos_the_nut/whos_the_nut_app.dart';

void main() {
  runApp(const PureBlancheApp());
}

class PureBlancheApp extends StatelessWidget {
  const PureBlancheApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blanche',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: '/',
      routes: {
        '/': (_) => const MainPage(),
        '/code': (_) => const CodeProjectsPage(),
        '/video': (_) => const VideoProjectsPage(),
        '/guestbook': (_) => const GuestbookPage(),
        // Sub-apps
        '/app/jara-holdem': (_) => const AppWrapper(
              title: 'Jara Holdem Timer',
              child: JaraHoldemApp(),
            ),
        '/app/roulette': (_) => const AppWrapper(
              title: '자마카세 인원뽑기',
              child: RouletteAppEntry(),
            ),
        '/app/jamakase': (_) => const HtmlAppPage(
              title: 'Jamakase Notify',
              htmlPath: 'apps/jamakase/index.html',
            ),
        '/app/birthday': (_) => const HtmlAppPage(
              title: '제 25회 자라 생일 선물 리스트',
              htmlPath: 'apps/birthday/index.html',
            ),
        '/app/whos-the-nut': (_) => const AppWrapper(
              title: "Who's the Nut?",
              child: WhosTheNutApp(),
            ),
      },
    );
  }
}
