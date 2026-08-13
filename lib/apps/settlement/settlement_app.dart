/// 정산표 — 엔트리 + 프로젝트 목록/생성.
library;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'engine.dart';
import 'models.dart';
import 'project_view.dart';
import 'store.dart';
import 'ui_kit.dart';

class SettlementApp extends StatefulWidget {
  const SettlementApp({super.key});

  @override
  State<SettlementApp> createState() => _SettlementAppState();
}

class _SettlementAppState extends State<SettlementApp> {
  final _store = SettlementStore();
  String? _openProjectId;

  @override
  void initState() {
    super.initState();
    _store.init();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.abyss,
      child: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          if (!_store.ready) {
            return const Center(
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

          final open =
              _openProjectId == null ? null : _store.byId(_openProjectId!);
          if (open == null) {
            return _ProjectListView(
              store: _store,
              onOpen: (id) => setState(() => _openProjectId = id),
            );
          }
          return ProjectView(
            store: _store,
            project: open,
            onClose: () => setState(() => _openProjectId = null),
          );
        },
      ),
    );
  }
}

// ───────────────────────────── 프로젝트 목록 ─────────────────────────────

class _ProjectListView extends StatelessWidget {
  final SettlementStore store;
  final ValueChanged<String> onOpen;

  const _ProjectListView({required this.store, required this.onOpen});

  Future<void> _create(BuildContext context) async {
    final id = await showSettlementDialog<String>(
      context: context,
      title: '새 정산 프로젝트',
      maxWidth: 520,
      builder: (ctx) => _CreateProjectForm(store: store),
    );
    if (id != null) onOpen(id);
  }

  @override
  Widget build(BuildContext context) {
    final projects = store.projects;
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
                  if (projects.isNotEmpty)
                    Text(
                      '${projects.length}개',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.steel),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (projects.isEmpty)
                const EmptyHint(
                  icon: Icons.receipt_long_outlined,
                  title: '아직 정산 프로젝트가 없다.',
                  subtitle: '모임 하나당 프로젝트 하나. 인원 이름을 먼저 등록하고 지출을 쌓아나가면 된다.',
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
                          onOpen: () => onOpen(p.id),
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
                '데이터는 이 브라우저에만 저장된다(localStorage).',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.steel.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final SettlementProject project;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _ProjectCard({
    required this.project,
    required this.onOpen,
    required this.onDelete,
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

// ───────────────────────────── 생성 폼 ─────────────────────────────

class _CreateProjectForm extends StatefulWidget {
  final SettlementStore store;

  const _CreateProjectForm({required this.store});

  @override
  State<_CreateProjectForm> createState() => _CreateProjectFormState();
}

class _CreateProjectFormState extends State<_CreateProjectForm> {
  final _name = TextEditingController();
  final _count = TextEditingController(text: '4');
  List<TextEditingController> _names = [];
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

  void _submit() {
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

    final created = widget.store.createProject(projectName, names);
    Navigator.of(context).pop(created.id);
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
          constraints: const BoxConstraints(maxHeight: 260),
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
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            PrimaryButton(label: '만들기', icon: Icons.check, onTap: _submit),
          ],
        ),
      ],
    );
  }
}
