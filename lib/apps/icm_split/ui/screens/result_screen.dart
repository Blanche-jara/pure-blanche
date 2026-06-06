import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
import '../../state/icm_providers.dart';
import '../design_tokens.dart';
import '../widgets/apple_widgets.dart';
import '../widgets/result_bar_chart.dart';

/// 결과 화면: ICM \$ / % — 포커 룸 스타일. 칩 색 식별 + 리더 골드 강조.
class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(icmResultsProvider);
    final totalChips = ref.watch(totalChipsProvider);
    final pool = ref.watch(prizePoolProvider);

    if (totalChips <= 0 || pool <= 0) {
      return const _Empty(
        icon: Icons.insights_outlined,
        text: '칩 스택과 상금을 입력하면 ICM 결과가 표시됩니다.',
      );
    }

    // 칩리더(최대 EV) 인덱스.
    var leader = 0;
    for (var i = 1; i < rows.length; i++) {
      if (rows[i].equity > rows[leader].equity) leader = i;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
      children: [
        const AppleLargeTitle(title: '결과', subtitle: 'Independent Chip Model'),
        _HeroPanel(pool: pool, totalChips: totalChips, players: rows.length),
        const SizedBox(height: 16),
        _SectionLabel('분배'),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 16, 10),
            child: ResultBarChart(
              data: [
                for (var i = 0; i < rows.length; i++)
                  BarDatum(
                    rows[i].label,
                    rows[i].equity,
                    color: AppColors.chip(i),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SectionLabel('순위'),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 56),
                _PlayerRow(row: rows[i], index: i, isLeader: i == leader),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 상금풀을 골드 대형 숫자로 보여주는 펠트 그라데이션 히어로.
class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.pool,
    required this.totalChips,
    required this.players,
  });
  final double pool;
  final int totalChips;
  final int players;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: feltGradient(t.brightness),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: t.colorScheme.outline),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GTD · 총 상금',
            style: t.textTheme.labelMedium?.copyWith(
              color: t.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Fmt.money(pool, whole: true),
              style: t.textTheme.displaySmall?.copyWith(color: AppColors.gold),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat(label: '칩 합계', value: Fmt.chips(totalChips)),
              Container(
                width: 1,
                height: 34,
                margin: const EdgeInsets.symmetric(horizontal: 18),
                color: t.colorScheme.outline,
              ),
              _MiniStat(label: '플레이어', value: '$players명'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: t.textTheme.titleLarge),
        Text(
          label,
          style: t.textTheme.bodySmall?.copyWith(
            color: t.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.row,
    required this.index,
    required this.isLeader,
  });
  final IcmRow row;
  final int index;
  final bool isLeader;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          ChipDot(AppColors.chip(index)),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    row.label,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isLeader ? AppColors.gold : null,
                    ),
                  ),
                ),
                if (isLeader) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.emoji_events,
                    size: 15,
                    color: AppColors.gold,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Fmt.money(row.equity),
                style: t.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isLeader ? AppColors.gold : t.colorScheme.onSurface,
                ),
              ),
              Text(
                '${Fmt.percent(row.percent)} · ${Fmt.chips(row.stack)}',
                style: t.textTheme.bodySmall?.copyWith(
                  color: t.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 섹션 라벨(카드 위 muted 캡션).
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      child: Text(
        text.toUpperCase(),
        style: t.textTheme.labelMedium?.copyWith(
          color: t.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: t.colorScheme.onSurfaceVariant),
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
