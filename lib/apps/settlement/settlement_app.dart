/// 정산표 — 엔트리 + 프로젝트 목록/생성/공유.
///
/// 정산표는 두 가지 모습으로 존재한다.
/// - **로컬**: 이 브라우저에만 저장(localStorage). 혼자 계산할 때.
/// - **공유**: 서버(D1)에 저장되고 `#/settlement/<code>` 링크로 함께 편집.
library;

import 'package:flutter/material.dart';

import '../../services/settlement_service.dart';
import '../../theme/app_colors.dart';
import 'controller.dart';
import 'engine.dart';
import 'models.dart';
import 'project_view.dart';
import 'share.dart';
import 'store.dart';
import 'ui_kit.dart';

class SettlementApp extends StatefulWidget {
  /// 공유 링크(`#/settlement/<code>`)로 들어온 경우의 코드.
  final String? code;

  const SettlementApp({super.key, this.code});

  @override
  State<SettlementApp> createState() => _SettlementAppState();
}

class _SettlementAppState extends State<SettlementApp> {
  final _store = SettlementStore();
  final _service = SettlementService();

  SettlementController? _controller;

  /// 공유 정산표를 여는 중인지 / 열다 실패했는지.
  bool _opening = false;
  String? _openError;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await _store.init();
    if (!mounted) return;
    final code = widget.code;
    if (code != null) {
      await _openShared(code);
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _store.dispose();
    super.dispose();
  }

  void _setController(SettlementController? next) {
    _controller?.dispose();
    _controller = next;
    if (mounted) setState(() {});
  }

  void _openLocal(String projectId) {
    _setController(
      LocalSettlementController(store: _store, projectId: projectId),
    );
  }

  /// 공유 코드로 서버에서 불러와 연다.
  Future<void> _openShared(String code) async {
    setState(() {
      _opening = true;
      _openError = null;
    });
    try {
      final project = await _service.fetch(code);
      _store.rememberShared(project);
      if (!mounted) return;
      _opening = false;
      _setController(RemoteSettlementController(
        service: _service,
        code: code,
        initial: project,
        store: _store,
      ));
    } on SettlementException catch (e) {
      if (!mounted) return;
      setState(() {
        _opening = false;
        _openError = e.message;
      });
    }
  }

  void _close() {
    _setController(null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.abyss,
      child: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          if (!_store.ready || _opening) {
            return const _Spinner();
          }
          if (_openError != null && _controller == null) {
            return _OpenError(
              message: _openError!,
              onRetry: widget.code == null ? null : () => _openShared(widget.code!),
              onBack: () => setState(() => _openError = null),
            );
          }
          final controller = _controller;
          if (controller != null) {
            return ProjectView(controller: controller, onClose: _close);
          }
          return _ProjectListView(
            store: _store,
            service: _service,
            onOpenLocal: _openLocal,
            onOpenShared: _openShared,
          );
        },
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.signalGreen,
          ),
        ),
      );
}

