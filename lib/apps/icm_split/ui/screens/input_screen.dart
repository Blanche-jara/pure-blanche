import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
import '../../state/icm_providers.dart';
import '../../state/scenario_controller.dart';
import '../design_tokens.dart';
import '../widgets/apple_widgets.dart';
import '../widgets/number_field.dart';
import '../widgets/payout_editor.dart';

/// 입력 화면: 플레이어 스택 + 상금 구조. 합계/검증 실시간 표시.
class InputScreen extends ConsumerWidget {
  const InputScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(scenarioControllerProvider);
    final controller = ref.read(scenarioControllerProvider.notifier);
    final totalChips = ref.watch(totalChipsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const AppleLargeTitle(title: '입력', subtitle: '플레이어 스택과 상금 구조'),
        ApplePanel(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    Text(
                      '플레이어',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      '칩 합계 ${Fmt.chips(totalChips)}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < s.players.length; i++)
                _PlayerRow(index: i, key: ValueKey(s.players[i].id)),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => controller.addPlayer(),
                      icon: const Icon(Icons.person_add_alt, size: 18),
                      label: const Text('플레이어 추가'),
                    ),
                    const Spacer(),
                    Text(
                      '${s.players.length}명',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const PayoutEditor(),
        const SizedBox(height: 12),
        if (!s.hasChips)
          const _Hint(icon: Icons.info_outline, text: '칩 스택을 입력하면 결과가 계산됩니다.'),
      ],
    );
  }
}

class _PlayerRow extends ConsumerWidget {
  const _PlayerRow({required this.index, super.key});
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(scenarioControllerProvider).players;
    if (index >= players.length) return const SizedBox.shrink();
    final p = players[index];
    final controller = ref.read(scenarioControllerProvider.notifier);
    final canRemove = players.length > 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ChipDot(AppColors.chip(index)),
          const SizedBox(width: 10),
          SizedBox(
            width: 76,
            child: TextFormField(
              initialValue: p.name,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'P${index + 1}',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
              ),
              onChanged: (v) => controller.updateName(p.id, v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: NumberField(
              value: p.stack.toDouble(),
              step: 500,
              decimals: 0,
              dense: true,
              hint: '칩',
              onChanged: (v) => controller.updateStack(p.id, v.round()),
            ),
          ),
          IconButton(
            onPressed: canRemove ? () => controller.removePlayer(p.id) : null,
            icon: const Icon(Icons.close),
            visualDensity: VisualDensity.compact,
            tooltip: '제거',
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(color: color)),
        ),
      ],
    );
  }
}
