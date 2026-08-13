/// 정산표 — 프로젝트 상세(헤더 + 3개 탭).
library;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'engine.dart';
import 'models.dart';
import 'store.dart';
import 'tab_expenses.dart';
import 'tab_members.dart';
import 'tab_overview.dart';
import 'ui_kit.dart';

class ProjectView extends StatefulWidget {
  final SettlementStore store;
  final SettlementProject project;
  final VoidCallback onClose;

  const ProjectView({
    super.key,
    required this.store,
    required this.project,
    required this.onClose,
  });

  @override
  State<ProjectView> createState() => _ProjectViewState();
}

class _ProjectViewState extends State<ProjectView> {
  int _tab = 0;

  /// 인원별 탭에서 선택된 인원. null이면 첫 인원.
  String? _focusMemberId;

  /// 통합 탭에서 인원 카드를 누르면 인원별 탭으로 이동.
  void _openMember(String memberId) {
    setState(() {
      _focusMemberId = memberId;
      _tab = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    final wide = MediaQuery.of(context).size.width >= 768;
    final flows = pairFlows(p);
    final remaining = flows.fold(0, (s, f) => s + f.amount);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 헤더 ──
              Row(
                children: [
                  GhostButton(
                    label: '프로젝트',
                    icon: Icons.arrow_back,
                    dense: true,
                    onTap: widget.onClose,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Segoe UI',
                        fontSize: wide ? 26 : 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        color: AppColors.snow,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── 요약 스탯 ──
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _Stat(
                    label: '총 지출',
                    value: formatWonUnit(totalSpent(p)),
                    sub: '${p.expenses.length}건',
                    width: wide ? 240 : double.infinity,
                  ),
                  _Stat(
                    label: '남은 송금',
                    value: formatWonUnit(remaining),
                    sub: '${flows.length}건',
                    accent: flows.isEmpty
                        ? AppColors.signalGreen
                        : AppColors.warning,
                    width: wide ? 240 : double.infinity,
                  ),
                  _Stat(
                    label: '인원',
                    value: '${p.members.length}명',
                    sub: p.members.map((m) => m.name).join(', '),
                    width: wide ? 300 : double.infinity,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: ProgressBar(value: settledRatio(p))),
                  const SizedBox(width: 12),
                  Text(
                    '${(settledRatio(p) * 100).round()}% 정산됨',
                    style: const TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 12,
                        color: AppColors.steel),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── 탭 ──
              _TabBar(
                index: _tab,
                labels: const ['지출 기록', '통합 정산', '인원별'],
                counts: [
                  p.expenses.length,
                  flows.length,
                  p.members.length,
                ],
                onChanged: (i) => setState(() => _tab = i),
              ),
              const SizedBox(height: 20),

              if (_tab == 0)
                ExpensesTab(store: widget.store, project: p)
              else if (_tab == 1)
                OverviewTab(
                  store: widget.store,
                  project: p,
                  onOpenMember: _openMember,
                )
              else
                MembersTab(
                  store: widget.store,
                  project: p,
                  selectedId: _focusMemberId,
                  onSelect: (id) => setState(() => _focusMemberId = id),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color accent;
  final double width;

  const _Stat({
    required this.label,
    required this.value,
    required this.sub,
    required this.width,
    this.accent = AppColors.snow,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: PanelCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: AppColors.steel,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Consolas',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.parchment),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final int index;
  final List<String> labels;
  final List<int> counts;
  final ValueChanged<int> onChanged;

  const _TabBar({
    required this.index,
    required this.labels,
    required this.counts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.warmCharcoal)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            _TabButton(
              label: labels[i],
              count: counts[i],
              selected: i == index,
              onTap: () => onChanged(i),
            ),
        ],
      ),
    );
  }
}

class _TabButton extends StatefulWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.selected;
    final fg = on
        ? AppColors.signalGreen
        : (_hover ? AppColors.snow : AppColors.steel);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: on ? AppColors.signalGreen : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.count}',
                style: TextStyle(
                  fontFamily: 'Consolas',
                  fontSize: 12,
                  color: fg.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
