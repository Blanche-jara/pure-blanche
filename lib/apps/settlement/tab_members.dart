/// 정산표 — 탭 3: 인원별 페이지.
/// 그 사람이 **누구에게 얼마를 보내야 하는지 건별로** 보여주고,
/// 건마다 "입금했습니다"로 정산 처리한다.
library;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'controller.dart';
import 'engine.dart';
import 'models.dart';
import 'ui_kit.dart';

class MembersTab extends StatelessWidget {
  final SettlementController controller;
  final SettlementProject project;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const MembersTab({
    super.key,
    required this.controller,
    required this.project,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (project.members.isEmpty) {
      return const EmptyHint(
        icon: Icons.person_outline,
        title: '등록된 인원이 없다.',
      );
    }

    final meId = project.members.any((m) => m.id == selectedId)
        ? selectedId!
        : project.members.first.id;

    final summaries = memberSummaries(project);
    final mine = summaries.firstWhere((s) => s.memberId == meId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 인원 선택 ──
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in summaries)
              MemberChip(
                name: project.nameOf(s.memberId),
                selected: s.memberId == meId,
                badge: s.toSend > 0
                    ? '-${formatWon(s.toSend)}'
                    : s.toReceive > 0
                        ? '+${formatWon(s.toReceive)}'
                        : '✓',
                accent: s.toSend > 0
                    ? AppColors.danger
                    : AppColors.signalGreen,
                onTap: () => onSelect(s.memberId),
              ),
          ],
        ),
        SizedBox(height: isCompact(context) ? 14 : 22),

        _MemberHeadline(project: project, summary: mine),
        SizedBox(height: isCompact(context) ? 16 : 24),

        _OutgoingSection(controller: controller, project: project, meId: meId),
        SizedBox(height: isCompact(context) ? 20 : 30),
        _IncomingSection(controller: controller, project: project, meId: meId),
      ],
    );
  }
}

/// 선택된 인원의 최종 결론(보낼 돈 / 받을 돈).
class _MemberHeadline extends StatelessWidget {
  final SettlementProject project;
  final MemberSummary summary;

  const _MemberHeadline({required this.project, required this.summary});

  @override
  Widget build(BuildContext context) {
    final compact = isCompact(context);
    final flows = pairFlows(project);
    final outgoing = flows.where((f) => f.fromId == summary.memberId).toList();
    final incoming = flows.where((f) => f.toId == summary.memberId).toList();
    final name = project.nameOf(summary.memberId);

    return PanelCard(
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              fontFamily: 'Segoe UI',
              fontSize: compact ? 17 : 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: AppColors.snow,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '결제 ${formatWonUnit(summary.paid)} · 본인 부담 ${formatWonUnit(summary.share)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: compact ? 11.5 : 12.5, color: AppColors.steel),
          ),
          SizedBox(height: compact ? 10 : 16),
          if (outgoing.isEmpty && incoming.isEmpty)
            const Row(
              children: [
                Icon(Icons.verified, size: 18, color: AppColors.signalGreen),
                SizedBox(width: 8),
                Text(
                  '주고받을 돈이 없다. 정산 끝.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.signalGreen,
                  ),
                ),
              ],
            ),
          for (final f in outgoing)
            _HeadlineLine(
              prefix: '$name →',
              target: project.nameOf(f.toId),
              amount: f.amount,
              color: AppColors.danger,
              suffix: '보내야 함',
            ),
          for (final f in incoming)
            _HeadlineLine(
              prefix: '${project.nameOf(f.fromId)} →',
              target: name,
              amount: f.amount,
              color: AppColors.signalGreen,
              suffix: '받을 예정',
            ),
        ],
      ),
    );
  }
}

class _HeadlineLine extends StatelessWidget {
  final String prefix;
  final String target;
  final int amount;
  final Color color;
  final String suffix;

