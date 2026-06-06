import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'home_shell.dart';
import 'theme.dart';

/// 앱 루트 위젯. 테마·로케일·홈 셸 구성.
class IcmApp extends StatelessWidget {
  const IcmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      // "Night rail" 다크가 기본 정체성. (시스템 라이트에서도 다크로 표시)
      themeMode: ThemeMode.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: const HomeShell(),
    );
  }
}