class _OpenError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback onBack;

  const _OpenError({
    required this.message,
    required this.onBack,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmptyHint(
                icon: Icons.link_off,
                title: message,
                subtitle: '링크가 정확한지, 정산표가 삭제되지 않았는지 확인해보자.',
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onRetry != null) ...[
                    GhostButton(
                        label: '다시 시도', icon: Icons.refresh, onTap: onRetry),
                    const SizedBox(width: 8),
                  ],
                  GhostButton(label: '목록으로', onTap: onBack),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── 프로젝트 목록 ─────────────────────────────

class _ProjectListView extends StatelessWidget {
  final SettlementStore store;
  final SettlementService service;
  final ValueChanged<String> onOpenLocal;
  final ValueChanged<String> onOpenShared;

  const _ProjectListView({
    required this.store,
    required this.service,
    required this.onOpenLocal,
    required this.onOpenShared,
  });

  Future<void> _create(BuildContext context) async {
    final result = await showSettlementDialog<_CreateResult>(
      context: context,
      title: '새 정산 프로젝트',
      maxWidth: 520,
      builder: (ctx) => _CreateProjectForm(store: store, service: service),
    );
    if (result == null) return;
    if (result.code != null) {
      onOpenShared(result.code!);
    } else if (result.localId != null) {
      onOpenLocal(result.localId!);
    }
  }

  Future<void> _openByCode(BuildContext context) async {
    final code = await showSettlementDialog<String>(
      context: context,
      title: '공유 링크로 열기',
      maxWidth: 440,
      builder: (ctx) => const _OpenByCodeForm(),
    );
    if (code != null) onOpenShared(code);
  }

  @override
  Widget build(BuildContext context) {
    final projects = store.projects;
    final shared = store.sharedRefs;
    final wide = MediaQuery.of(context).size.width >= 768;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 18, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'SETTLEMENT',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.52,
                  color: AppColors.signalGreen,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '정산표',
                style: TextStyle(
                  fontFamily: 'Segoe UI',
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                  color: AppColors.snow,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '누가 결제했는지만 적으면, 누가 누구에게 얼마를 보내야 하는지 정리해준다.',
                style: TextStyle(
                    fontSize: 14, color: AppColors.parchment, height: 1.6),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  PrimaryButton(
                    label: '새 프로젝트',
                    icon: Icons.add,
                    onTap: () => _create(context),
                  ),
                  const SizedBox(width: 10),
                  GhostButton(
                    label: '공유 링크로 열기',
                    icon: Icons.link,
                    onTap: () => _openByCode(context),
                  ),
                ],
              ),

              // ── 공유 정산표 ──
              if (shared.isNotEmpty) ...[
                const SizedBox(height: 30),
                SectionTitle('공유 정산표', trailingText: '${shared.length}개'),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final ref in shared)
                      SizedBox(
                        width: wide ? 320 : double.infinity,
                        child: _SharedCard(
                          sharedRef: ref,
                          onOpen: () => onOpenShared(ref.code),
                          onForget: () async {
                            final ok = await confirmDialog(
                              context: context,
                              title: '목록에서 제거',
                              message:
                                  '"${ref.name}" 을(를) 이 목록에서만 지운다. 서버의 정산표는 그대로 남고, '
                                  '링크가 있으면 다시 열 수 있다.',
                              confirmLabel: '제거',
                            );
                            if (ok) store.forgetShared(ref.code);
                          },
                        ),
                      ),
                  ],
                ),
              ],

              // ── 로컬 정산표 ──
              const SizedBox(height: 30),
              SectionTitle(
                '이 브라우저 정산표',
                trailingText: projects.isEmpty ? null : '${projects.length}개',
              ),
              if (projects.isEmpty && shared.isEmpty)
                const EmptyHint(
                  icon: Icons.receipt_long_outlined,
                  title: '아직 정산 프로젝트가 없다.',
                  subtitle: '모임 하나당 프로젝트 하나. 인원 이름을 먼저 등록하고 지출을 쌓아나가면 된다.',
                )
              else if (projects.isEmpty)
                const EmptyHint(
                  icon: Icons.devices,
                  title: '이 브라우저에만 저장된 정산표는 없다.',
                )
              else
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final p in projects)
                      SizedBox(
                        width: wide ? 320 : double.infinity,
                        child: _ProjectCard(
                          project: p,
                          onOpen: () => onOpenLocal(p.id),
                          onPublish: () => _publish(context, p),
                          onDelete: () async {
                            final ok = await confirmDialog(
                              context: context,
                              title: '프로젝트 삭제',
                              message:
                                  '"${p.name}" 을(를) 삭제한다. 지출 ${p.expenses.length}건과 정산 기록이 모두 사라지며 되돌릴 수 없다.',
                            );
                            if (ok) store.deleteProject(p.id);
                          },
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 40),
              Text(
                '공유 정산표는 서버에 저장되고 링크를 아는 사람이 함께 편집한다. '
                '그 외 정산표는 이 브라우저에만 남는다.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: AppColors.steel.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 로컬 정산표를 서버로 올려 공유 가능하게 만든다(원본은 그대로 남긴다).
  Future<void> _publish(BuildContext context, SettlementProject local) async {
    final ok = await confirmDialog(
      context: context,
      title: '공유로 전환',
      message: '"${local.name}" 의 인원·지출·정산 내역을 서버에 올려 공유 링크를 만든다. '
          '이 브라우저의 원본은 그대로 남는다.',
      confirmLabel: '올리기',
    );
    if (!ok || !context.mounted) return;

    showToast(context, '서버에 올리는 중…');
    try {
      final published = await publishToServer(service, local);
      store.rememberShared(published.project, ownerToken: published.ownerToken);
      if (!context.mounted) return;
      onOpenShared(published.project.code!);
    } on SettlementException catch (e) {
      if (!context.mounted) return;
      showToast(context, e.message, danger: true);
    }
  }
}

/// 로컬 프로젝트를 서버에 그대로 재현한다.
/// 인원 → 지출 → 송금 → 입금 처리 순으로 올리며, id는 서버가 새로 발급한 것으로 매핑한다.
Future<CreatedProject> publishToServer(
  SettlementService service,
  SettlementProject local,
) async {
  final created = await service.create(
    name: local.name,
    memberNames: local.members.map((m) => m.name).toList(),
  );
  var project = created.project;
  final code = project.code!;

  // 생성 시 인원 순서를 그대로 지키므로 인덱스로 대응시킨다.
  final memberMap = <String, String>{
    for (var i = 0; i < local.members.length; i++)
      local.members[i].id: project.members[i].id,
  };

  final expenseMap = <String, String>{};
  for (final e in local.expenses) {
    project = await service.addExpense(
      code,
      title: e.title,
      amount: e.amount,
      payerId: memberMap[e.payerId]!,
      participantIds: [
        for (final id in e.participantIds)
          if (memberMap[id] != null) memberMap[id]!
      ],
    );
    // 서버는 입력 순서대로 돌려주므로 방금 올린 건이 마지막이다.
    expenseMap[e.id] = project.expenses.last.id;
  }

  for (final t in local.transfers) {
    project = await service.addTransfer(
      code,
      fromId: memberMap[t.fromId]!,
      toId: memberMap[t.toId]!,
      amount: t.amount,
      memo: t.memo,
    );
  }

  final legs = <({String expenseId, String debtorId})>[];
  for (final key in local.settledLegs) {
    final parts = key.split('::');
    if (parts.length != 2) continue;
    final expenseId = expenseMap[parts[0]];
    final debtorId = memberMap[parts[1]];
    if (expenseId == null || debtorId == null) continue;
    legs.add((expenseId: expenseId, debtorId: debtorId));
  }
  if (legs.isNotEmpty) {
    project = await service.setLegs(code, legs: legs, settled: true);
  }

  return CreatedProject(project: project, ownerToken: created.ownerToken);
}

// ───────────────────────────── 카드 ─────────────────────────────

class _SharedCard extends StatelessWidget {
  final SharedRef sharedRef;
  final VoidCallback onOpen;
  final VoidCallback onForget;

  const _SharedCard({
    required this.sharedRef,
    required this.onOpen,
    required this.onForget,
  });

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      onTap: onOpen,
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, size: 15, color: AppColors.signalGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sharedRef.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Segoe UI',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.snow,
                  ),
                ),
              ),
              _IconAction(
                icon: Icons.copy,
                tooltip: '링크 복사',
                color: AppColors.signalGreen,
                onTap: () => copyShareLink(context, sharedRef.code),
              ),
              _IconAction(
                icon: Icons.close,
                tooltip: '목록에서 제거',
                color: AppColors.danger,
                onTap: onForget,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sharedRef.code,
            style: const TextStyle(
              fontFamily: 'Consolas',
              fontSize: 13,
              letterSpacing: 1.5,
              color: AppColors.parchment,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${sharedRef.isOwner ? '내가 만든 정산표' : '링크로 참여'} · '
            '최근 ${sharedRef.lastOpenedAt.year}.${formatDay(sharedRef.lastOpenedAt)}',
            style: const TextStyle(fontSize: 12, color: AppColors.steel),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final SettlementProject project;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback onPublish;

  const _ProjectCard({
    required this.project,
    required this.onOpen,
    required this.onDelete,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    final done = isFullySettled(project);
    final total = totalSpent(project);

    return PanelCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Segoe UI',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.snow,
                  ),
                ),
              ),
              _IconAction(
                icon: Icons.ios_share,
                tooltip: '공유로 전환',
                color: AppColors.signalGreen,
                onTap: onPublish,
              ),
              _IconAction(
                icon: Icons.delete_outline,
                tooltip: '삭제',
                color: AppColors.danger,
                onTap: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${project.members.length}명 · 지출 ${project.expenses.length}건 · '
            '${project.createdAt.year}.${formatDay(project.createdAt)}',
            style: const TextStyle(fontSize: 12.5, color: AppColors.steel),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Money(total, size: 20, color: AppColors.snow),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: (done ? AppColors.signalGreen : AppColors.warning)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  done ? '정산 완료' : '정산 중',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: done ? AppColors.signalGreen : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(value: settledRatio(project)),
          const SizedBox(height: 12),
          Text(
            project.members.map((m) => m.name).join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.parchment),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  State<_IconAction> createState() => _IconActionState();
}

class _IconActionState extends State<_IconAction> {
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
            padding: const EdgeInsets.all(4),
            child: Icon(
              widget.icon,
              size: 17,
              color: _hover ? widget.color : AppColors.steel,
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── 링크로 열기 ─────────────────────────────

class _OpenByCodeForm extends StatefulWidget {
  const _OpenByCodeForm();

  @override
  State<_OpenByCodeForm> createState() => _OpenByCodeFormState();
}

class _OpenByCodeFormState extends State<_OpenByCodeForm> {
  final _input = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _submit() {
    // 전체 링크를 붙여넣어도, 코드 8자만 넣어도 받는다.
    final raw = _input.text.trim().toLowerCase();
    final match = RegExp(r'([a-z0-9]{8})$').firstMatch(raw);
    if (match == null) {
      setState(() => _error = '공유 링크나 8자리 코드를 입력해주세요.');
      return;
    }
    Navigator.of(context).pop(match.group(1));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LabeledField(
          label: '공유 링크 또는 코드',
          controller: _input,
          hint: 'pure-blanche.com/#/settlement/k3m8qr2t',
          autofocus: true,
          maxLength: 200,
          onSubmitted: (_) => _submit(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(fontSize: 12.5, color: AppColors.danger)),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GhostButton(
                label: '취소', onTap: () => Navigator.of(context).pop()),
            const SizedBox(width: 8),
            PrimaryButton(label: '열기', icon: Icons.arrow_forward, onTap: _submit),
          ],
        ),
      ],
    );
  }
}

