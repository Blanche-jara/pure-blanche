import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../state/persistence_providers.dart';
import '../state/scenario_controller.dart';
import 'screens/deal_screen.dart';
import 'screens/decision_screen.dart';
import 'screens/help_screen.dart';
import 'screens/input_screen.dart';
import 'screens/result_screen.dart';
import 'screens/scenarios_screen.dart';
import 'widgets/apple_widgets.dart';

/// 앱 메인 셸. 하단 탭으로 입력/결과/딜/의사결정 전환.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _tabs = [
    InputScreen(),
    ResultScreen(),
    DealScreen(),
    DecisionScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.actionSave,
            icon: const Icon(Icons.save_outlined),
            onPressed: () => _saveScenario(context),
          ),
          IconButton(
            tooltip: l10n.actionLoad,
            icon: const Icon(Icons.folder_open_outlined),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ScenariosScreen())),
          ),
          IconButton(
            tooltip: l10n.actionReset,
            icon: const Icon(Icons.refresh),
            onPressed: () => _confirmReset(context),
          ),
          IconButton(
            tooltip: '도움말',
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const HelpScreen())),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.edit_outlined),
            selectedIcon: const Icon(Icons.edit),
            label: l10n.tabInput,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: l10n.tabResult,
          ),
          NavigationDestination(
            icon: const Icon(Icons.handshake_outlined),
            selectedIcon: const Icon(Icons.handshake),
            label: l10n.tabDeal,
          ),
          NavigationDestination(
            icon: const Icon(Icons.psychology_outlined),
            selectedIcon: const Icon(Icons.psychology),
            label: l10n.tabDecision,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('새 계산'),
        content: const Text('현재 입력을 초기화할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      ref.read(scenarioControllerProvider.notifier).reset();
    }
  }

  Future<void> _saveScenario(BuildContext context) async {
    final state = ref.read(scenarioControllerProvider);
    final title = await showTextPrompt(
      context,
      title: '시나리오 저장',
      confirmLabel: '저장',
      initial: state.title,
      label: '제목',
      hint: '예: 파이널 4인',
    );
    if (title == null) return;

    final trimmed = title.trim();
    ref.read(scenarioControllerProvider.notifier).setTitle(trimmed);
    final scenario = ref
        .read(scenarioControllerProvider)
        .toScenario(DateTime.now());
    await ref.read(savedScenariosProvider.notifier).save(scenario);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"${scenario.title}" 저장됨')));
    }
  }
}
