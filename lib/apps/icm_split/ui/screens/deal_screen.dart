import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
import '../../state/deal_providers.dart';
import '../../state/icm_providers.dart';
import '../design_tokens.dart';
import '../widgets/apple_widgets.dart';
import '../widgets/number_field.dart';

/// 딜 방식 비교 팔레트 — ICM=에메랄드(primary), Chip-chop=골드, Save=세이지.
const Color _kChipChopColor = AppColors.gold;
const Color _kSaveColor = Color(0xFF8FA39A);

/// 딜 계산기 화면: ICM / Chip-chop / Save-for-winner 비교.
class DealScreen extends ConsumerWidget {
  const DealScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalChips = ref.watch(totalChipsProvider);
    final pool = ref.watch(prizePoolProvider);
    if (totalChips <= 0 || pool <= 0) {
      return _empty('칩 스택과 상금을 입력하면 딜 분배가 계산됩니다.', context);
    }

    final deal = ref.watch(dealComparisonProvider);
    final saveAmount = ref.watch(saveAmountProvider).clamp(0.0, deal.saveMax);
    final scheme = Theme.of(context).colorScheme;
    final showSave = saveAmount > 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const AppleLargeTitle(
          title: '딜',
          subtitle: 'ICM · Chip-chop · Save-for-winner',
        ),
        ApplePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GroupedBarChart(deal: deal, showSave: showSave),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  _LegendDot(color: scheme.primary, label: 'ICM'),
                  _LegendDot(color: _kChipChopColor, label: 'Chip-chop'),
                  if (showSave) _LegendDot(color: _kSaveColor, label: 'Save'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 방식별 분배 비교 (반응형 그리드 — 폭에 맞춰 절대 넘치지 않음).
        AppleGroup(
          header: '방식별 분배 비교',
          rows: [
            _CompareHeader(showSave: showSave),
            for (var i = 0; i < deal.labels.length; i++)
              _CompareRow(
                name: deal.labels[i],
                icm: deal.icm[i],
                chipChop: deal.chipChop[i],
                save: deal.save.now[i],
                showSave: showSave,
              ),
          ],
        ),
        const SizedBox(height: 8),
        _SaveControl(deal: deal),
        const SizedBox(height: 4),
        _DealNote(showSave: showSave),
      ],
    );
  }

  Widget _empty(String text, BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.handshake_outlined,
              size: 48,
              color: t.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              text,
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
}

/// 비교 그리드 헤더 행 (Expanded 컬럼 → 반응형).
class _CompareHeader extends StatelessWidget {
  const _CompareHeader({required this.showSave});
  final bool showSave;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    Widget cell(String t, {int flex = 2, bool right = true}) => Expanded(
      flex: flex,
      child: Text(
        t,
        textAlign: right ? TextAlign.right : TextAlign.left,
        style: s,
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          cell('플레이어', flex: 3, right: false),
          cell('ICM'),
          cell('Chip-chop'),
          if (showSave) cell('Save'),
        ],
      ),
    );
  }
}

/// 비교 그리드 한 플레이어 행. Chip-chop은 ICM 대비 증감을 색으로 표시.
class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.name,
    required this.icm,
    required this.chipChop,
    required this.save,
    required this.showSave,
  });
  final String name;
  final double icm;
  final double chipChop;
  final double save;
  final bool showSave;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final delta = chipChop - icm;
    final ccColor = delta.abs() < 0.5
        ? t.colorScheme.onSurface
        : (delta > 0 ? AppColors.felt : AppColors.danger);

    Widget value(
      String txt, {
      int flex = 2,
      Color? color,
      bool strong = false,
    }) => Expanded(
      flex: flex,
      child: Text(
        txt,
        textAlign: TextAlign.right,
        style: t.textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
          fontFeatures: const [],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(name, style: t.textTheme.bodyLarge)),
          value(Fmt.wonCompact(icm), strong: true),
          value(Fmt.wonCompact(chipChop), color: ccColor),
          if (showSave) value(Fmt.wonCompact(save)),
        ],
      ),
    );
  }
}

class _SaveControl extends ConsumerWidget {
  const _SaveControl({required this.deal});
  final DealComparison deal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final notifier = ref.read(saveAmountProvider.notifier);
    final max = deal.saveMax;
    final saveAmount = ref.watch(saveAmountProvider).clamp(0.0, max);

    return ApplePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('위너 적립금 (Save-for-winner)', style: t.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '1등 상금에서 적립금 S를 떼어 위너에게 적립하고, 나머지를 지금 ICM으로 분배합니다.',
            style: t.textTheme.bodyMedium?.copyWith(
              color: t.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: saveAmount.toDouble(),
                  max: max <= 0 ? 1 : max,
                  label: Fmt.money(saveAmount, whole: true),
                  onChanged: max <= 0
                      ? null
                      : (v) => notifier.set(v.roundToDouble()),
                ),
              ),
              SizedBox(
                width: 116,
                child: NumberField(
                  value: saveAmount.toDouble(),
                  prefixText: '₩ ',
                  decimals: 0,
                  dense: true,
                  min: 0,
                  max: max,
                  onChanged: (v) => notifier.set(v),
                ),
              ),
            ],
          ),
          Text(
            '권장 범위 0 ~ ${Fmt.money(max, whole: true)} (1등이 2등 이상 유지)',
            style: t.textTheme.bodySmall?.copyWith(
              color: t.colorScheme.onSurfaceVariant,
            ),
          ),
          if (saveAmount > 0) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            for (var i = 0; i < deal.labels.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(deal.labels[i], style: t.textTheme.bodyLarge),
                    ),
                    _mini('지금', Fmt.wonCompact(deal.save.now[i]), t),
                    _mini('위너 시', Fmt.wonCompact(deal.save.ifWin[i]), t),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _mini(String label, String value, ThemeData t) => Expanded(
    flex: 3,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          label,
          style: t.textTheme.bodySmall?.copyWith(
            color: t.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class _GroupedBarChart extends StatelessWidget {
  const _GroupedBarChart({required this.deal, required this.showSave});
  final DealComparison deal;
  final bool showSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final all = <double>[
      ...deal.icm,
      ...deal.chipChop,
      if (showSave) ...deal.save.now,
    ];
    final maxV = all.fold(0.0, (a, b) => a > b ? a : b);
    final maxY = maxV <= 0 ? 1.0 : maxV * 1.2;

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (v, _) => Text(
                  Fmt.wonCompact(v),
                  style: const TextStyle(fontSize: 9),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= deal.labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      deal.labels[i],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          barGroups: [
            for (var i = 0; i < deal.labels.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 2,
                barRods: [
                  BarChartRodData(
                    toY: deal.icm[i],
                    width: 9,
                    color: scheme.primary,
                  ),
                  BarChartRodData(
                    toY: deal.chipChop[i],
                    width: 9,
                    color: _kChipChopColor,
                  ),
                  if (showSave)
                    BarChartRodData(
                      toY: deal.save.now[i],
                      width: 9,
                      color: _kSaveColor,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _DealNote extends StatelessWidget {
  const _DealNote({required this.showSave});
  final bool showSave;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
      child: Text(
        '• Chip-chop은 ICM 대비 칩리더에게 유리(숏스택에 불리)합니다. 실전에선 둘 사이에서 협상합니다.\n'
        '${showSave ? "• Save-for-winner의 기대총액은 순수 ICM과 같고, 분산만 위너 자리로 이동합니다." : "• 아래 슬라이더로 위너 적립금을 설정하면 Save-for-winner 분배가 나타납니다."}',
        style: TextStyle(color: color, fontSize: 13, height: 1.5),
      ),
    );
  }
}
