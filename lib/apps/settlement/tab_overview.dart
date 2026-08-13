/// 정산표 — 탭 2: 통합 정산(쌍별 상계 화살표 + 인원 요약).
library;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'controller.dart';
import 'dialogs.dart';
import 'engine.dart';
import 'models.dart';
import 'ui_kit.dart';

class OverviewTab extends StatelessWidget {
  final SettlementController controller;
  final SettlementProject project;
  final ValueChanged<String> onOpenMember;

  const OverviewTab({
    super.key,
    required this.controller,
    required this.project,
    required this.onOpenMember,
  });

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 768;
    final flows = pairFlows(project);
    final summaries = memberSummaries(project);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          '최종 송금',
          trailingText: flows.isEmpty ? null : '${flows.length}건',
          action: GhostButton(
            label: '송금 기록',
            icon: Icons.swap_horiz,
            dense: true,
            onTap: () => showTransferDialog(
              context: context,
              controller: controller,
              project: project,
            ),
          ),
        ),
        if (project.expenses.isEmpty)
          const EmptyHint(
            icon: Icons.hub_outlined,
            title: '아직 계산할 지출이 없다.',
            subtitle: '"지출 기록" 탭에서 결제 건을 추가하면 여기에 화살표가 그려진다.',
          )
        else if (flows.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.signalGreen.withValues(alpha: 0.05),
              border: Border.all(
                  color: AppColors.signalGreen.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              children: [
                Icon(Icons.verified, size: 30, color: AppColors.signalGreen),
                SizedBox(height: 12),
                Text(
                  '정산 완료. 남은 송금이 없다.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.signalGreen,
                  ),
                ),
              ],
            ),
          )
        else
          for (final f in flows)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FlowRow(
                controller: controller,
                project: project,
                flow: f,
                wide: wide,
              ),
            ),
        const SizedBox(height: 32),
        const SectionTitle('인원 요약'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final s in summaries)
              SizedBox(
                width: wide ? 258 : double.infinity,
                child: _MemberSummaryCard(
                  project: project,
                  summary: s,
                  onTap: () => onOpenMember(s.memberId),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _FlowRow extends StatelessWidget {
  final SettlementController controller;
  final SettlementProject project;
  final PairFlow flow;
  final bool wide;

  const _FlowRow({
    required this.controller,
    required this.project,
    required this.flow,
    required this.wide,
  });

  /// 상계 근거 한 줄. 예: "채무 52,300원 − 역방향 15,000원 − 이미 송금 5,000원".
  String get _breakdown {
    final parts = <String>['채무 ${formatWonUnit(flow.rawForward)}'];
    if (flow.rawBackward > 0) {
      parts.add('역방향 ${formatWonUnit(flow.rawBackward)} 상계');
    }
    if (flow.transferred != 0) {
      parts.add(flow.transferred > 0
          ? '이미 송금 ${formatWonUnit(flow.transferred)}'
          : '역송금 ${formatWonUnit(-flow.transferred)}');
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final fromName = project.nameOf(flow.fromId);
    final toName = project.nameOf(flow.toId);

    return PanelCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (wide)
            Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    fromName,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.snow,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 1,
                          color:
                              AppColors.signalGreen.withValues(alpha: 0.35),
                        ),
                        Container(
                          color: AppColors.carbon,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Money(flow.amount,
                              size: 17, color: AppColors.signalGreen),
                        ),
                      ],
                    ),
                  ),
                ),
                const Icon(Icons.play_arrow,
                    size: 16, color: AppColors.signalGreen),
                const SizedBox(width: 10),
                SizedBox(
                  width: 110,
                  child: Text(
                    toName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.snow,
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$fromName → $toName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.snow,
                    ),
                  ),
                ),
                Money(flow.amount, size: 16, color: AppColors.signalGreen),
              ],
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  _breakdown,
                  style:
                      const TextStyle(fontSize: 11.5, color: AppColors.steel),
                ),
              ),
              const SizedBox(width: 10),
              GhostButton(
                label: '입금 기록',
                dense: true,
                onTap: () => showTransferDialog(
                  context: context,
                  controller: controller,
                  project: project,
                  fromId: flow.fromId,
                  toId: flow.toId,
                  amount: flow.amount,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberSummaryCard extends StatelessWidget {
  final SettlementProject project;
  final MemberSummary summary;
  final VoidCallback onTap;

  const _MemberSummaryCard({
    required this.project,
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final net = summary.net;
    final netColor = net > 0
        ? AppColors.signalGreen
        : net < 0
            ? AppColors.danger
            : AppColors.steel;

    return PanelCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.nameOf(summary.memberId),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Segoe UI',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.snow,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 16, color: AppColors.steel),
            ],
          ),
          const SizedBox(height: 10),
          _KV(label: '결제한 돈', value: formatWonUnit(summary.paid)),
          _KV(label: '본인 부담', value: formatWonUnit(summary.share)),
          const Divider(color: AppColors.warmCharcoal, height: 18),
          _KV(
            label: net >= 0 ? '더 낸 돈' : '덜 낸 돈',
            value: formatWonUnit(net.abs()),
            color: netColor,
            bold: true,
          ),
          const SizedBox(height: 8),
          if (summary.toSend > 0)
            _Pill(
              text: '보낼 ${formatWonUnit(summary.toSend)}',
              color: AppColors.danger,
            ),
          if (summary.toReceive > 0) ...[
            if (summary.toSend > 0) const SizedBox(height: 6),
            _Pill(
              text: '받을 ${formatWonUnit(summary.toReceive)}',
              color: AppColors.signalGreen,
            ),
          ],
          if (summary.toSend == 0 && summary.toReceive == 0)
            const _Pill(text: '정산 완료', color: AppColors.steel),
        ],
      ),
    );
  }
}

class _KV extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _KV({
    required this.label,
    required this.value,
    this.color = AppColors.parchment,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12.5, color: AppColors.steel)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Consolas',
              fontSize: bold ? 14 : 12.5,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Consolas',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
