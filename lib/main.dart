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
import 'apps/icm_split/icm_split_app.dart';
import 'apps/safe_link/safe_link_app.dart';
import 'apps/cannon/cannon_app.dart';

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
        // 숨김 관리자 진입점(#/admin). 비밀번호 통과 시 전체 글 수정/삭제.
        '/admin': (_) => const GuestbookPage(adminEntry: true),
        // Sub-apps
        '/app/jara-holdem': (_) => const AppWrapper(
              title: 'Jara Holdem Timer',
              trackId: 'jara-holdem',
              child: JaraHoldemApp(),
            ),
        '/app/roulette': (_) => const AppWrapper(
              title: '자마카세 인원뽑기',
              trackId: 'roulette',
              child: RouletteAppEntry(),
            ),
        '/app/jamakase': (_) => const HtmlAppPage(
              title: 'Jamakase Notify',
              trackId: 'jamakase',
              htmlPath: 'apps/jamakase/index.html',
            ),
        '/app/birthday': (_) => const HtmlAppPage(
              title: '제 25회 자라 생일 선물 리스트',
              trackId: 'birthday',
              htmlPath: 'apps/birthday/index.html',
            ),
        '/app/whos-the-nut': (_) => const AppWrapper(
              title: "Who's the Nut?",
              trackId: 'whos-the-nut',
              child: WhosTheNutApp(),
            ),
        '/app/icm-split': (_) => const AppWrapper(
              title: 'ICM Split',
              trackId: 'icm-split',
              child: IcmSplitApp(),
            ),
        '/app/safe-link': (_) => const AppWrapper(
              title: "It's Safe Link",
              trackId: 'safe-link',
              child: SafeLinkApp(),
            ),
        '/app/cannon': (_) => const AppWrapper(
              title: 'THE CANNON',
              trackId: 'cannon',
              child: CannonApp(),
            ),
        '/app/word-guesser': (_) => const HtmlAppPage(
              title: 'Word Guesser',
              trackId: 'word-guesser',
              htmlPath: 'apps/word-guesser/index.html',
            ),
        '/app/word-finder': (_) => const HtmlAppPage(
              title: 'Word Finder',
              trackId: 'word-finder',
              htmlPath: 'apps/word-finder/index.html',
            ),
      },
    );
  }
}
