/// 정산표 서비스 ↔ Worker 통합 테스트.
///
/// 로컬 Worker가 떠 있을 때만 돌아간다:
/// ```
/// cd backend && npx wrangler d1 execute pure-blanche-guestbook --local --file=./schema.sql
/// npx wrangler dev            # http://localhost:8787
/// flutter test test/settlement_service_integration_test.dart --dart-define=GUESTBOOK_API=http://localhost:8787
/// ```
/// 서버가 없으면 전체를 skip 한다(CI에서 빨갛게 만들지 않는다).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pure_blanche/apps/settlement/engine.dart';
import 'package:pure_blanche/services/settlement_service.dart';

Future<bool> _serverUp() async {
  try {
    final uri = Uri.parse('${SettlementService.baseUrl}/health');
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 2);
    final res = await (await client.getUrl(uri)).close();
    client.close();
    return res.statusCode == 200;
  } catch (_) {
    return false;
  }
}

void main() {
  late bool up;

  setUpAll(() async {
    up = await _serverUp();
    if (!up) {
      // ignore: avoid_print
      print('⏭  ${SettlementService.baseUrl} 응답 없음 — 통합 테스트 skip');
    }
  });

  test('생성 → 지출 → 입금 처리 → 상계 결과가 서버 왕복 후에도 동일하다', () async {
    if (!up) return;

    final service = SettlementService();

    final created = await service.create(
      name: '통합 테스트 정산',
      memberNames: ['블랑쉬', '민수', '지연'],
    );
    final code = created.project.code!;
    expect(created.ownerToken, isNotNull);
    expect(code.length, 8);
    expect(created.project.members.map((m) => m.name).toList(),
        ['블랑쉬', '민수', '지연']);

    final a = created.project.members[0].id;
    final b = created.project.members[1].id;
    final c = created.project.members[2].id;

    // 97,000원을 블랑쉬가 결제 → 민수/지연이 각 32,333원씩 갚아야 한다.
    var project = await service.addExpense(
      code,
      title: '1차 삼겹살',
      amount: 97000,
      payerId: a,
      participantIds: [a, b, c],
    );
    expect(project.expenses.length, 1);

    var flows = pairFlows(project);
    expect(flows.length, 2);
    expect(flows.every((f) => f.toId == a && f.amount == 32333), isTrue);

    // 결제자가 1원 나머지를 흡수했는지(서버 왕복 후에도 동일).
    expect(sharesOf(project.expenses.single)[a], 32334);

    // 민수가 "입금했습니다" → 화살표 1개만 남는다.
    final expenseId = project.expenses.single.id;
    project = await service.setLegs(
      code,
      legs: [(expenseId: expenseId, debtorId: b)],
      settled: true,
    );
    expect(project.settledLegs, {'$expenseId::$b'});

    flows = pairFlows(project);
    expect(flows.length, 1);
    expect(flows.single.fromId, c);

    // 지연이 5,000원만 부분 송금 → 남은 금액에서 차감.
    project = await service.addTransfer(
      code,
      fromId: c,
      toId: a,
      amount: 5000,
      memo: '계좌이체',
    );
    flows = pairFlows(project);
    expect(flows.single.amount, 32333 - 5000);

    // 나머지도 입금 처리 → 정산 완료.
    project = await service.setLegs(
      code,
      legs: [(expenseId: expenseId, debtorId: c)],
      settled: true,
    );
    // 5,000원을 더 보냈으니 이제 블랑쉬가 지연에게 돌려줘야 한다.
    flows = pairFlows(project);
    expect(flows.single.fromId, a);
    expect(flows.single.toId, c);
    expect(flows.single.amount, 5000);

    // 다시 조회해도 같은 상태.
    final refetched = await service.fetch(code);
    expect(refetched.settledLegs, project.settledLegs);
    expect(refetched.transfers.length, 1);
    expect(refetched.expenses.single.amount, 97000);
    expect(totalSpent(refetched), 97000);

    // 시각은 UTC로 오지만 로컬로 변환돼 미래가 아니어야 한다.
    expect(
      refetched.createdAt.isAfter(DateTime.now().add(const Duration(hours: 1))),
      isFalse,
    );

    // 권한: 토큰 없이 삭제 불가.
    await expectLater(
      service.deleteProject(code),
      throwsA(isA<SettlementException>()),
    );

    // 소유자 토큰으로는 삭제되고, 이후 조회는 실패한다.
    await service.deleteProject(code, ownerToken: created.ownerToken);
    await expectLater(
      service.fetch(code),
      throwsA(isA<SettlementException>()),
    );
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('비밀 프로젝트는 암호를 넣어야 열리고, 열쇠는 편집에도 쓰인다', () async {
    if (!up) return;

    final service = SettlementService();

    // 생성 rate limit(10초)을 피하려고 앞 테스트와 간격을 둔다.
    await Future<void>.delayed(const Duration(seconds: 11));

    final created = await service.create(
      name: '비밀 여행 정산',
      memberNames: ['블랑쉬', '민수'],
      password: 'tr1p2026',
    );
    final code = created.project.code!;
    expect(created.project.locked, isTrue);
    expect(created.accessToken, isNotNull);

    // 열쇠 없이는 조회조차 막힌다 — 그리고 그 사실을 코드로 구분할 수 있어야 한다.
    try {
      await service.fetch(code);
      fail('암호 없이 열려서는 안 된다');
    } on SettlementException catch (e) {
      expect(e.needsPassword, isTrue);
      expect(e.projectName, '비밀 여행 정산'); // 암호 화면에 띄울 이름
    }

    // 틀린 암호.
    await expectLater(
      service.unlock(code, 'wrong-password'),
      throwsA(
        isA<SettlementException>().having((e) => e.code, 'code', 'bad_password'),
      ),
    );

    // 맞는 암호 → 생성 때 받은 것과 같은 열쇠.
    final unlocked = await service.unlock(code, 'tr1p2026');
    expect(unlocked.accessToken, created.accessToken);
    expect(unlocked.project.name, '비밀 여행 정산');

    // 열쇠로 조회·편집 모두 된다.
    final token = unlocked.accessToken;
    final fetched = await service.fetch(code, token: token);
    expect(fetched.members.length, 2);

    final withExpense = await service.addExpense(
      code,
      title: '숙소',
      amount: 100000,
      payerId: fetched.members[0].id,
      participantIds: fetched.members.map((m) => m.id).toList(),
      token: token,
    );
    expect(withExpense.expenses.single.amount, 100000);

    // 열쇠 없는 편집은 막힌다.
    await expectLater(
      service.addExpense(
        code,
        title: '몰래',
        amount: 5000,
        payerId: fetched.members[0].id,
        participantIds: [fetched.members[0].id],
      ),
      throwsA(isA<SettlementException>()
          .having((e) => e.needsPassword, 'needsPassword', isTrue)),
    );

    await service.deleteProject(code, ownerToken: created.ownerToken);
  }, timeout: const Timeout(Duration(seconds: 90)));
}
