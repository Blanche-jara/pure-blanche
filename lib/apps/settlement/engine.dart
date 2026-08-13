/// 정산표 — 계산 엔진(순수 함수만. UI/저장소 의존 없음).
///
/// ## 계산 흐름
/// 1. **지출 → 채무 줄(leg)**: 지출 한 건을 참여자 수로 균등분할하고,
///    결제자를 제외한 각 참여자가 결제자에게 자기 몫을 갚는 [DebtLeg] 을 만든다.
///    1원 단위 나머지는 **결제자가 더 부담**한다(다른 사람들은 깔끔한 금액).
/// 2. **정산 처리 제외**: 개인 페이지에서 "입금했습니다"를 누른 leg는 계산에서 빠진다.
/// 3. **쌍별 상계**: 두 사람 사이 양방향 채무와 직접 송금을 한 줄로 합친다.
///    `net(A→B) = 미정산(A→B) - 미정산(B→A) - 직접송금순액(A→B)`
library;

import 'models.dart';

/// 지출 한 건의 인원별 부담액. 반환값 합계는 항상 [Expense.amount] 와 정확히 같다.
///
/// 균등분할 후 남는 1원 단위는 결제자가 먼저 흡수하고, 그래도 남으면
/// 참여자 순서대로 1원씩 더 부담한다.
Map<String, int> sharesOf(Expense expense) {
  final ids = expense.participantIds;
  if (ids.isEmpty) return const {};

  final base = expense.amount ~/ ids.length;
  var remainder = expense.amount - base * ids.length;

  // 나머지를 떠안을 순서: 결제자 우선, 그 다음 입력 순서.
  final order = <String>[
    if (ids.contains(expense.payerId)) expense.payerId,
    ...ids.where((id) => id != expense.payerId),
  ];

  final result = {for (final id in ids) id: base};
  for (final id in order) {
    if (remainder <= 0) break;
    result[id] = result[id]! + 1;
    remainder--;
  }
  return result;
}

/// 프로젝트 전체의 채무 줄 목록(최신 지출이 앞).
///
/// 결제자 본인의 몫은 leg가 되지 않는다(자기 자신에게 보낼 필요 없음).
List<DebtLeg> legsOf(SettlementProject project) {
  final legs = <DebtLeg>[];
  for (final e in project.expenses) {
    final shares = sharesOf(e);
    for (final entry in shares.entries) {
      if (entry.key == e.payerId) continue;
      if (entry.value <= 0) continue;
      legs.add(DebtLeg(
        expenseId: e.id,
        expenseTitle: e.title,
        debtorId: entry.key,
        creditorId: e.payerId,
        amount: entry.value,
        createdAt: e.createdAt,
        expenseAmount: e.amount,
        participantCount: e.participantIds.length,
        settled: project.settledLegs.contains(
          DebtLeg.legKey(e.id, entry.key),
        ),
      ));
    }
  }
  legs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return legs;
}

/// [memberId] 가 **갚아야 할** 채무 줄들(최신순).
List<DebtLeg> legsOwedBy(SettlementProject project, String memberId) =>
    legsOf(project).where((l) => l.debtorId == memberId).toList();

/// [memberId] 가 **받아야 할** 채무 줄들(최신순).
List<DebtLeg> legsOwedTo(SettlementProject project, String memberId) =>
    legsOf(project).where((l) => l.creditorId == memberId).toList();

/// 쌍별 상계 결과. 실제로 송금이 필요한 줄만(금액 > 0) 담기며,
/// 금액 내림차순 정렬.
List<PairFlow> pairFlows(SettlementProject project) {
  // 미정산 채무를 (debtor, creditor) 쌍으로 합산.
  final raw = <String, int>{}; // 'from>to' → 합계
  for (final leg in legsOf(project)) {
    if (leg.settled) continue;
    final k = '${leg.debtorId}>${leg.creditorId}';
    raw[k] = (raw[k] ?? 0) + leg.amount;
  }

  // 직접 송금은 채무를 줄인다(보낸 사람 기준 차감).
  final sent = <String, int>{}; // 'from>to' → 합계
  for (final t in project.transfers) {
    final k = '${t.fromId}>${t.toId}';
    sent[k] = (sent[k] ?? 0) + t.amount;
  }

  final flows = <PairFlow>[];
  final members = project.members;
  for (var i = 0; i < members.length; i++) {
    for (var j = i + 1; j < members.length; j++) {
      final a = members[i].id;
      final b = members[j].id;

      final forward = raw['$a>$b'] ?? 0; // a가 b에게 갚을 돈
      final backward = raw['$b>$a'] ?? 0; // b가 a에게 갚을 돈
      final transferNet = (sent['$a>$b'] ?? 0) - (sent['$b>$a'] ?? 0);

      final net = forward - backward - transferNet;
      if (net == 0) continue;

      if (net > 0) {
        flows.add(PairFlow(
          fromId: a,
          toId: b,
          amount: net,
          rawForward: forward,
          rawBackward: backward,
          transferred: transferNet,
        ));
      } else {
        flows.add(PairFlow(
          fromId: b,
          toId: a,
          amount: -net,
          rawForward: backward,
          rawBackward: forward,
          transferred: -transferNet,
        ));
      }
    }
  }

  flows.sort((x, y) => y.amount.compareTo(x.amount));
  return flows;
}

/// 인원별 요약(멤버 목록 순서 유지).
List<MemberSummary> memberSummaries(SettlementProject project) {
  final paid = {for (final m in project.members) m.id: 0};
  final share = {for (final m in project.members) m.id: 0};

  for (final e in project.expenses) {
    paid[e.payerId] = (paid[e.payerId] ?? 0) + e.amount;
    sharesOf(e).forEach((id, v) => share[id] = (share[id] ?? 0) + v);
  }

  final send = {for (final m in project.members) m.id: 0};
  final receive = {for (final m in project.members) m.id: 0};
  for (final f in pairFlows(project)) {
    send[f.fromId] = (send[f.fromId] ?? 0) + f.amount;
    receive[f.toId] = (receive[f.toId] ?? 0) + f.amount;
  }

  return project.members
      .map((m) => MemberSummary(
            memberId: m.id,
            paid: paid[m.id] ?? 0,
            share: share[m.id] ?? 0,
            toSend: send[m.id] ?? 0,
            toReceive: receive[m.id] ?? 0,
          ))
      .toList();
}

/// 프로젝트 총 지출액.
int totalSpent(SettlementProject project) =>
    project.expenses.fold(0, (sum, e) => sum + e.amount);

/// 정산 진행률 0.0~1.0 (정산 처리된 채무 줄 비율). 채무가 없으면 1.0.
double settledRatio(SettlementProject project) {
  final legs = legsOf(project);
  if (legs.isEmpty) return 1.0;
  final done = legs.where((l) => l.settled).length;
  return done / legs.length;
}

/// 남은 송금이 하나도 없으면 true.
bool isFullySettled(SettlementProject project) => pairFlows(project).isEmpty;
