// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'ICM Split';

  @override
  String get tabInput => '입력';

  @override
  String get tabResult => '결과';

  @override
  String get tabDeal => '딜';

  @override
  String get tabDecision => '의사결정';

  @override
  String get actionSave => '저장';

  @override
  String get actionLoad => '불러오기';

  @override
  String get actionReset => '새 계산';
}
