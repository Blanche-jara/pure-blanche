/// 정산표 — 프로젝트 하나를 편집하는 창구.
///
/// UI(탭·다이얼로그)는 이 인터페이스만 알고, 데이터가 **이 브라우저에만**
/// 있는지(로컬) **서버에 공유돼 있는지**(원격) 신경 쓰지 않는다.
///
/// - [LocalSettlementController] — localStorage. 즉시 반영, 실패하지 않음.
/// - [RemoteSettlementController] — 공유 코드 기반 서버 원장(docs/SETTLEMENT_BACKEND.md).
///   각 변경이 API 왕복이며, 응답의 프로젝트 전체로 상태를 교체한다.
library;

import 'package:flutter/foundation.dart';

import '../../services/settlement_service.dart';
import 'models.dart';
import 'store.dart';

abstract class SettlementController extends ChangeNotifier {
  /// 현재 프로젝트. 삭제됐으면 null.
  SettlementProject? get project;

  /// 서버 요청이 진행 중인지(로컬은 항상 false).
  bool get busy => false;

  /// 마지막 실패 메시지. UI가 배너로 보여주고 [clearError] 로 지운다.
  String? get error => null;

  void clearError() {}

  /// 서버 공유 프로젝트인지.
  bool get isShared => project?.isShared ?? false;

  /// 서버에서 최신 상태를 다시 받아온다(로컬은 no-op).
  Future<void> refresh() async {}

  Future<void> rename(String name);

  Future<void> addExpense({
    required String title,
    required int amount,
    required String payerId,
    required List<String> participantIds,
  });

  Future<void> updateExpense(
    String expenseId, {
    required String title,
    required int amount,
    required String payerId,
    required List<String> participantIds,
  });

  Future<void> removeExpense(String expenseId);

  Future<void> addTransfer({
    required String fromId,
    required String toId,
    required int amount,
    String memo,
  });

  Future<void> removeTransfer(String transferId);

  Future<void> setLegSettled(String expenseId, String debtorId, bool settled);

  Future<void> settleLegs(Iterable<DebtLeg> legs);
}

// ─────────────────────────── 로컬 ───────────────────────────

class LocalSettlementController extends SettlementController {
  final SettlementStore store;
  final String projectId;

  LocalSettlementController({required this.store, required this.projectId}) {
    store.addListener(notifyListeners);
  }

  @override
  void dispose() {
    store.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  SettlementProject? get project => store.byId(projectId);

  @override
  Future<void> rename(String name) async =>
      store.renameProject(projectId, name);

  @override
  Future<void> addExpense({
    required String title,
    required int amount,
    required String payerId,
    required List<String> participantIds,
  }) async =>
      store.addExpense(
        projectId,
        title: title,
        amount: amount,
        payerId: payerId,
        participantIds: participantIds,
      );

  @override
  Future<void> updateExpense(
    String expenseId, {
    required String title,
    required int amount,
    required String payerId,
    required List<String> participantIds,
  }) async =>
      store.updateExpense(
        projectId,
        expenseId,
        title: title,
        amount: amount,
        payerId: payerId,
        participantIds: participantIds,
      );

  @override
  Future<void> removeExpense(String expenseId) async =>
      store.removeExpense(projectId, expenseId);

  @override
  Future<void> addTransfer({
    required String fromId,
    required String toId,
    required int amount,
    String memo = '',
  }) async =>
      store.addTransfer(
        projectId,
        fromId: fromId,
        toId: toId,
        amount: amount,
        memo: memo,
      );

  @override
  Future<void> removeTransfer(String transferId) async =>
      store.removeTransfer(projectId, transferId);

  @override
  Future<void> setLegSettled(
          String expenseId, String debtorId, bool settled) async =>
      store.setLegSettled(projectId, expenseId, debtorId, settled);

  @override
  Future<void> settleLegs(Iterable<DebtLeg> legs) async =>
      store.settleLegs(projectId, legs);
}

// ─────────────────────────── 원격(공유) ───────────────────────────

class RemoteSettlementController extends SettlementController {
  final SettlementService service;
  final String code;

  /// 비밀 프로젝트의 열쇠. 공개 프로젝트면 null.
  final String? accessToken;

  /// 공유 목록의 이름/최근 열람을 갱신하기 위한 로컬 스토어(선택).
  final SettlementStore? store;

  SettlementProject? _project;
  bool _busy = false;
  String? _error;

  RemoteSettlementController({
    required this.service,
    required this.code,
    required SettlementProject initial,
    this.accessToken,
    this.store,
  }) : _project = initial;

  @override
  SettlementProject? get project => _project;

  @override
  bool get busy => _busy;

  @override
  String? get error => _error;

  @override
  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  /// 모든 변경의 공통 껍데기. 실패해도 이전 상태를 유지하고 메시지만 남긴다.
  Future<void> _run(Future<SettlementProject> Function() call) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final next = await call();
      _project = next;
      store?.rememberShared(next);
    } on SettlementException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = '요청을 처리하지 못했습니다.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  Future<void> refresh() =>
      _run(() => service.fetch(code, token: accessToken));

  @override
  Future<void> rename(String name) =>
      _run(() => service.rename(code, name, token: accessToken));

  @override
  Future<void> addExpense({
    required String title,
    required int amount,
    required String payerId,
    required List<String> participantIds,
  }) =>
      _run(() => service.addExpense(
            code,
            title: title,
            amount: amount,
            payerId: payerId,
            participantIds: participantIds,
            token: accessToken,
          ));

  @override
  Future<void> updateExpense(
    String expenseId, {
    required String title,
    required int amount,
    required String payerId,
    required List<String> participantIds,
  }) =>
      _run(() => service.updateExpense(
            code,
            expenseId,
            title: title,
            amount: amount,
            payerId: payerId,
            participantIds: participantIds,
            token: accessToken,
          ));

  @override
  Future<void> removeExpense(String expenseId) =>
      _run(() => service.removeExpense(code, expenseId, token: accessToken));

  @override
  Future<void> addTransfer({
    required String fromId,
    required String toId,
    required int amount,
    String memo = '',
  }) =>
      _run(() => service.addTransfer(
            code,
            fromId: fromId,
            toId: toId,
            amount: amount,
            memo: memo,
            token: accessToken,
          ));

  @override
  Future<void> removeTransfer(String transferId) =>
      _run(() => service.removeTransfer(code, transferId, token: accessToken));

  @override
  Future<void> setLegSettled(
          String expenseId, String debtorId, bool settled) =>
      _run(() => service.setLegs(
            code,
            legs: [(expenseId: expenseId, debtorId: debtorId)],
            settled: settled,
            token: accessToken,
          ));

  @override
  Future<void> settleLegs(Iterable<DebtLeg> legs) {
    final list = [
      for (final l in legs) (expenseId: l.expenseId, debtorId: l.debtorId)
    ];
    if (list.isEmpty) return Future.value();
    return _run(() =>
        service.setLegs(code, legs: list, settled: true, token: accessToken));
  }

  /// 인원 추가/이름변경/삭제 — 공유 프로젝트에서만 쓰는 부가 기능.
  Future<void> addMember(String name) =>
      _run(() => service.addMember(code, name, token: accessToken));

  Future<void> renameMember(String memberId, String name) => _run(
      () => service.renameMember(code, memberId, name, token: accessToken));

  Future<void> removeMember(String memberId) =>
      _run(() => service.removeMember(code, memberId, token: accessToken));
}
