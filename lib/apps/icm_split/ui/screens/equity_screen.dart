import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
import '../../state/decision_providers.dart';
import '../../state/equity_providers.dart';
import '../widgets/card_picker.dart';

/// 핸드 에쿼티 계산기: 히어로/상대 홀 카드(+선택적 보드) → 몬테카를로 승률.
class EquityScreen extends ConsumerWidget {
  const EquityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(equityControllerProvider);
    final ctrl = ref.read(equityControllerProvider.notifier);
    final sel = st.selection;

    Future<void> pick(CardSlot slot, int index, int? current) async {
      final used = {...sel.used};
      if (current != null) used.remove(current);
      final picked = await showCardPicker(context, used);
      if (picked == null) return;
      ctrl.setCard(slot, index, picked == clearSentinel ? null : picked);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('핸드 에쿼티 계산기'),
        actions: [
          IconButton(
            tooltip: '비우기',
            icon: const Icon(Icons.refresh),
            onPressed: ctrl.clearAll,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _CardRow(
            label: '히어로',
            cards: sel.hero,
            onTap: (i) => pick(CardSlot.hero, i, sel.hero[i]),
          ),
          _CardRow(
            label: '상대',
            cards: sel.villain,
            onTap: (i) => pick(CardSlot.villain, i, sel.villain[i]),
          ),
          _CardRow(
            label: '보드(선택)',
            cards: sel.board,
            onTap: (i) => pick(CardSlot.board, i, sel.board[i]),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: sel.ready && !st.computing
                ? () => ctrl.calculate()
                : null,
            icon: st.computing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.calculate),
            label: Text(st.computing ? '계산 중…' : '에쿼티 계산'),
          ),
          if (!sel.ready)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '히어로·상대 카드를 각각 2장씩 선택하세요.',
                textAlign: TextAlign.center,
              ),
            ),
          if (st.result != null && st.result!.trials > 0)
            _ResultCard(result: st.result!),
        ],
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({
    required this.label,
    required this.cards,
    required this.onTap,
  });
  final String label;
  final List<int?> cards;
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            for (var i = 0; i < cards.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: CardSlotChip(card: cards[i], onTap: () => onTap(i)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends ConsumerWidget {
  const _ResultCard({required this.result});
  final dynamic result; // EquityResult

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hero = result.heroEquity * 100.0;
    final villain = result.villainEquity * 100.0;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '에쿼티',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                letterSpacing: -0.374,
              ),
            ),
            const SizedBox(height: 8),
            _Bar(label: '히어로', pct: hero, color: scheme.primary),
            const SizedBox(height: 6),
            _Bar(label: '상대', pct: villain, color: scheme.tertiary),
            const SizedBox(height: 8),
            Text(
              '타이 ${Fmt.percent(result.tieRate * 100)} · 시뮬 ${Fmt.chips(result.trials)}회',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('이 승률을 푸시/폴드에 적용'),
                onPressed: () {
                  ref.read(decisionInputsProvider.notifier).setWinProb(hero);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('푸시/폴드 승률을 ${Fmt.percent(hero)}로 설정했습니다'),
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.pct, required this.color});
  final String label;
  final double pct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 48, child: Text(label)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0, 1),
              minHeight: 16,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 56,
          child: Text(
            Fmt.percent(pct),
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