  const _HeadlineLine({
    required this.prefix,
    required this.target,
    required this.amount,
    required this.color,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final compact = isCompact(context);
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 5 : 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$prefix $target',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: AppColors.snow,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Money(amount, size: compact ? 14 : 16, color: color),
          SizedBox(width: compact ? 5 : 8),
          Text(
            suffix,
            style: TextStyle(
                fontSize: compact ? 10.5 : 11.5, color: AppColors.steel),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── 내가 보내야 할 건 ───────────────────────

class _OutgoingSection extends StatelessWidget {
  final SettlementController controller;
  final SettlementProject project;
  final String meId;

  const _OutgoingSection({
    required this.controller,
    required this.project,
    required this.meId,
  });

  @override
  Widget build(BuildContext context) {
    final legs = legsOwedBy(project, meId);
    // 채권자별로 묶는다(멤버 순서 유지).
    final byCreditor = <String, List<DebtLeg>>{};
    for (final l in legs) {
      byCreditor.putIfAbsent(l.creditorId, () => []).add(l);
    }
    final creditorIds = project.members
        .map((m) => m.id)
        .where(byCreditor.containsKey)
        .toList();

    final pending = legs.where((l) => !l.settled).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          '보내야 할 건',
          trailingText: legs.isEmpty
              ? null
              : (pending == 0 ? '전부 입금 완료' : '미입금 $pending건'),
        ),
        if (legs.isEmpty)
          const EmptyHint(
            icon: Icons.outbox_outlined,
            title: '보낼 돈이 없다.',
            subtitle: '이 사람이 부담해야 할 지출을 다른 사람이 결제한 적이 없다.',
          )
        else
          for (final cid in creditorIds)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _CreditorGroup(
                controller: controller,
                project: project,
                meId: meId,
                creditorId: cid,
                legs: byCreditor[cid]!,
              ),
            ),
      ],
    );
  }
}

class _CreditorGroup extends StatelessWidget {
  final SettlementController controller;
  final SettlementProject project;
  final String meId;
  final String creditorId;
  final List<DebtLeg> legs;

  const _CreditorGroup({
    required this.controller,
    required this.project,
    required this.meId,
    required this.creditorId,
    required this.legs,
  });

  @override
  Widget build(BuildContext context) {
    final pending = legs.where((l) => !l.settled).toList();
    final pendingTotal = pending.fold(0, (s, l) => s + l.amount);

    final compact = isCompact(context);
    return PanelCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 16,
        vertical: compact ? 9 : 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.north_east, size: 14, color: AppColors.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${project.nameOf(creditorId)} 에게',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Segoe UI',
                    fontSize: compact ? 14 : 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.snow,
                  ),
                ),
              ),
              Money(
                pendingTotal,
                size: compact ? 14.5 : 16,
                color: pendingTotal > 0
                    ? AppColors.danger
                    : AppColors.signalGreen,
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            pending.isEmpty
                ? '${legs.length}건 전부 입금 완료'
                : '미입금 ${pending.length}건 / 전체 ${legs.length}건',
            style: TextStyle(
              fontSize: compact ? 10.5 : 11.5,
              color: pending.isEmpty ? AppColors.signalGreen : AppColors.steel,
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          for (final leg in legs)
            _LegRow(
              controller: controller,
              project: project,
              leg: leg,
              counterpartLabel: null,
            ),
          if (pending.length > 1) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: GhostButton(
                label: compact
                    ? '${pending.length}건 한번에'
                    : '${pending.length}건 한번에 입금 완료',
                icon: Icons.done_all,
                dense: true,
                onTap: () {
                  controller.settleLegs(pending);
                  showToast(context,
                      '${project.nameOf(creditorId)} 건 ${pending.length}개 정산 처리');
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────── 나에게 들어올 건 ───────────────────────

class _IncomingSection extends StatelessWidget {
  final SettlementController controller;
  final SettlementProject project;
  final String meId;

  const _IncomingSection({
    required this.controller,
    required this.project,
    required this.meId,
  });

  @override
  Widget build(BuildContext context) {
    final legs = legsOwedTo(project, meId);
    final byDebtor = <String, List<DebtLeg>>{};
    for (final l in legs) {
      byDebtor.putIfAbsent(l.debtorId, () => []).add(l);
    }
    final debtorIds =
        project.members.map((m) => m.id).where(byDebtor.containsKey).toList();
    final pending = legs.where((l) => !l.settled).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          '받아야 할 건',
          trailingText: legs.isEmpty
              ? null
              : (pending == 0 ? '전부 입금 확인' : '미입금 $pending건'),
        ),
        if (legs.isEmpty)
          const EmptyHint(
            icon: Icons.inbox_outlined,
            title: '받을 돈이 없다.',
            subtitle: '이 사람이 남을 대신해 결제한 지출이 없다.',
          )
        else
          for (final did in debtorIds)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _DebtorGroup(
                controller: controller,
                project: project,
                debtorId: did,
                legs: byDebtor[did]!,
              ),
            ),
      ],
    );
  }
}

