/// 정산표 — 입력 다이얼로그(지출 추가/수정, 직접 송금 기록).
library;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'controller.dart';
import 'engine.dart';
import 'models.dart';
import 'ui_kit.dart';

/// 지출 추가/수정. [existing] 이 있으면 수정 모드.
Future<void> showExpenseDialog({
  required BuildContext context,
  required SettlementController controller,
  required SettlementProject project,
  Expense? existing,
}) {
  return showSettlementDialog<void>(
    context: context,
    title: existing == null ? '지출 추가' : '지출 수정',
    maxWidth: 560,
    builder: (ctx) => _ExpenseForm(
      controller: controller,
      project: project,
      existing: existing,
    ),
  );
}

class _ExpenseForm extends StatefulWidget {
  final SettlementController controller;
  final SettlementProject project;
  final Expense? existing;

  const _ExpenseForm({
    required this.controller,
    required this.project,
    this.existing,
  });

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late String _payerId;
  late Set<String> _participants;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _amount = TextEditingController(text: e == null ? '' : '${e.amount}');
    _payerId = e?.payerId ?? widget.project.members.first.id;
    _participants = e != null
        ? e.participantIds.toSet()
        : widget.project.members.map((m) => m.id).toSet();
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  int get _amountValue => int.tryParse(_amount.text.trim()) ?? 0;

  /// 현재 입력 상태로 만든 가상 지출(미리보기 계산용).
  Expense get _preview => Expense(
        id: widget.existing?.id ?? '_preview',
        title: _title.text,
        amount: _amountValue,
        payerId: _payerId,
        participantIds: widget.project.members
            .map((m) => m.id)
            .where(_participants.contains)
            .toList(),
        createdAt: DateTime.now(),
      );

