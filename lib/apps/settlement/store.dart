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
const _sharedKey = 'pb_settlement_shared_v1';
const _uuid = Uuid();

/// 이 브라우저가 알고 있는 **공유 정산표** 하나에 대한 메모.
/// 실제 데이터는 서버에 있고, 여기에는 다시 찾아갈 단서만 둔다.
class SharedRef {
  final String code;
  final String name;

  /// 이 브라우저에서 만든 정산표라면 삭제 권한 토큰. 남의 링크로 열었으면 null.
  final String? ownerToken;

  /// 비밀 프로젝트의 잠금을 푼 뒤 받은 열쇠. 있으면 다시 암호를 묻지 않는다.
  final String? accessToken;

  final DateTime lastOpenedAt;

  const SharedRef({
    required this.code,
    required this.name,
    required this.lastOpenedAt,
    this.ownerToken,
    this.accessToken,
  });

  bool get isOwner => ownerToken != null;

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        if (ownerToken != null) 'ownerToken': ownerToken,
        if (accessToken != null) 'accessToken': accessToken,
        'lastOpenedAt': lastOpenedAt.toIso8601String(),
      };

  factory SharedRef.fromJson(Map<String, dynamic> j) => SharedRef(
        code: j['code'] as String,
        name: (j['name'] as String?) ?? '정산표',
        ownerToken: j['ownerToken'] as String?,
        accessToken: j['accessToken'] as String?,
        lastOpenedAt: parseTime(
            (j['lastOpenedAt'] as String?) ?? DateTime.now().toIso8601String()),
      );
}

class SettlementStore extends ChangeNotifier {
  List<SettlementProject> _projects = [];
  List<SharedRef> _shared = [];
  bool _ready = false;

  /// 저장된 프로젝트 목록(최신 생성 순).
  List<SettlementProject> get projects => List.unmodifiable(_projects);

  /// 이 브라우저가 아는 공유 정산표들(최근 연 순).
  List<SharedRef> get sharedRefs => List.unmodifiable(_shared);

  SharedRef? sharedRef(String code) {
    for (final s in _shared) {
      if (s.code == code) return s;
    }
    return null;
  }

  String? ownerTokenFor(String code) => sharedRef(code)?.ownerToken;

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
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _projects = decoded
              .whereType<Map<String, dynamic>>()
              .map(SettlementProject.fromJson)
              .toList();
        }
      }

      final rawShared = prefs.getString(_sharedKey);
      if (rawShared != null && rawShared.isNotEmpty) {
        final decoded = jsonDecode(rawShared);
        if (decoded is List) {
          _shared = decoded
              .whereType<Map<String, dynamic>>()
              .map(SharedRef.fromJson)
              .toList();
        }
      }
    } catch (_) {
      // 저장 형식이 깨졌어도 앱은 살아 있어야 한다. 빈 목록으로 시작.
      _projects = [];
      _shared = [];
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(_projects.map((p) => p.toJson()).toList()),
      );
      await prefs.setString(
        _sharedKey,
        jsonEncode(_shared.map((s) => s.toJson()).toList()),
      );
    } catch (_) {
      // 저장 실패해도 메모리 상태는 유지된다.
    }
  }

  // ─────────────────────── 공유 정산표 메모 ───────────────────────

  /// 공유 정산표를 열거나 갱신할 때마다 호출 — 이름/최근 열람을 최신으로 유지한다.
  /// [ownerToken]·[accessToken] 은 새로 받았을 때만 주면 되고,
  /// 안 주면 이미 보관 중인 값을 그대로 지킨다.
  void rememberShared(
    SettlementProject project, {
    String? ownerToken,
    String? accessToken,
  }) {
    final code = project.code;
    if (code == null) return;

    final existing = sharedRef(code);
    final ref = SharedRef(
      code: code,
      name: project.name,
      ownerToken: ownerToken ?? existing?.ownerToken,
      accessToken: accessToken ?? existing?.accessToken,
      lastOpenedAt: DateTime.now(),
    );
    _shared = [ref, ..._shared.where((s) => s.code != code)];
    notifyListeners();
    _persist();
  }

  /// 접근 토큰만 버린다(암호가 바뀌어 열쇠가 무효가 된 경우).
  void clearAccessToken(String code) {
    final existing = sharedRef(code);
    if (existing == null || existing.accessToken == null) return;
    _shared = [
      for (final s in _shared)
        if (s.code == code)
          SharedRef(
            code: s.code,
            name: s.name,
            ownerToken: s.ownerToken,
            lastOpenedAt: s.lastOpenedAt,
          )
        else
          s
    ];
    notifyListeners();
    _persist();
  }

  /// 목록에서만 지운다(서버 데이터는 그대로).
  void forgetShared(String code) {
    _shared = _shared.where((s) => s.code != code).toList();
    notifyListeners();
    _persist();
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
