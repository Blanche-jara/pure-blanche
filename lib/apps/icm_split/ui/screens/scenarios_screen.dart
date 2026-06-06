import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
import '../../models/scenario.dart';
import '../../state/persistence_providers.dart';
import '../../state/scenario_controller.dart';

/// 저장된 시나리오 목록. 탭하면 불러오고, 삭제 가능.
class ScenariosScreen extends ConsumerWidget {
  const ScenariosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenarios = ref.watch(savedScenariosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('저장된 시나리오')),
      body: scenarios.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '저장된 시나리오가 없습니다.\n입력 화면에서 저장(💾) 버튼을 눌러보세요.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              itemCount: scenarios.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = scenarios[i];
                return _ScenarioTile(scenario: s);
              },
            ),
    );
  }
}

class _ScenarioTile extends ConsumerWidget {
  const _ScenarioTile({required this.scenario});
  final Scenario scenario;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pool = scenario.payout.total;
    return ListTile(
      leading: const Icon(Icons.savings_outlined),
      title: Text(scenario.title.isEmpty ? '제목 없음' : scenario.title),
      subtitle: Text(
        '${scenario.players.length}명 · 상금풀 ${Fmt.money(pool, whole: true)} · ${Fmt.dateTime(scenario.updatedAt)}',
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: '삭제',
        onPressed: () => _confirmDelete(context, ref),
      ),
      onTap: () {
        ref.read(scenarioControllerProvider.notifier).load(scenario);
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('"${scenario.title}" 불러옴')));
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제'),
        content: Text('"${scenario.title}" 시나리오를 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      await ref.read(savedScenariosProvider.notifier).remove(scenario.id);
    }
  }
}