  void _submit() {
    final title = _title.text.trim();
    final amount = _amountValue;
    final ids = _preview.participantIds;

    if (title.isEmpty) {
      setState(() => _error = '항목명을 입력해주세요.');
      return;
    }
    if (amount <= 0) {
      setState(() => _error = '금액을 입력해주세요.');
      return;
    }
    if (ids.isEmpty) {
      setState(() => _error = '참여자를 최소 1명 선택해주세요.');
      return;
    }

    if (widget.existing == null) {
      widget.controller.addExpense(
        title: title,
        amount: amount,
        payerId: _payerId,
        participantIds: ids,
      );
    } else {
      widget.controller.updateExpense(
        widget.existing!.id,
        title: title,
        amount: amount,
        payerId: _payerId,
        participantIds: ids,
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    final compact = isCompact(context);
    final shares = _amountValue > 0 && _participants.isNotEmpty
        ? sharesOf(_preview)
        : const <String, int>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LabeledField(
          label: '항목명',
          controller: _title,
          hint: '예: 1차 삼겹살',
          maxLength: 30,
          autofocus: true,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: compact ? 10 : 14),
        LabeledField(
          label: '결제 금액 (원)',
          controller: _amount,
          hint: '97000',
          numeric: true,
          maxLength: 9,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: compact ? 12 : 18),

        // ── 결제자 ──
        const _FieldLabel('결제한 사람'),
        const SizedBox(height: 8),
        Wrap(
          spacing: compact ? 6 : 8,
          runSpacing: compact ? 6 : 8,
          children: [
            for (final m in p.members)
              MemberChip(
                name: m.name,
                selected: m.id == _payerId,
                accent: AppColors.warning,
                onTap: () => setState(() {
                  _payerId = m.id;
                  // 결제자는 보통 참여자이기도 하다.
                  _participants.add(m.id);
                }),
              ),
          ],
        ),
        SizedBox(height: compact ? 12 : 18),

        // ── 참여자 ──
        Row(
          children: [
            const _FieldLabel('나눠 낼 사람'),
            const SizedBox(width: 8),
            Text(
              '${_participants.length}명',
              style: const TextStyle(
                  fontFamily: 'Consolas',
                  fontSize: 11.5,
                  color: AppColors.steel),
            ),
            const Spacer(),
            GhostButton(
              label: _participants.length == p.members.length ? '전체 해제' : '전체',
              dense: true,
              onTap: () => setState(() {
                if (_participants.length == p.members.length) {
                  _participants = {_payerId};
                } else {
                  _participants = p.members.map((m) => m.id).toSet();
                }
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: compact ? 6 : 8,
          runSpacing: compact ? 6 : 8,
          children: [
            for (final m in p.members)
              MemberChip(
                name: m.name,
                selected: _participants.contains(m.id),
                badge: shares[m.id] != null ? formatWon(shares[m.id]!) : null,
                onTap: () => setState(() {
                  if (_participants.contains(m.id)) {
                    _participants.remove(m.id);
                  } else {
                    _participants.add(m.id);
                  }
                }),
              ),
          ],
        ),

        // ── 미리보기 ──
        if (shares.isNotEmpty) ...[
          SizedBox(height: compact ? 12 : 18),
          Container(
            padding: EdgeInsets.all(compact ? 10 : 14),
            decoration: BoxDecoration(
              color: AppColors.abyss,
              border: Border.all(
                  color: AppColors.signalGreen.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatWonUnit(_amountValue)} ÷ ${_participants.length}명',
                  style: const TextStyle(
                    fontFamily: 'Consolas',
                    fontSize: 12.5,
                    color: AppColors.steel,
                  ),
                ),
                const SizedBox(height: 8),
                for (final leg in legsOf(SettlementProject(
                  id: '_',
                  name: '_',
                  createdAt: DateTime.now(),
                  members: p.members,
                  expenses: [_preview],
                  transfers: const [],
                  settledLegs: const {},
                )))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.nameOf(leg.debtorId),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12.5, color: AppColors.snow),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.arrow_forward,
                              size: 12, color: AppColors.signalGreen),
                        ),
                        Flexible(
                          child: Text(
                            p.nameOf(leg.creditorId),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12.5, color: AppColors.snow),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Spacer(),
                        Money(leg.amount,
                            size: 12.5, color: AppColors.signalGreen),
                      ],
                    ),
                  ),
                if (_participants.contains(_payerId))
                  Text(
                    '${p.nameOf(_payerId)} 본인 부담 ${formatWonUnit(shares[_payerId] ?? 0)}'
                    '${(shares[_payerId] ?? 0) != (_amountValue ~/ _participants.length) ? ' (1원 단위 나머지 포함)' : ''}',
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.steel),
                  ),
              ],
            ),
          ),
        ],

        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!,
              style:
                  const TextStyle(fontSize: 12.5, color: AppColors.danger)),
        ],
        SizedBox(height: compact ? 16 : 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GhostButton(
                label: '취소', onTap: () => Navigator.of(context).pop()),
            const SizedBox(width: 8),
            PrimaryButton(
              label: widget.existing == null ? '추가' : '저장',
              icon: Icons.check,
              onTap: _submit,
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────── 직접 송금 기록 ───────────────────────────

/// 건과 무관하게 오간 송금 기록. [fromId]/[toId]/[amount] 로 초기값을 채울 수 있다.
Future<void> showTransferDialog({
  required BuildContext context,
  required SettlementController controller,
  required SettlementProject project,
  String? fromId,
  String? toId,
  int? amount,
}) {
  return showSettlementDialog<void>(
    context: context,
    title: '직접 송금 기록',
    maxWidth: 480,
    builder: (ctx) => _TransferForm(
      controller: controller,
      project: project,
      initialFrom: fromId,
      initialTo: toId,
      initialAmount: amount,
    ),
  );
}

class _TransferForm extends StatefulWidget {
  final SettlementController controller;
  final SettlementProject project;
  final String? initialFrom;
  final String? initialTo;
  final int? initialAmount;

  const _TransferForm({
    required this.controller,
    required this.project,
    this.initialFrom,
    this.initialTo,
    this.initialAmount,
  });

  @override
  State<_TransferForm> createState() => _TransferFormState();
}

class _TransferFormState extends State<_TransferForm> {
  late final TextEditingController _amount;
  late final TextEditingController _memo;
  String? _fromId;
  String? _toId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.initialAmount == null ? '' : '${widget.initialAmount}',
    );
    _memo = TextEditingController();
    _fromId = widget.initialFrom;
    _toId = widget.initialTo;
  }

  @override
  void dispose() {
    _amount.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = int.tryParse(_amount.text.trim()) ?? 0;
    if (_fromId == null || _toId == null) {
      setState(() => _error = '보낸 사람과 받은 사람을 선택해주세요.');
      return;
    }
    if (_fromId == _toId) {
      setState(() => _error = '보낸 사람과 받은 사람이 같다.');
      return;
    }
    if (amount <= 0) {
      setState(() => _error = '금액을 입력해주세요.');
      return;
    }

    // 다이얼로그가 닫힌 뒤에 알려야 하므로 messenger를 미리 잡아둔다.
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    final settled = await widget.controller.addTransfer(
      fromId: _fromId!,
      toId: _toId!,
      amount: amount,
      memo: _memo.text.trim(),
    );
    showToastOn(
      messenger,
      settled > 0 ? '송금 기록 · $settled건 자동 정산' : '송금 기록 (선입금으로 남음)',
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.project;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.07),
            border:
                Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '보낸 금액만큼 오래된 건부터 자동으로 정산 처리된다. '
            '남는 금액은 선입금으로 남아 다음 정산에서 차감된다.',
            style: TextStyle(
                fontSize: 12, color: AppColors.parchment, height: 1.55),
          ),
        ),
        const SizedBox(height: 18),
        const _FieldLabel('보낸 사람'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in p.members)
              MemberChip(
                name: m.name,
                selected: m.id == _fromId,
                accent: AppColors.danger,
                onTap: () => setState(() => _fromId = m.id),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const _FieldLabel('받은 사람'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in p.members)
              MemberChip(
                name: m.name,
                selected: m.id == _toId,
                onTap: () => setState(() => _toId = m.id),
              ),
          ],
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: '금액 (원)',
          controller: _amount,
          hint: '50000',
          numeric: true,
          maxLength: 9,
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: '메모 (선택)',
          controller: _memo,
          hint: '예: 계좌이체',
          maxLength: 30,
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!,
              style:
                  const TextStyle(fontSize: 12.5, color: AppColors.danger)),
        ],
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GhostButton(
                label: '취소', onTap: () => Navigator.of(context).pop()),
            const SizedBox(width: 8),
            PrimaryButton(label: '기록', icon: Icons.check, onTap: _submit),
          ],
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: AppColors.steel,
        ),
      );
}
