/// 정산표 — 프로젝트 상세(헤더 + 3개 탭).
library;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'controller.dart';
import 'engine.dart';
import 'share.dart';
import 'tab_expenses.dart';
import 'tab_members.dart';
import 'tab_overview.dart';
import 'ui_kit.dart';

class ProjectView extends StatefulWidget {
  final SettlementController controller;
  final VoidCallback onClose;

  const ProjectView({
    super.key,
    required this.controller,
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
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final p = widget.controller.project;
    if (p == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EmptyHint(
                icon: Icons.help_outline,
                title: '정산표를 불러올 수 없다.',
                subtitle: '삭제되었거나 링크가 잘못됐을 수 있다.',
              ),
              const SizedBox(height: 16),
              GhostButton(label: '목록으로', onTap: widget.onClose),
            ],
          ),
        ),
      );
    }

    final flows = pairFlows(p);
    final remaining = flows.fold(0, (s, f) => s + f.amount);

    final compact = isCompact(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 40,
        vertical: compact ? 14 : 24,
      ),
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
                        fontSize: compact ? 19 : 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        color: AppColors.snow,
                      ),
                    ),
                  ),
                  if (widget.controller.busy) ...[
                    const SizedBox(width: 10),
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: AppColors.signalGreen,
                      ),
                    ),
                  ],
                  if (widget.controller.isShared) ...[
                    const SizedBox(width: 10),
                    GhostButton(
                      label: '새로고침',
                      icon: Icons.refresh,
                      dense: true,
                      onTap: widget.controller.refresh,
                    ),
                  ],
                ],
              ),
              SizedBox(height: compact ? 9 : 12),

              // ── 공유 상태 / 에러 ──
              ShareBanner(project: p),
              if (widget.controller.error != null) ...[
                const SizedBox(height: 10),
                _ErrorBanner(
                  message: widget.controller.error!,
                  onDismiss: widget.controller.clearError,
                  onRetry: widget.controller.refresh,
                ),
              ],
              SizedBox(height: compact ? 10 : 16),

              // ── 요약 스탯 ── 모바일은 한 줄에 3칸으로 눌러 담는다.
              if (compact)
                PanelCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MiniStat(
                            label: '총 지출',
                            value: formatWon(totalSpent(p)),
                            sub: '${p.expenses.length}건',
                          ),
                          _MiniStat(
                            label: '남은 송금',
                            value: formatWon(remaining),
                            sub: '${flows.length}건',
                            accent: flows.isEmpty
                                ? AppColors.signalGreen
                                : AppColors.warning,
                          ),
                          _MiniStat(
                            label: '인원',
                            value: '${p.members.length}',
                            sub: '${(settledRatio(p) * 100).round()}% 정산',
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      ProgressBar(value: settledRatio(p), height: 4),
                    ],
                  ),
                )
              else ...[
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _Stat(
                      label: '총 지출',
                      value: formatWonUnit(totalSpent(p)),
                      sub: '${p.expenses.length}건',
                      width: 240,
                    ),
                    _Stat(
                      label: '남은 송금',
                      value: formatWonUnit(remaining),
                      sub: '${flows.length}건',
                      accent: flows.isEmpty
                          ? AppColors.signalGreen
                          : AppColors.warning,
                      width: 240,
                    ),
                    _Stat(
                      label: '인원',
                      value: '${p.members.length}명',
                      sub: p.members.map((m) => m.name).join(', '),
                      width: 300,
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
              ],
              SizedBox(height: compact ? 14 : 24),

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
              SizedBox(height: compact ? 14 : 20),

              if (_tab == 0)
                ExpensesTab(controller: widget.controller, project: p)
              else if (_tab == 1)
                OverviewTab(
                  controller: widget.controller,
                  project: p,
                  onOpenMember: _openMember,
                )
              else
                MembersTab(
                  controller: widget.controller,
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

/// 서버 요청 실패 배너. 이전 상태는 그대로 두고 메시지만 알린다.
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  final VoidCallback onRetry;

  const _ErrorBanner({
    required this.message,
    required this.onDismiss,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppColors.parchment),
            ),
          ),
          const SizedBox(width: 10),
          GhostButton(
            label: isCompact(context) ? '재시도' : '다시 불러오기',
            dense: true,
            color: AppColors.danger,
            onTap: onRetry,
          ),
          const SizedBox(width: 6),
          GhostButton(label: '닫기', dense: true, onTap: onDismiss),
        ],
      ),
    );
  }
}

/// 모바일 요약 스탯 한 칸. 세 개가 한 줄을 3등분한다.
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color accent;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.sub,
    this.accent = AppColors.snow,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: AppColors.steel,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'Consolas',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, color: AppColors.parchment),
          ),
        ],
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
          padding: EdgeInsets.symmetric(
            horizontal: pick(context, 11.0, 16.0),
            vertical: pick(context, 9.0, 12.0),
          ),
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
                  fontSize: pick(context, 13.0, 14.0),
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