class _DebtorGroup extends StatelessWidget {
  final SettlementController controller;
  final SettlementProject project;
  final String debtorId;
  final List<DebtLeg> legs;

  const _DebtorGroup({
    required this.controller,
    required this.project,
    required this.debtorId,
    required this.legs,
  });

  @override
  Widget build(BuildContext context) {
    final pending = legs.where((l) => !l.settled).toList();
    final pendingTotal = pending.fold(0, (s, l) => s + l.amount);

    final compact = isCompact(context);
    return PanelCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 16,
        vertical: compact ? 9 : 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.south_west,
                  size: 14, color: AppColors.signalGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${project.nameOf(debtorId)} 에게서',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Segoe UI',
                    fontSize: compact ? 14 : 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.snow,
                  ),
                ),
              ),
              Money(
                pendingTotal,
                size: compact ? 14.5 : 16,
                color: pendingTotal > 0
                    ? AppColors.signalGreen
                    : AppColors.steel,
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 12),
          for (final leg in legs)
            _LegRow(
              controller: controller,
              project: project,
              leg: leg,
              counterpartLabel: '입금 확인',
            ),
        ],
      ),
    );
  }
}

// ─────────────────────── 건 한 줄 ───────────────────────

/// 채무 건 하나. 오른쪽 버튼이 이 건의 정산 여부를 토글한다.
/// [counterpartLabel] 이 있으면 그 문구를 버튼에 쓴다(받는 쪽 관점: "입금 확인").
class _LegRow extends StatelessWidget {
  final SettlementController controller;
  final SettlementProject project;
  final DebtLeg leg;
  final String? counterpartLabel;

  const _LegRow({
    required this.controller,
    required this.project,
    required this.leg,
    required this.counterpartLabel,
  });

  @override
  Widget build(BuildContext context) {
    final settled = leg.settled;
    final compact = isCompact(context);

    return Container(
      margin: EdgeInsets.only(bottom: compact ? 5 : 8),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 12,
        vertical: compact ? 7 : 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.abyss,
        border: Border.all(
          color: settled
              ? AppColors.signalGreen.withValues(alpha: 0.35)
              : AppColors.warmCharcoal,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      // 좁은 화면에서는 한 줄에 [제목·금액·버튼]을 다 넣으면 제목이 몇 글자로 뭉개진다.
      // 그래서 모바일은 2줄로 쪼갠다 — 위: 제목+금액 / 아래: 근거+버튼.
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _title(settled, compact)),
                    const SizedBox(width: 8),
                    Money(
                      leg.amount,
                      size: 13,
                      color: settled ? AppColors.steel : AppColors.snow,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: _meta(settled, compact)),
                    const SizedBox(width: 8),
                    _actionButton(context, settled, compact),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _title(settled, compact),
                      const SizedBox(height: 3),
                      _meta(settled, compact),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Money(
                  leg.amount,
                  size: 14,
                  color: settled ? AppColors.steel : AppColors.snow,
                ),
                const SizedBox(width: 10),
                _actionButton(context, settled, compact),
              ],
            ),
    );
  }

  Widget _title(bool settled, bool compact) => Text(
        leg.expenseTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: compact ? 12.5 : 13.5,
          fontWeight: FontWeight.w600,
          color: settled ? AppColors.steel : AppColors.snow,
          decoration: settled ? TextDecoration.lineThrough : null,
        ),
      );

  Widget _meta(bool settled, bool compact) => Text(
        '${formatDay(leg.createdAt)} · '
        '${formatWonUnit(leg.expenseAmount)} ÷ ${leg.participantCount}명'
        '${settled ? ' · 완료' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Consolas',
          fontSize: compact ? 10 : 11,
          color: AppColors.steel,
        ),
      );

  Widget _actionButton(BuildContext context, bool settled, bool compact) {
    if (settled) {
      return GhostButton(
        label: '취소',
        icon: compact ? null : Icons.undo,
        dense: true,
        color: AppColors.warning,
        onTap: () =>
            controller.setLegSettled(leg.expenseId, leg.debtorId, false),
      );
    }
    return PrimaryButton(
      // 모바일에선 버튼이 화면을 다 먹지 않게 짧게.
      label: compact
          ? (counterpartLabel == null ? '입금' : '확인')
          : (counterpartLabel ?? '입금했습니다'),
      icon: Icons.check,
      dense: true,
      onTap: () {
        controller.setLegSettled(leg.expenseId, leg.debtorId, true);
        showToast(context, '${leg.expenseTitle} 정산 처리');
      },
    );
  }
}
