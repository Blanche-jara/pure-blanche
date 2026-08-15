/// SMTM 모바일 레이아웃 회귀 테스트.
///
/// 여행·결제 특성상 대부분 모바일로 쓰기 때문에 **좁은 화면에서 오버플로가 없어야** 한다.
/// 좁은 폭 4종(320~430)에 실제로 그려보고, 렌더 중 예외(RenderFlex overflow 포함)가
/// 하나라도 나면 실패한다.
///
/// 화면을 가로로 넘치게 만드는 최악 조건을 일부러 넣는다:
/// 긴 이름, 8자리 금액, 참여자 다수, 긴 항목명.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_blanche/apps/settlement/controller.dart';
import 'package:pure_blanche/apps/settlement/models.dart';
import 'package:pure_blanche/apps/settlement/tab_expenses.dart';
import 'package:pure_blanche/apps/settlement/tab_members.dart';
import 'package:pure_blanche/apps/settlement/tab_overview.dart';
import 'package:pure_blanche/theme/app_theme.dart';

/// 아무것도 하지 않는 컨트롤러. 레이아웃만 보는 테스트라 동작은 필요 없다.
class _StubController extends SettlementController {
  @override
  final SettlementProject? project;

  _StubController(this.project);

  @override
  Future<void> rename(String name) async {}
  @override
  Future<void> addExpense({
    required String title,
    required int amount,
    required String payerId,
    required List<String> participantIds,
  }) async {}
  @override
  Future<void> updateExpense(
    String expenseId, {
    required String title,
    required int amount,
    required String payerId,
    required List<String> participantIds,
  }) async {}
  @override
  Future<void> removeExpense(String expenseId) async {}
  @override
  Future<int> addTransfer({
    required String fromId,
    required String toId,
    required int amount,
    String memo = '',
  }) async =>
      0;
  @override
  Future<void> removeTransfer(String transferId) async {}
  @override
  Future<void> setLegSettled(
      String expenseId, String debtorId, bool settled) async {}
  @override
  Future<void> settleLegs(Iterable<DebtLeg> legs) async {}
}

final _t0 = DateTime(2026, 8, 13);

/// 최악 조건 프로젝트: 이름 길고, 금액 크고, 인원 많다.
SettlementProject _project() {
  const members = [
    Member(id: 'a', name: '김블랑쉬'),
    Member(id: 'b', name: '박민수현'),
    Member(id: 'c', name: '최지연우'),
    Member(id: 'd', name: '정현우진'),
    Member(id: 'e', name: '한소영미'),
  ];
  final ids = members.map((m) => m.id).toList();

  return SettlementProject(
    id: 'p',
    code: 'k3m8qr2t',
    name: '2026 여름 강릉 우정여행 정산',
    createdAt: _t0,
    members: members,
    expenses: [
      Expense(
        id: 'e1',
        title: '1차 삼겹살에 소주까지',
        amount: 12345678,
        payerId: 'a',
        participantIds: ids,
        createdAt: _t0,
      ),
      Expense(
        id: 'e2',
        title: '숙소',
        amount: 970000,
        payerId: 'b',
        participantIds: const ['b', 'c', 'd'],
        createdAt: _t0.add(const Duration(days: 1)),
      ),
      Expense(
        id: 'e3',
        title: '택시',
        amount: 23000,
        payerId: 'c',
        participantIds: const ['a', 'c'],
        createdAt: _t0.add(const Duration(days: 2)),
      ),
    ],
    transfers: [
      Transfer(
        id: 't1',
        fromId: 'd',
        toId: 'a',
        amount: 1500000,
        memo: '우선 일부만 보냅니다',
        createdAt: _t0,
      ),
    ],
    settledLegs: {DebtLeg.legKey('e1', 'b')},
  );
}

/// [child] 를 [width] 폭 화면에 그리고, 렌더 중 예외가 없었는지 확인한다.
Future<void> _renderAt(
  WidgetTester tester,
  double width,
  Widget child,
) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  // 320: 구형 소형 / 360: 갤럭시 / 390: iPhone 14 / 430: iPhone Pro Max
  const widths = [320.0, 360.0, 390.0, 430.0];

  for (final w in widths) {
    testWidgets('지출 기록 탭 — ${w.toInt()}px 오버플로 없음', (tester) async {
      final p = _project();
      await _renderAt(
        tester,
        w,
        ExpensesTab(controller: _StubController(p), project: p),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('통합 정산 탭 — ${w.toInt()}px 오버플로 없음', (tester) async {
      final p = _project();
      await _renderAt(
        tester,
        w,
        OverviewTab(
          controller: _StubController(p),
          project: p,
          onOpenMember: (_) {},
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('인원별 탭 — ${w.toInt()}px 오버플로 없음', (tester) async {
      final p = _project();
      await _renderAt(
        tester,
        w,
        MembersTab(
          controller: _StubController(p),
          project: p,
          selectedId: 'a',
          onSelect: (_) {},
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('인원별 탭 — 모든 인원을 돌아가며 그려도 오버플로 없음', (tester) async {
    final p = _project();
    for (final m in p.members) {
      await _renderAt(
        tester,
        360,
        MembersTab(
          controller: _StubController(p),
          project: p,
          selectedId: m.id,
          onSelect: (_) {},
        ),
      );
      expect(tester.takeException(), isNull, reason: '인원 ${m.name} 화면');
    }
  });
}
