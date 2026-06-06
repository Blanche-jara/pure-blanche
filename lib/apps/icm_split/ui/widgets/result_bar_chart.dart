import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/formatting.dart';

/// 막대 하나에 필요한 최소 데이터. [color]가 있으면 그 색으로(없으면 테마 primary).
class BarDatum {
  const BarDatum(this.label, this.value, {this.color});
  final String label;
  final double value;
  final Color? color;
}

/// 플레이어별 \$ 분배를 막대그래프로 표시. 딜 비교 등에도 재사용.
class ResultBarChart extends StatelessWidget {
  const ResultBarChart({super.key, required this.data, this.height = 220});

  final List<BarDatum> data;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return SizedBox(height: height);
    final scheme = Theme.of(context).colorScheme;
    final maxV = data.map((d) => d.value).fold(0.0, (a, b) => a > b ? a : b);
    final maxY = maxV <= 0 ? 1.0 : maxV * 1.2;

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                Fmt.money(rod.toY),
                TextStyle(color: scheme.onInverseSurface, fontSize: 11),
              ),
            ),
          ),
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
                getTitlesWidget: (value, meta) => Text(
                  Fmt.wonCompact(value),
                  style: const TextStyle(fontSize: 9),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      data[i].label,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: scheme.outlineVariant.withValues(alpha: 0.6),
              strokeWidth: 1,
            ),
          ),
          barGroups: [
            for (var i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i].value,
                    width: 20,
                    color: data[i].color ?? scheme.primary,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(5),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
