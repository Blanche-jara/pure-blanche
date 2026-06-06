import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/scenario_repository.dart';
import 'state/persistence_providers.dart';
import 'ui/app.dart';

/// pure-blanche 허브용 ICM Split 진입 위젯.
///
/// ICM 원본은 main()에서 Hive 저장소를 연 뒤 ProviderScope로 [IcmApp]을 감싼다.
/// 허브는 자체 main()을 거치지 않으므로 여기서 동일한 부팅을 재현한다:
///   1. Hive 저장소를 1회만 열고(재진입 시 동일 Future 재사용),
///   2. 열린 저장소를 scenarioRepositoryProvider에 주입한 ProviderScope로
///   3. 원본 [IcmApp](자체 테마·로케일·네비게이션을 가진 중첩 MaterialApp)을 구동.
class IcmSplitApp extends StatefulWidget {
  const IcmSplitApp({super.key});

  @override
  State<IcmSplitApp> createState() => _IcmSplitAppState();
}

class _IcmSplitAppState extends State<IcmSplitApp> {
  // Hive 초기화/박스 열기는 앱 수명 동안 1회면 충분하다. 서브앱을 나갔다
  // 다시 들어와도 동일한 저장소를 재사용하도록 static으로 캐시한다.
  static Future<ScenarioRepository>? _repoFuture;

  @override
  void initState() {
    super.initState();
    _repoFuture ??= ScenarioRepository.open();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ScenarioRepository>(
      future: _repoFuture,
      builder: (context, snapshot) {
        // ICM "Night rail" 다크 배경과 맞춘 로딩/에러 화면.
        if (snapshot.hasError) {
          return const ColoredBox(
            color: Color(0xFF0E1311),
            child: Center(
              child: Text(
                '저장소를 불러오지 못했습니다.',
                style: TextStyle(color: Color(0xFFA7B2AB)),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const ColoredBox(
            color: Color(0xFF0E1311),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF24C283)),
            ),
          );
        }
        return ProviderScope(
          overrides: [
            scenarioRepositoryProvider.overrideWithValue(snapshot.data!),
          ],
          child: const IcmApp(),
        );
      },
    );
  }
}
