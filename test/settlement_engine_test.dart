import 'package:flutter_test/flutter_test.dart';
import 'package:pure_blanche/apps/settlement/engine.dart';
import 'package:pure_blanche/apps/settlement/models.dart';

final _t0 = DateTime(2026, 8, 13);

SettlementProject _project({
  List<Expense> expenses = const [],
  List<Transfer> transfers = const [],
  Set<String> settled = const {},
}) =>
    SettlementProject(
      id: 'p',
      name: '테스트',
      createdAt: _t0,
      members: const [
        Member(id: 'a', name: '나'),
        Member(id: 'b', name: '민수'),
        Member(id: 'c', name: '지연'),
      ],
      expenses: expenses,
      transfers: transfers,
      settledLegs: settled,
    );

Expense _expense({
  required String id,
  required int amount,
  required String payer,
  required List<String> participants,
  int dayOffset = 0,
}) =>
    Expense(
      id: id,
      title: id,
      amount: amount,
      payerId: payer,
      participantIds: participants,
      createdAt: _t0.add(Duration(days: dayOffset)),
    );

void main() {
  group('sharesOf', () {
    test('나눠떨어지지 않는 금액은 결제자가 나머지를 흡수한다', () {
      final e = _expense(
          id: 'e1', amount: 97000, payer: 'a', participants: ['a', 'b', 'c']);
      final s = sharesOf(e);

      expect(s['a'], 32334); // 결제자가 +1원
      expect(s['b'], 32333);
      expect(s['c'], 32333);
      expect(s.values.reduce((x, y) => x + y), 97000); // 합계 = 총액
    });

    test('결제자가 참여자가 아니면 참여자 순서대로 나머지를 나눈다', () {
      final e =
          _expense(id: 'e1', amount: 100, payer: 'a', participants: ['b', 'c']);
      final s = sharesOf(e);
      expect(s['b'], 50);
      expect(s['c'], 50);
      expect(s.containsKey('a'), isFalse);
    });

    test('1인 참여면 전액 부담', () {
      final e =
          _expense(id: 'e1', amount: 5000, payer: 'a', participants: ['b']);
      expect(sharesOf(e)['b'], 5000);
    });
  });

  group('legsOf', () {
    test('결제자 본인 몫은 채무가 되지 않는다', () {
      final p = _project(expenses: [
        _expense(
            id: 'e1', amount: 97000, payer: 'a', participants: ['a', 'b', 'c'])
      ]);
      final legs = legsOf(p);

      expect(legs.length, 2);
      expect(legs.every((l) => l.creditorId == 'a'), isTrue);
      expect(legs.map((l) => l.amount).toSet(), {32333});
    });

    test('정산 처리된 건은 settled 로 표시된다', () {
      final p = _project(
        expenses: [
          _expense(
              id: 'e1', amount: 900, payer: 'a', participants: ['a', 'b', 'c'])
        ],
        settled: {DebtLeg.legKey('e1', 'b')},
      );
      final legs = legsOf(p);
      expect(legs.firstWhere((l) => l.debtorId == 'b').settled, isTrue);
      expect(legs.firstWhere((l) => l.debtorId == 'c').settled, isFalse);
    });
  });

  group('pairFlows (쌍별 상계)', () {
    test('단순 1건: 참여자들이 결제자에게 보낸다', () {
      final p = _project(expenses: [
        _expense(
            id: 'e1', amount: 90000, payer: 'a', participants: ['a', 'b', 'c'])
      ]);
      final flows = pairFlows(p);

      expect(flows.length, 2);
      for (final f in flows) {
        expect(f.toId, 'a');
        expect(f.amount, 30000);
      }
    });

    test('양방향 채무는 한 줄로 상계된다', () {
      final p = _project(expenses: [
        // a가 30000 결제, b/c 각 10000씩 a에게
        _expense(
            id: 'e1', amount: 30000, payer: 'a', participants: ['a', 'b', 'c']),
        // b가 6000 결제, a/c 각 2000씩 b에게
        _expense(
            id: 'e2', amount: 6000, payer: 'b', participants: ['a', 'b', 'c']),
      ]);
      final flows = pairFlows(p);
      final ab = flows.firstWhere(
          (f) => {f.fromId, f.toId}.containsAll({'a', 'b'}));

      // b→a 10000, a→b 2000 → b가 a에게 8000
      expect(ab.fromId, 'b');
      expect(ab.toId, 'a');
      expect(ab.amount, 8000);
      expect(ab.rawForward, 10000);
      expect(ab.rawBackward, 2000);
    });

    test('건별 입금 처리된 채무는 제외된다', () {
      final p = _project(
        expenses: [
          _expense(
              id: 'e1',
              amount: 30000,
              payer: 'a',
              participants: ['a', 'b', 'c'])
        ],
        settled: {DebtLeg.legKey('e1', 'b')},
      );
      final flows = pairFlows(p);

      expect(flows.length, 1);
      expect(flows.single.fromId, 'c');
      expect(flows.single.amount, 10000);
    });

    test('직접 송금은 남은 금액에서 차감된다', () {
      final p = _project(
        expenses: [
          _expense(
              id: 'e1',
              amount: 30000,
              payer: 'a',
              participants: ['a', 'b', 'c'])
        ],
        transfers: [
          Transfer(
              id: 't1',
              fromId: 'b',
              toId: 'a',
              amount: 4000,
              memo: '',
              createdAt: _t0),
        ],
      );
      final flows = pairFlows(p);
      final ba =
          flows.firstWhere((f) => f.fromId == 'b' && f.toId == 'a');

      expect(ba.amount, 6000);
      expect(ba.transferred, 4000);
    });

    test('과다 송금은 반대 방향 채무로 뒤집힌다', () {
      final p = _project(
        expenses: [
          _expense(
              id: 'e1',
              amount: 30000,
              payer: 'a',
              participants: ['a', 'b', 'c'])
        ],
        transfers: [
          Transfer(
              id: 't1',
              fromId: 'b',
              toId: 'a',
              amount: 12000,
              memo: '',
              createdAt: _t0),
        ],
      );
      final ab = pairFlows(p)
          .firstWhere((f) => {f.fromId, f.toId}.containsAll({'a', 'b'}));

      expect(ab.fromId, 'a'); // a가 2000원을 b에게 돌려줘야 한다
      expect(ab.toId, 'b');
      expect(ab.amount, 2000);
    });

    test('전원 정산 완료면 화살표가 사라진다', () {
      final p = _project(
        expenses: [
          _expense(
              id: 'e1',
              amount: 30000,
              payer: 'a',
              participants: ['a', 'b', 'c'])
        ],
        settled: {
          DebtLeg.legKey('e1', 'b'),
          DebtLeg.legKey('e1', 'c'),
        },
      );
      expect(pairFlows(p), isEmpty);
      expect(isFullySettled(p), isTrue);
      expect(settledRatio(p), 1.0);
    });
  });

  group('memberSummaries', () {
    test('결제액/부담액/보낼돈/받을돈이 맞아떨어진다', () {
      final p = _project(expenses: [
        _expense(
            id: 'e1', amount: 90000, payer: 'a', participants: ['a', 'b', 'c']),
        _expense(id: 'e2', amount: 30000, payer: 'b', participants: ['b', 'c']),
      ]);
      final byId = {
        for (final s in memberSummaries(p)) s.memberId: s,
      };

      expect(byId['a']!.paid, 90000);
      expect(byId['a']!.share, 30000);
      expect(byId['a']!.net, 60000);

      expect(byId['b']!.paid, 30000);
      expect(byId['b']!.share, 30000 + 15000);
      expect(byId['b']!.net, -15000);

      expect(byId['c']!.paid, 0);
      expect(byId['c']!.share, 45000);
      expect(byId['c']!.net, -45000);

      // 순액 합계는 항상 0.
      expect(
        byId.values.fold(0, (s, m) => s + m.net),
        0,
      );
      // 받을 총액 = 보낼 총액.
      expect(
        byId.values.fold(0, (s, m) => s + m.toSend),
        byId.values.fold(0, (s, m) => s + m.toReceive),
      );
    });

    test('총 지출은 모든 결제액의 합', () {
      final p = _project(expenses: [
        _expense(id: 'e1', amount: 90000, payer: 'a', participants: ['a', 'b']),
        _expense(id: 'e2', amount: 30000, payer: 'b', participants: ['b', 'c']),
      ]);
      expect(totalSpent(p), 120000);
    });
  });

  group('건별 정산과 합계 송금이 하나의 장부로 맞물린다', () {
    // 30,000원을 a가 결제 → b가 15,000 갚을 빚.
    SettlementProject withDebt() => _project(expenses: [
          _expense(
              id: 'e1', amount: 30000, payer: 'a', participants: ['a', 'b'])
        ]);

    test('합계 송금은 덮이는 건을 함께 정산 처리한다', () {
      final p = withDebt();
      final coverage = coverageOf(p, 'b', 'a', 15000);

      expect(coverage.legs.length, 1);
      expect(coverage.applied, 15000);
      expect(coverage.legs.single.debtorId, 'b');
    });

    test('같은 빚을 송금+건별로 둘 다 처리해도 이중 차감되지 않는다', () {
      final p = withDebt();
      final coverage = coverageOf(p, 'b', 'a', 15000);

      // 송금 기록 = 전액이 건에 붙고, 그 건은 정산 처리된다.
      final afterTransfer = p.copyWith(
        transfers: [
          Transfer(
            id: 't1',
            fromId: 'b',
            toId: 'a',
            amount: 15000,
            applied: coverage.applied,
            memo: '',
            createdAt: _t0,
          )
        ],
        settledLegs: coverage.legs.map((l) => l.key).toSet(),
      );
      expect(pairFlows(afterTransfer), isEmpty);

      // 여기서 사용자가 같은 건의 "입금했습니다"를 또 눌러도 그대로 0이어야 한다.
      // (예전엔 a가 b에게 15,000을 돌려줘야 하는 것으로 뒤집혔다.)
      final clickedAgain = afterTransfer.copyWith(
        settledLegs: {...afterTransfer.settledLegs, DebtLeg.legKey('e1', 'b')},
      );
      expect(pairFlows(clickedAgain), isEmpty);
    });

    test('초과 송금분만 선입금으로 남아 방향을 뒤집는다', () {
      final p = withDebt();
      final coverage = coverageOf(p, 'b', 'a', 20000); // 5,000 초과

      expect(coverage.applied, 15000); // 건에 붙는 건 딱 15,000
      final after = p.copyWith(
        transfers: [
          Transfer(
            id: 't1',
            fromId: 'b',
            toId: 'a',
            amount: 20000,
            applied: coverage.applied,
            memo: '',
            createdAt: _t0,
          )
        ],
        settledLegs: coverage.legs.map((l) => l.key).toSet(),
      );

      final flow = pairFlows(after).single;
      expect(flow.fromId, 'a'); // a가 5,000 돌려줘야 한다
      expect(flow.toId, 'b');
      expect(flow.amount, 5000);
    });

    test('건은 쪼개지 않는다 — 모자란 송금은 통째로 선입금', () {
      final p = withDebt();
      final coverage = coverageOf(p, 'b', 'a', 10000); // 15,000짜리 건에 부족

      expect(coverage.legs, isEmpty);
      expect(coverage.applied, 0);

      final after = p.copyWith(transfers: [
        Transfer(
          id: 't1',
          fromId: 'b',
          toId: 'a',
          amount: 10000,
          memo: '',
          createdAt: _t0,
        )
      ]);
      // 빚 15,000 - 선입금 10,000 = 5,000 남는다.
      expect(pairFlows(after).single.amount, 5000);
    });

    test('오래된 건부터 덮는다', () {
      final p = _project(expenses: [
        _expense(
            id: 'old', amount: 20000, payer: 'a', participants: ['a', 'b'],
            dayOffset: 0),
        _expense(
            id: 'new', amount: 40000, payer: 'a', participants: ['a', 'b'],
            dayOffset: 5),
      ]);
      // 각각 b가 10,000 / 20,000 갚을 빚. 10,000 보내면 오래된 것만 덮인다.
      final coverage = coverageOf(p, 'b', 'a', 10000);
      expect(coverage.legs.single.expenseId, 'old');
    });
  });

  group('진행률은 갚은 방식과 무관하게 같은 값을 낸다', () {
    SettlementProject withDebt() => _project(expenses: [
          _expense(
              id: 'e1', amount: 30000, payer: 'a', participants: ['a', 'b'])
        ]);

    test('건별로 갚으면 100%', () {
      final p = withDebt()
          .copyWith(settledLegs: {DebtLeg.legKey('e1', 'b')});
      expect(settledRatio(p), 1.0);
      expect(isFullySettled(p), isTrue);
    });

    test('합계로 갚아도 100% (예전엔 완료 배지와 0% 진행바가 같이 떴다)', () {
      final p = withDebt();
      final coverage = coverageOf(p, 'b', 'a', 15000);
      final after = p.copyWith(
        transfers: [
          Transfer(
            id: 't1',
            fromId: 'b',
            toId: 'a',
            amount: 15000,
            applied: coverage.applied,
            memo: '',
            createdAt: _t0,
          )
        ],
        settledLegs: coverage.legs.map((l) => l.key).toSet(),
      );
      expect(isFullySettled(after), isTrue);
      expect(settledRatio(after), 1.0);
    });

    test('서로 빚이 상쇄돼도 100%', () {
      final p = _project(expenses: [
        _expense(id: 'e1', amount: 20000, payer: 'a', participants: ['a', 'b']),
        _expense(id: 'e2', amount: 20000, payer: 'b', participants: ['a', 'b']),
      ]);
      expect(pairFlows(p), isEmpty);
      expect(settledRatio(p), 1.0);
    });

    test('절반만 갚으면 절반', () {
      final p = _project(expenses: [
        _expense(id: 'e1', amount: 20000, payer: 'a', participants: ['a', 'b']),
        _expense(id: 'e2', amount: 20000, payer: 'a', participants: ['a', 'b']),
      ]);
      final half = p.copyWith(settledLegs: {DebtLeg.legKey('e1', 'b')});
      expect(settledRatio(half), 0.5);
    });
  });

  test('JSON 왕복 직렬화가 상태를 보존한다', () {
    final p = _project(
      expenses: [
        _expense(
            id: 'e1', amount: 97000, payer: 'a', participants: ['a', 'b', 'c'])
      ],
      transfers: [
        Transfer(
            id: 't1',
            fromId: 'b',
            toId: 'a',
            amount: 1000,
            memo: '계좌이체',
            createdAt: _t0),
      ],
      settled: {DebtLeg.legKey('e1', 'c')},
    );

    final round = SettlementProject.fromJson(p.toJson());

    expect(round.name, p.name);
    expect(round.members.length, 3);
    expect(round.expenses.single.amount, 97000);
    expect(round.transfers.single.memo, '계좌이체');
    expect(round.transfers.single.applied, 0);
    expect(round.settledLegs, {DebtLeg.legKey('e1', 'c')});
    expect(pairFlows(round).length, pairFlows(p).length);
  });
}
