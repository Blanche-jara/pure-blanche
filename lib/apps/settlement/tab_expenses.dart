/// 정산표 — 탭 1: 지출 기록 + 직접 송금 기록.
library;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'dialogs.dart';
import 'engine.dart';
import 'models.dart';
import 'store.dart';
import 'ui_kit.dart';

class ExpensesTab extends StatelessWidget {
  final SettlementStore store;
  final SettlementProject project;

  const ExpensesTab({
    super.key,
    required this.store,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    final expenses = project.expenses.reversed.toList();
    final transfers = project.transfers.reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          '지출',
          trailingText: '${expenses.length}건',
          action: PrimaryButton(
            label: '지출 추가',
            icon: Icons.add,
            dense: true,
            onTap: () => showExpenseDialog(
              context: context,
              store: store,
              project: project,
            ),
          ),
        ),
        if (expenses.isEmpty)
          const EmptyHint(
            icon: Icons.receipt_outlined,
            title: '아직 지출이 없다.',
            subtitle: '"지출 추가"로 결제한 사람과 금액을 적으면 자동으로 채무가 만들어진다.',
          )
        else
          for (final e in expenses)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ExpenseRow(
                store: store,
                project: project,
                expense: e,
              ),
            ),
        const SizedBox(height: 32),
        SectionTitle(
          '직접 송금',
          trailingText: '${transfers.length}건',
          action: GhostButton(
            label: '송금 기록',
            icon: Icons.swap_horiz,
            dense: true,
            onTap: () => showTransferDialog(
              context: context,
              store: store,
              project: project,
            ),
          ),
        ),
        if (transfers.isEmpty)
          const EmptyHint(
            icon: Icons.swap_horiz,
            title: '기록된 송금이 없다.',
            subtitle: '건별 정산과 별개로 뭉텅이 입금이 오갔다면 여기에 적는다.',
          )
        else
          for (final t in transfers)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TransferRow(
                store: store,
                project: project,
                transfer: t,
              ),
            ),
      ],
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  final SettlementStore store;
  final SettlementProject project;
  final Expense expense;

  const _ExpenseRow({
    required this.store,
    required this.project,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final shares = sharesOf(expense);
    final others = expense.participantIds
        .where((id) => id != expense.payerId)
        .toList();
    final settledCount = others
        .where((id) =>
            project.settledLegs.contains(DebtLeg.legKey(expense.id, id)))
        .length;
    final allSettled = others.isEmpty || settledCount == others.length;

    return PanelCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            expense.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Segoe UI',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.snow,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatDay(expense.createdAt),
                          style: const TextStyle(
                              fontFamily: 'Consolas',
                              fontSize: 11.5,
                              color: AppColors.steel),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.steel),
                        children: [
                          TextSpan(
                            text: project.nameOf(expense.payerId),
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: ' 결제 · '),
                          TextSpan(
                            text: '${expense.participantIds.length}명 부담 · '
                                '1인 ${formatWonUnit(expense.amount ~/ expense.participantIds.length)}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Money(expense.amount, size: 17),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MiniIcon(
                        icon: Icons.edit_outlined,
                        tooltip: '수정',
                        onTap: () => showExpenseDialog(
                          context: context,
                          store: store,
                          project: project,
                          existing: expense,
                        ),
                      ),
                      _MiniIcon(
                        icon: Icons.delete_outline,
                        tooltip: '삭제',
                        color: AppColors.danger,
                        onTap: () async {
                          final ok = await confirmDialog(
                            context: context,
                            title: '지출 삭제',
                            message:
                                '"${expense.title}" (${formatWonUnit(expense.amount)}) 을(를) 삭제한다. '
                                '이 지출에서 만들어진 채무와 정산 표시도 함께 사라진다.',
                          );
                          if (ok) store.removeExpense(project.id, expense.id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final id in expense.participantIds)
                _ShareChip(
                  name: project.nameOf(id),
                  amount: shares[id] ?? 0,
                  isPayer: id == expense.payerId,
                  settled: id != expense.payerId &&
                      project.settledLegs
                          .contains(DebtLeg.legKey(expense.id, id)),
                ),
            ],
          ),
          if (others.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              allSettled
                  ? '이 건은 전원 입금 완료'
                  : '입금 완료 $settledCount / ${others.length}명',
              style: TextStyle(
                fontSize: 11.5,
                color:
                    allSettled ? AppColors.signalGreen : AppColors.steel,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShareChip extends StatelessWidget {
  final String name;
  final int amount;
  final bool isPayer;
  final bool settled;

  const _ShareChip({
    required this.name,
    required this.amount,
    required this.isPayer,
    required this.settled,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPayer
        ? AppColors.warning
        : settled
            ? AppColors.signalGreen
            : AppColors.parchment;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.abyss,
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPayer) ...[
            const Icon(Icons.credit_card, size: 12, color: AppColors.warning),
            const SizedBox(width: 5),
          ] else if (settled) ...[
            const Icon(Icons.check, size: 12, color: AppColors.signalGreen),
            const SizedBox(width: 5),
          ],
          Text(
            name,
            style: TextStyle(fontSize: 12, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            formatWon(amount),
            style: TextStyle(
              fontFamily: 'Consolas',
              fontSize: 11.5,
              color: color.withValues(alpha: 0.75),
              decoration: settled ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferRow extends StatelessWidget {
  final SettlementStore store;
  final SettlementProject project;
  final Transfer transfer;

  const _TransferRow({
    required this.store,
    required this.project,
    required this.transfer,
  });

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    project.nameOf(transfer.fromId),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.snow),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.arrow_forward,
                      size: 14, color: AppColors.signalGreen),
                ),
                Flexible(
                  child: Text(
                    project.nameOf(transfer.toId),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.snow),
                  ),
                ),
                if (transfer.memo.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      transfer.memo,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.steel),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatDay(transfer.createdAt),
            style: const TextStyle(
                fontFamily: 'Consolas',
                fontSize: 11.5,
                color: AppColors.steel),
          ),
          const SizedBox(width: 12),
          Money(transfer.amount, size: 15, color: AppColors.mint),
          const SizedBox(width: 4),
          _MiniIcon(
            icon: Icons.delete_outline,
            tooltip: '삭제',
            color: AppColors.danger,
            onTap: () => store.removeTransfer(project.id, transfer.id),
          ),
        ],
      ),
    );
  }
}

class _MiniIcon extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color? color;
  final VoidCallback onTap;

  const _MiniIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  State<_MiniIcon> createState() => _MiniIconState();
}

class _MiniIconState extends State<_MiniIcon> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            child: Icon(
              widget.icon,
              size: 16,
              color: _hover
                  ? (widget.color ?? AppColors.signalGreen)
                  : AppColors.steel,
            ),
          ),
        ),
      ),
    );
  }
}
