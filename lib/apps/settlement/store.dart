/// 정산표 — 상태 + 영속화.
///
/// 현재 저장소는 브라우저 localStorage(`shared_preferences`)이며,
/// 프로젝트 전체가 JSON 한 덩어리로 들어간다.
/// 백엔드(D1) 연동 시 [_load]/[_persist] 두 곳만 교체하면 되도록 격리해 두었다.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';

const _storageKey = 'pb_settlement_v1';
const _uuid = Uuid();

class SettlementStore extends ChangeNotifier {
  List<SettlementProject> _projects = [];
  bool _ready = false;

  /// 저장된 프로젝트 목록(최신 생성 순).
  List<SettlementProject> get projects => List.unmodifiable(_projects);

  /// localStorage 로드가 끝났는지. false면 로딩 스피너.
  bool get ready => _ready;

  SettlementProject? byId(String id) {
    for (final p in _projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ─────────────────────────── 영속화 ───────────────────────────

  Future<void> init() async {
    if (_ready) return;
    await _load();
    _ready = true;
    notifyListeners();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      _projects = decoded
          .whereType<Map<String, dynamic>>()
          .map(SettlementProject.fromJson)
          .toList();
    } catch (_) {
      // 저장 형식이 깨졌어도 앱은 살아 있어야 한다. 빈 목록으로 시작.
      _projects = [];
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(_projects.map((p) => p.toJson()).toList()),
      );
    } catch (_) {
      // 저장 실패해도 메모리 상태는 유지된다.
    }
  }

  void _update(SettlementProject next) {
    final i = _projects.indexWhere((p) => p.id == next.id);
    if (i < 0) return;
    _projects[i] = next;
    notifyListeners();
    _persist();
  }

  // ─────────────────────────── 프로젝트 ───────────────────────────

  /// 새 프로젝트 생성. [names] 는 인원 이름 목록(중복 이름 허용).
  SettlementProject createProject(String name, List<String> names) {
    final project = SettlementProject.create(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
      members: [
        for (final n in names) Member(id: _uuid.v4(), name: n),
      ],
    );
    _projects = [project, ..._projects];
    notifyListeners();
    _persist();
    return project;
  }

  void renameProject(String projectId, String name) {
    final p = byId(projectId);
    if (p == null) return;
    _update(p.copyWith(name: name));
  }

  void deleteProject(String projectId) {
    _projects = _projects.where((p) => p.id != projectId).toList();
    notifyListeners();
    _persist();
  }

  // ─────────────────────────── 인원 ───────────────────────────

  void addMember(String projectId, String name) {
    final p = byId(projectId);
    if (p == null) return;
    _update(p.copyWith(
      members: [...p.members, Member(id: _uuid.v4(), name: name)],
    ));
  }

  void renameMember(String projectId, String memberId, String name) {
    final p = byId(projectId);
    if (p == null) return;
    _update(p.copyWith(
      members: [
        for (final m in p.members) m.id == memberId ? m.copyWith(name: name) : m
      ],
    ));
  }

  /// 인원 삭제. 지출/송금에 얽혀 있으면 삭제하지 않고 false 반환.
  bool removeMember(String projectId, String memberId) {
    final p = byId(projectId);
    if (p == null) return false;
    final used = p.expenses.any((e) =>
            e.payerId == memberId || e.participantIds.contains(memberId)) ||
        p.transfers.any((t) => t.fromId == memberId || t.toId == memberId);
    if (used) return false;
    _update(p.copyWith(
      members: p.members.where((m) => m.id != memberId).toList(),
    ));
    return true;
  }

  // ─────────────────────────── 지출 ───────────────────────────

  void addExpense(
    String projectId, {
    required String title,
    required int amount,
    required String payerId,
    required List<String> participantIds,
  }) {
    final p = byId(projectId);
    if (p == null) return;
    _update(p.copyWith(
      expenses: [
        ...p.expenses,
        Expense(
          id: _uuid.v4(),
          title: title,
          amount: amount,
          payerId: payerId,
          participantIds: participantIds,
          createdAt: DateTime.now(),
        ),
      ],
    ));
  }

  void updateExpense(
    String projectId,
    String expenseId, {
    required String title,
    required int amount,
    required String payerId,
    required List<String> participantIds,
  }) {
    final p = byId(projectId);
    if (p == null) return;

    // 참여자/금액이 바뀌면 기존 "입금했습니다" 처리가 근거를 잃는다.
    // 더 이상 존재하지 않는 채무 건의 정산 표시는 정리한다.
    final kept = participantIds.toSet()..remove(payerId);
    final settled = p.settledLegs
        .where((k) =>
            !k.startsWith('$expenseId::') ||
            kept.contains(k.substring(expenseId.length + 2)))
        .toSet();

    _update(p.copyWith(
      expenses: [
        for (final e in p.expenses)
          if (e.id == expenseId)
            e.copyWith(
              title: title,
              amount: amount,
              payerId: payerId,
              participantIds: participantIds,
            )
          else
            e
      ],
      settledLegs: settled,
    ));
  }

  void removeExpense(String projectId, String expenseId) {
    final p = byId(projectId);
    if (p == null) return;
    _update(p.copyWith(
      expenses: p.expenses.where((e) => e.id != expenseId).toList(),
      settledLegs:
          p.settledLegs.where((k) => !k.startsWith('$expenseId::')).toSet(),
    ));
  }

  // ─────────────────────── 정산 처리(입금 체크) ───────────────────────

  /// 채무 건 하나를 "입금 완료"로 표시하거나 되돌린다.
  void setLegSettled(
    String projectId,
    String expenseId,
    String debtorId,
    bool settled,
  ) {
    final p = byId(projectId);
    if (p == null) return;
    final key = DebtLeg.legKey(expenseId, debtorId);
    final next = Set<String>.from(p.settledLegs);
    if (settled) {
      next.add(key);
    } else {
      next.remove(key);
    }
    _update(p.copyWith(settledLegs: next));
  }

  /// 여러 건을 한 번에 정산 처리(개인 페이지의 "전부 입금 완료").
  void settleLegs(String projectId, Iterable<DebtLeg> legs) {
    final p = byId(projectId);
    if (p == null) return;
    _update(p.copyWith(
      settledLegs: {...p.settledLegs, ...legs.map((l) => l.key)},
    ));
  }

  // ─────────────────────────── 직접 송금 ───────────────────────────

  void addTransfer(
    String projectId, {
    required String fromId,
    required String toId,
    required int amount,
    String memo = '',
  }) {
    final p = byId(projectId);
    if (p == null) return;
    _update(p.copyWith(
      transfers: [
        ...p.transfers,
        Transfer(
          id: _uuid.v4(),
          fromId: fromId,
          toId: toId,
          amount: amount,
          memo: memo,
          createdAt: DateTime.now(),
        ),
      ],
    ));
  }

  void removeTransfer(String projectId, String transferId) {
    final p = byId(projectId);
    if (p == null) return;
    _update(p.copyWith(
      transfers: p.transfers.where((t) => t.id != transferId).toList(),
    ));
  }
}