// ───────────────────────────── 생성 폼 ─────────────────────────────

/// 생성 결과 — 공유면 [code], 로컬이면 [localId] 가 채워진다.
class _CreateResult {
  final String? code;
  final String? localId;

  const _CreateResult({this.code, this.localId});
}

class _CreateProjectForm extends StatefulWidget {
  final SettlementStore store;
  final SettlementService service;

  const _CreateProjectForm({required this.store, required this.service});

  @override
  State<_CreateProjectForm> createState() => _CreateProjectFormState();
}

class _CreateProjectFormState extends State<_CreateProjectForm> {
  final _name = TextEditingController();
  final _count = TextEditingController(text: '4');
  List<TextEditingController> _names = [];
  bool _share = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _syncNameFields(4);
  }

  @override
  void dispose() {
    _name.dispose();
    _count.dispose();
    for (final c in _names) {
      c.dispose();
    }
    super.dispose();
  }

  /// 인원수 입력에 맞춰 이름 입력칸 개수를 늘리거나 줄인다(입력값은 보존).
  void _syncNameFields(int n) {
    n = n.clamp(1, 30);
    while (_names.length < n) {
      _names.add(TextEditingController());
    }
    if (_names.length > n) {
      for (final c in _names.sublist(n)) {
        c.dispose();
      }
      _names = _names.sublist(0, n);
    }
  }

  void _onCountChanged(String v) {
    final n = int.tryParse(v);
    if (n == null) return;
    setState(() => _syncNameFields(n));
  }

  void _bump(int delta) {
    final n = (int.tryParse(_count.text) ?? _names.length) + delta;
    if (n < 1 || n > 30) return;
    _count.text = '$n';
    setState(() => _syncNameFields(n));
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final projectName = _name.text.trim();
    final names = _names.map((c) => c.text.trim()).toList();

    if (projectName.isEmpty) {
      setState(() => _error = '프로젝트 이름을 입력해주세요.');
      return;
    }
    if (names.length < 2) {
      setState(() => _error = '인원은 2명 이상이어야 정산이 의미가 있다.');
      return;
    }
    if (names.any((n) => n.isEmpty)) {
      setState(() => _error = '모든 인원의 이름을 입력해주세요.');
      return;
    }

    if (!_share) {
      final created = widget.store.createProject(projectName, names);
      if (!mounted) return;
      Navigator.of(context).pop(_CreateResult(localId: created.id));
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final created = await widget.service.create(
        name: projectName,
        memberNames: names,
      );
      widget.store
          .rememberShared(created.project, ownerToken: created.ownerToken);
      if (!mounted) return;
      Navigator.of(context).pop(_CreateResult(code: created.project.code));
    } on SettlementException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 560;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LabeledField(
          label: '프로젝트 이름',
          controller: _name,
          hint: '예: 2월 강릉 여행',
          maxLength: 40,
          autofocus: true,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: 120,
              child: LabeledField(
                label: '인원수',
                controller: _count,
                numeric: true,
                maxLength: 2,
                onChanged: _onCountChanged,
              ),
            ),
            const SizedBox(width: 8),
            GhostButton(label: '−', dense: true, onTap: () => _bump(-1)),
            const SizedBox(width: 6),
            GhostButton(label: '+', dense: true, onTap: () => _bump(1)),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          '인원 이름',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: AppColors.steel,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < _names.length; i++)
                  SizedBox(
                    width: wide ? 218 : double.infinity,
                    child: LabeledField(
                      label: '${i + 1}번',
                      controller: _names[i],
                      hint: '이름',
                      maxLength: 12,
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // ── 저장 위치 ──
        _ShareToggle(
          share: _share,
          onChanged: (v) => setState(() => _share = v),
        ),

        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(
            _error!,
            style: const TextStyle(fontSize: 12.5, color: AppColors.danger),
          ),
        ],
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GhostButton(
              label: '취소',
              onTap: _submitting ? null : () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            PrimaryButton(
              label: _submitting ? '만드는 중…' : '만들기',
              icon: Icons.check,
              onTap: _submitting ? null : _submit,
            ),
          ],
        ),
      ],
    );
  }
}

class _ShareToggle extends StatelessWidget {
  final bool share;
  final ValueChanged<bool> onChanged;

  const _ShareToggle({required this.share, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '저장 위치',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: AppColors.steel,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ShareOption(
                icon: Icons.link,
                title: '링크로 공유',
                subtitle: '서버에 저장. 참여자가 각자 링크로 들어와 입금 처리',
                selected: share,
                onTap: () => onChanged(true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ShareOption(
                icon: Icons.lock_outline,
                title: '나만 보기',
                subtitle: '이 브라우저에만 저장. 서버로 나가지 않음',
                selected: !share,
                onTap: () => onChanged(false),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.signalGreen.withValues(alpha: 0.08)
                : AppColors.abyss,
            border: Border.all(
              color:
                  selected ? AppColors.signalGreen : AppColors.warmCharcoal,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 15,
                    color: selected
                        ? AppColors.signalGreen
                        : AppColors.parchment,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.signalGreen
                          : AppColors.parchment,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.steel, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
