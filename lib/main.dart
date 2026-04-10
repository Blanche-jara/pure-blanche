import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'pages/main_page.dart';
import 'pages/code_projects_page.dart';
import 'pages/video_projects_page.dart';
import 'pages/guestbook_page.dart';

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
      },
    );
  }
}
