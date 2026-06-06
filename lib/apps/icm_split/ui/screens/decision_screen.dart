import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
import '../../state/decision_providers.dart';
import '../../state/scenario_controller.dart';
import '../widgets/apple_widgets.dart';
import '../widgets/number_field.dart';
import 'equity_screen.dart';

/// 의사결정 도구: 버블 팩터 / 필요 콜 에쿼티 / 푸시·폴드 ICM EV 비교.
class DecisionScreen extends ConsumerWidget {
  const DecisionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(scenarioControllerProvider);
    final result = ref.watch(decisionResultProvider);

    if (result == null) {
      final t = Theme.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 48,
                color: t.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                '플레이어 2명 이상, 칩·상금을 입력하면 의사결정 도구가 활성화됩니다.',
                textAlign: TextAlign.center,
                style: t.textTheme.bodyLarge?.copyWith(
                  color: t.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final labels = [
      for (var i = 0; i < s.players.length; i++)
        s.players[i].name.trim().isEmpty
            ? 'P${i + 1}'
            : s.players[i].name.trim(),
    ];
    final inputs = ref.watch(decisionInputsProvider);
    final inputCtrl = ref.read(decisionInputsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const AppleLargeTitle(title: '의사결정', subtitle: 'ICM 압박 · 콜 임계 · 푸시/폴드'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '대결 설정',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    letterSpacing: -0.374,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _PlayerDropdown(
                        label: '히어로',
                        labels: labels,
                        value: result.hero,
                        onChanged: inputCtrl.setHero,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PlayerDropdown(
                        label: '상대',
                        labels: labels,
                        value: result.opp,
                        onChanged: inputCtrl.setOpp,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: NumberField(
                        label: 'risk (칩, 0=올인 자동)',
                        value: inputs.riskOverride.toDouble(),
                        decimals: 0,
                        dense: true,
                        onChanged: (v) => inputCtrl.setRisk(v.round()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '적용 risk: ${Fmt.chips(result.risk)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        _MetricCard(
          title: '버블 팩터 (리스크 프리미엄)',
          value: result.bubbleFactor == null
              ? 'N/A'
              : result.bubbleFactor!.toStringAsFixed(2),
          subtitle: result.bubbleFactor == null
              ? '거래 가치가 없어 계산 불가'
              : (result.bubbleFactor! <= 1.01
                    ? '≈1.0 — 칩 EV 중립(ICM 압박 거의 없음)'
                    : '>1.0 — 잃는 ICM이 더 큼, 타이트하게 (값이 클수록 압박↑)'),
          accent: (result.bubbleFactor ?? 1) > 1.3,
        ),
        _MetricCard(
          title: '올인 콜 필요 에쿼티 (p*)',
          value: result.requiredEquity == null
              ? 'N/A'
              : Fmt.percent(result.requiredEquity! * 100),
          subtitle: '실제 승률이 이 값 이상이면 콜이 ICM상 이득',
        ),
        _PushFoldCard(
          result: result,
          winProb: inputs.winProbPercent,
          deadChips: inputs.deadChips,
          onWinProb: inputCtrl.setWinProb,
          onDead: inputCtrl.setDeadChips,
        ),
        _ConfTable(result: result, heroLabel: labels[result.hero]),
      ],
    );
  }
}

class _PlayerDropdown extends StatelessWidget {
  const _PlayerDropdown({
    required this.label,
    required this.labels,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<String> labels;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: value,
          items: [
            for (var i = 0; i < labels.length; i++)
              DropdownMenuItem(value: i, child: Text(labels[i])),
          ],
          onChanged: (v) => v == null ? null : onChanged(v),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    this.accent = false,
  });

  final String title;
  final String value;
  final String subtitle;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: accent ? scheme.error : scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PushFoldCard extends StatelessWidget {
  const _PushFoldCard({
    required this.result,
    required this.winProb,
    required this.deadChips,
    required this.onWinProb,
    required this.onDead,
  });

  final DecisionResult result;
  final double winProb;
  final int deadChips;
  final ValueChanged<double> onWinProb;
  final ValueChanged<int> onDead;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pf = result.pushFold;
    final call = pf.shouldCall;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '푸시 / 폴드 ICM EV 비교',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                letterSpacing: -0.374,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('승률 ${Fmt.percent(winProb)}'),
                Expanded(
                  child: Slider(
                    value: winProb,
                    max: 100,
                    divisions: 100,
                    label: '${winProb.round()}%',
                    onChanged: onWinProb,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _EvBox(label: '폴드 EV', value: pf.foldEv, highlight: !call),
                _EvBox(label: '콜 EV', value: pf.callEv, highlight: call),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: (call ? scheme.primary : scheme.error).withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${call ? "콜 / 푸시" : "폴드"}  (${pf.edge >= 0 ? "+" : "−"}${Fmt.money(pf.edge.abs())})',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: call ? scheme.primary : scheme.error,
                ),
              ),
            ),
            const SizedBox(height: 8),
            NumberField(
              label: '폴드 시 데드 칩(블라인드/앤티, 선택)',
              value: deadChips.toDouble(),
              decimals: 0,
              dense: true,
              onChanged: (v) => onDead(v.round()),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.style_outlined),
                label: const Text('핸드 에쿼티로 승률 추정'),
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const EquityScreen())),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvBox extends StatelessWidget {
  const _EvBox({
    required this.label,
    required this.value,
    required this.highlight,
  });
  final String label;
  final double value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(
          Fmt.money(value),
          style: TextStyle(
            fontSize: 18,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _ConfTable extends StatelessWidget {
  const _ConfTable({required this.result, required this.heroLabel});
  final DecisionResult result;
  final String heroLabel;

  @override
  Widget build(BuildContext context) {
    final c = result.conf;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$heroLabel ICM 3상태',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                letterSpacing: -0.374,
              ),
            ),
            const SizedBox(height: 8),
            _row('이길 때', c.icmWin),
            _row('폴드(현재)', c.icmFold),
            _row('질 때', c.icmLose),
            const Divider(),
            _row('얻는 ICM', c.dollarsGained),
            _row('잃는 ICM', c.dollarsLost),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), Text(Fmt.money(value))],
    ),
  );
}
