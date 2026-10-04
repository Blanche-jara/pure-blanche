import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart' hide Ink;
import 'package:flutter/services.dart';
import '../data/save_repository.dart';
import '../engine/balance.dart';
import '../engine/models.dart';
import '../engine/rare.dart';
import '../engine/rules.dart';
import '../state/game_controller.dart';
import 'design_tokens.dart';
import 'widgets/forge_stage.dart';
import 'widgets/checkpoint_shop.dart';
import 'widgets/game_guide.dart';

class ForgeScreen extends StatefulWidget {
  final GameController controller;
  final Color? backgroundColor;
  const ForgeScreen({
    super.key,
    required this.controller,
    this.backgroundColor,
  });
  @override
  State<ForgeScreen> createState() => _ForgeScreenState();
}

class _ForgeScreenState extends State<ForgeScreen> {
  GameController get game => widget.controller;
  GameState get state => game.state;
  bool _dialogOpen = false;
  int _endingSequence = -1;
  final FocusNode _focus = FocusNode();
  @override
  void initState() {
    super.initState();
    game.addListener(_onChange);
  }

  void _onChange() {
    if (game.outcome?.kind == OutcomeKind.ending &&
        !game.busy &&
        _endingSequence != game.actionSequence &&
        !_dialogOpen) {
      _endingSequence = game.actionSequence;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showEnding();
      });
    }
  }

  @override
  void dispose() {
    game.removeListener(_onChange);
    _focus.dispose();
    super.dispose();
  }

  Future<T?> _modal<T>(Widget Function(BuildContext) builder) async {
    if (_dialogOpen || (game.busy && !game.autoRunning)) return null;
    game.unlockAudio();
    _dialogOpen = true;
    try {
      game.stopAuto(silent: true);
      await game.idle;
      if (!mounted) return null;
      return await showDialog<T>(
        context: context,
        builder: (context) => AnimatedBuilder(
          animation: game,
          builder: (context, _) => builder(context),
        ),
      );
    } finally {
      _dialogOpen = false;
      if (mounted) {
        _focus.requestFocus();
        _onChange();
      }
    }
  }

  Future<bool> _confirm(
    String title,
    String message, {
    String action = '진행',
  }) async =>
      await _modal<bool>(
        (context) => _dialog(
          context,
          title,
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(message, style: const TextStyle(height: 1.6)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: PixelButton(
                      label: '취소',
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PixelButton(
                      label: action,
                      primary: true,
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ) ??
      false;
  Future<void> _enhance() async {
    if (_dialogOpen || game.busy || game.autoRunning) return;
    game.unlockAudio();
    if (state.sword.level == state.sword.maximum) return;
    if (state.gold < game.rules.totalCost) {
      game.act(
        (_) => throw const RuleException('골드가 부족합니다. 검을 팔아 자금을 마련하세요.'),
        '',
      );
      return;
    }
    List<int>? materials;
    if (game.rules.gate != null) {
      materials = await _selectMaterials();
      if (materials == null) return;
    } else if (state.confirmHigh &&
        !state.sword.isRare &&
        state.sword.level >= 20 &&
        state.protection == 0) {
      if (!await _confirm(
        '보호 없이 강화',
        '+${state.sword.level} 검이 실패하면 파괴됩니다.\n보호 없이 한 번 더 강화할까요?',
        action: '강화',
      )) {
        return;
      }
    }
    await game.enhance(materials: materials);
  }

  Future<void> _sell({int? slot}) async {
    if (_dialogOpen || game.busy || game.autoRunning) return;
    final sword = slot == null ? state.sword : state.storage[slot];
    if (sword == null) return;
    if (state.confirmHigh &&
        !sword.isRare &&
        sword.level >= 20 &&
        sword.canSell) {
      if (!await _confirm(
        '검 판매',
        '+${sword.level} ${sword.name}을 판매합니다.\n실수령 ${money(game.rules.saleNet(sword))} G',
        action: '판매',
      )) {
        return;
      }
    }
    game.act(
      (rules) => rules.sell(slot: slot),
      '${sword.name} 판매 · ${money(game.rules.saleNet(sword))} G',
    );
  }

  Future<void> _auto() async {
    if (game.autoRunning) {
      game.stopAuto();
      return;
    }
    if (_dialogOpen || game.busy || state.sword.isRare) return;
    game.unlockAudio();
    if (state.confirmHigh && state.autoTarget > 20 && state.protection == 0) {
      if (!await _confirm(
        '자동 강화 시작',
        '목표 +${state.autoTarget}까지 보호 없이 강화합니다.\n검이 파괴돼도 새 검으로 계속합니다.\n돌파·희귀 발견·골드 부족 시 정지합니다.',
        action: '시작',
      )) {
        return;
      }
    }
    unawaited(game.startAuto());
  }

  Future<List<int>?> _selectMaterials() {
    final gate = game.rules.gate!;
    final choices = game.rules.materialCandidates(includeLocked: true);
    final selected = game.rules.materialCandidates().take(gate.count).toSet();
    return _modal<List<int>>(
      (context) => StatefulBuilder(
        builder: (context, update) => _dialog(
          context,
          '+${state.sword.level + 1} 돌파',
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '+${gate.minimumLevel} 이상 일반 검 ${gate.count}자루를 선택하세요.',
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: 8),
              const Text(
                '성공하면 재료가 소모됩니다. 실패하면 그대로 남습니다.',
                style: TextStyle(color: Ink.muted, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              if (choices.isEmpty)
                const Text(
                  '보관함에 사용할 검이 없습니다. 본검을 보관하고 재료 검을 만들어 교체하세요.',
                  style: TextStyle(color: Ink.gold, height: 1.5),
                ),
              for (final slot in choices)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: selected.contains(slot),
                  activeColor: Ink.orange,
                  title: Text(
                    '+${state.storage[slot]!.level} ${state.storage[slot]!.name}',
                  ),
                  subtitle: state.storage[slot]!.locked
                      ? const Text('잠긴 검 · 직접 선택하면 재료로 사용됩니다.')
                      : null,
                  secondary: pixelImage(
                    state.storage[slot]!.image(thumbnail: true),
                    48,
                  ),
                  onChanged: (value) => update(() {
                    value! ? selected.add(slot) : selected.remove(slot);
                  }),
                ),
              const SizedBox(height: 20),
              PixelButton(
                label: '돌파 시도',
                detail: '${money(game.rules.totalCost)} G',
                primary: true,
                onPressed: selected.length == gate.count
                    ? () => Navigator.pop(context, selected.toList())
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) game.unlockAudio();
    if (_dialogOpen || event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.space:
        unawaited(_enhance());
      case LogicalKeyboardKey.keyS:
        unawaited(_sell());
      case LogicalKeyboardKey.keyD:
        game.act((rules) => rules.store(), '검을 보관했습니다.');
      case LogicalKeyboardKey.digit1:
        game.chooseProtection(0);
      case LogicalKeyboardKey.digit2:
        game.chooseProtection(1);
      case LogicalKeyboardKey.digit3:
        game.chooseProtection(2);
      case LogicalKeyboardKey.digit4:
        game.chooseProtection(3);
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _focus,
    autofocus: true,
    onKeyEvent: _key,
    child: Listener(
      onPointerDown: (_) => game.unlockAudio(),
      child: AnimatedBuilder(
        animation: game,
        builder: (context, _) => Scaffold(
          backgroundColor: widget.backgroundColor ?? Ink.background,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final desktop = constraints.maxWidth >= 1000;
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth < 400 ? 12 : 24,
                    vertical: 24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _header(desktop),
                          const SizedBox(height: 20),
                          if (game.saveError != null) ...[
                            PixelPanel(
                              child: Text(
                                game.saveError!,
                                style: const TextStyle(
                                  color: Ink.red,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (desktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _forge()),
                                const SizedBox(width: 20),
                                SizedBox(width: 340, child: _controls()),
                              ],
                            )
                          else ...[
                            _forge(),
                            const SizedBox(height: 16),
                            _controls(compact: true),
                          ],
                          const SizedBox(height: 20),
                          _storage(),
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              const Text(
                                'SPACE 강화  /  S 판매  /  D 보관  /  1~4 보호',
                                style: TextStyle(
                                  color: Ink.muted,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                game.saveError != null
                                    ? '저장 확인 필요'
                                    : game.lastSaved != null
                                    ? '자동 저장됨'
                                    : '진행은 이 브라우저에 저장됩니다',
                                style: const TextStyle(
                                  color: Ink.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
  Widget _header(bool desktop) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SWORD +${Balance.maxLevel}',
                  style: const TextStyle(
                    fontSize: 32,
                    color: Ink.text,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '검 강화하기',
                  style: TextStyle(color: Ink.muted, fontSize: 14),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  assetIcon('gold'),
                  const SizedBox(width: 8),
                  Text(
                    '${money(state.gold)} G',
                    style: const TextStyle(fontSize: 24, color: Ink.gold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '최고 +${state.bestLevel}  ·  시도 ${money(state.attempts.toDouble())}',
                style: const TextStyle(color: Ink.muted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          PixelButton(
            label: '상점',
            icon: desktop ? assetIcon('storage', 16) : null,
            onPressed: game.busy && !game.autoRunning ? null : _shop,
          ),
          PixelButton(
            label: '도감',
            icon: desktop ? assetIcon('book', 16) : null,
            onPressed: game.busy && !game.autoRunning ? null : _codex,
          ),
          PixelButton(
            label: '기록',
            onPressed: game.busy && !game.autoRunning ? null : _records,
          ),
          PixelButton(
            label: '설정',
            onPressed: game.busy && !game.autoRunning ? null : _settings,
          ),
          Tooltip(
            message: state.audioMuted ? '음악과 효과음 켜기' : '음악과 효과음 음소거',
            child: PixelButton(
              key: const ValueKey('game-mute'),
              label: state.audioMuted ? '소리 켜기' : '음소거',
              icon: Icon(
                state.audioMuted ? Icons.volume_off : Icons.volume_up,
                size: 16,
              ),
              selected: state.audioMuted,
              onPressed: () => game.setSettings(audioMuted: !state.audioMuted),
            ),
          ),
          Tooltip(
            message: '게임 도움말',
            child: SizedBox(
              width: 48,
              child: PixelButton(
                key: const ValueKey('game-help'),
                label: '?',
                onPressed: game.busy && !game.autoRunning ? null : _help,
              ),
            ),
          ),
        ],
      ),
    ],
  );
  Widget _forge() {
    final sword = state.sword;
    final color = sword.isRare ? Ink.gold : Ink.tier(sword.level);
    return PixelPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sword.isRare ? '희귀 무기' : '모루 위의 검',
                        style: TextStyle(
                          color: sword.isRare ? Ink.gold : Ink.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '+${sword.level}  ${sword.name}',
                        style: TextStyle(fontSize: 24, color: color),
                      ),
                    ],
                  ),
                ),
                if (sword.isRare)
                  Row(
                    children: List.generate(
                      3,
                      (i) => Opacity(
                        opacity: i < sword.hearts ? 1 : .2,
                        child: assetIcon('heart', 20),
                      ),
                    ),
                  )
                else
                  Text(
                    '${sword.level.toString().padLeft(2, '0')} / ${Balance.maxLevel}',
                    style: const TextStyle(color: Ink.muted, fontSize: 14),
                  ),
              ],
            ),
          ),
          Container(
            color: Ink.inset,
            child: ForgeStage(
              sword: sword,
              outcome: game.outcome,
              sequence: game.actionSequence,
              duration: game.animationDuration,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  color: game.outcome?.kind == OutcomeKind.destroyed
                      ? Ink.red
                      : Ink.orange,
                ),
                Expanded(
                  child: Text(
                    game.message,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: game.outcome?.kind == OutcomeKind.destroyed
                          ? Ink.red
                          : Ink.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls({bool compact = false}) {
    final sword = state.sword;
    final maximum = sword.level == sword.maximum;
    final actionable = !game.busy && !game.autoRunning;
    final base = maximum
        ? 0.0
        : sword.isRare
        ? Balance.rareProbabilities[sword.level]
        : Balance.probabilities[sword.level];
    final bonus = game.rules.probability - base;
    final enhanceButton = PixelButton(
      key: const ValueKey('enhance'),
      label: game.busy
          ? '단조 중...'
          : maximum
          ? '최고 단계 완성'
          : game.rules.gate != null
          ? '돌파하기'
          : '강화하기',
      detail: maximum
          ? null
          : '+${sword.level} → +${sword.level + 1}${compact ? ' · ${money(game.rules.totalCost)} G' : ''}',
      primary: true,
      onPressed: actionable && !maximum ? _enhance : null,
    );
    final autoControls = sword.isRare || maximum
        ? null
        : Row(
            children: [
              const Text(
                '자동 강화',
                style: TextStyle(color: Ink.muted, fontSize: 14),
              ),
              const Spacer(),
              DropdownButton<int>(
                key: const ValueKey('autoTarget'),
                value: state.autoTarget,
                isDense: true,
                underline: const SizedBox(),
                dropdownColor: Ink.panel,
                style: const TextStyle(
                  color: Ink.text,
                  fontFamily: 'NeoDunggeunmo',
                  fontSize: 14,
                ),
                items: List.generate(
                  Balance.maxLevel,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('목표 +${i + 1}'),
                  ),
                ),
                onChanged: actionable
                    ? (value) => game.setAutoTarget(value!)
                    : null,
              ),
              const SizedBox(width: 12),
              PixelButton(
                label: game.autoRunning ? '정지' : '시작',
                onPressed: game.autoRunning || !game.busy ? _auto : null,
              ),
            ],
          );
    return PixelPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.unlockedStartLevel > 0 || state.rareStarts.isNotEmpty) ...[
            Text(
              '새 검 시작점 · ${game.rules.startName}',
              style: const TextStyle(color: Ink.gold, fontSize: 14),
            ),
            const SizedBox(height: 12),
          ],
          if (compact) ...[
            enhanceButton,
            if (autoControls != null) ...[
              const SizedBox(height: 10),
              autoControls,
            ],
            const SizedBox(height: 20),
          ],
          Row(
            children: [
              const Expanded(
                child: Text(
                  '강화 성공률',
                  style: TextStyle(color: Ink.muted, fontSize: 14),
                ),
              ),
              Text(
                maximum
                    ? '완성'
                    : '${(game.rules.probability * 100).toStringAsFixed(1)}%',
                style: const TextStyle(color: Ink.green, fontSize: 28),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: maximum ? 1 : game.rules.probability,
            minHeight: 4,
            color: Ink.green,
            backgroundColor: Ink.border,
          ),
          const SizedBox(height: 8),
          Text(
            sword.isRare
                ? '실패하면 내구도 −1 · 보호 사용 불가'
                : bonus > .0001
                ? '장인의 기운 +${(bonus * 100).toStringAsFixed(1)}%p'
                : '실패하면 파괴 · 보호로 지킬 수 있습니다',
            style: const TextStyle(color: Ink.muted, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 20),
          _stat('총 강화비', '${money(game.rules.totalCost)} G', color: Ink.gold),
          const SizedBox(height: 8),
          _stat(
            '판매 실수령',
            sword.canSell ? '${money(game.rules.saleNet(sword))} G' : '판매 불가',
          ),
          const SizedBox(height: 8),
          Text(
            '판매 수수료 ${(state.fee * 100).round()}% · 협상 Lv.${state.negotiation}',
            style: const TextStyle(color: Ink.muted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          if (!sword.isRare) ...[
            Row(
              children: [
                assetIcon('shield', 16),
                const SizedBox(width: 6),
                const Text(
                  '파괴 방지',
                  style: TextStyle(color: Ink.muted, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                4,
                (option) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: option == 3 ? 0 : 6),
                    child: PixelButton(
                      key: ValueKey('protection-$option'),
                      label: ['없음', '25%', '50%', '90%'][option],
                      detail:
                          '${money(Balance.protectionCost(sword.level, option))} G',
                      selected: state.protection == option,
                      onPressed: actionable && !maximum
                          ? () => game.chooseProtection(option)
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sword.level == 0
                  ? '+0은 보호 적용 없이 강화합니다.'
                  : '보호비는 현재 검 가치에 비례 · 성공해도 결제',
              style: const TextStyle(
                color: Ink.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (!compact) enhanceButton,
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: PixelButton(
                  key: const ValueKey('sell'),
                  label: '판매',
                  onPressed: actionable && sword.canSell
                      ? () => unawaited(_sell())
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PixelButton(
                  label: '보관',
                  onPressed: actionable && sword.canStore
                      ? () => game.act((rules) => rules.store(), '검을 보관했습니다.')
                      : null,
                ),
              ),
            ],
          ),
          if (game.rules.canRelief) ...[
            const SizedBox(height: 12),
            PixelButton(
              label: '대장간 잡일',
              detail: '+50 G · 다시 시작할 자금',
              onPressed: actionable
                  ? () =>
                        game.act((rules) => rules.relief(), '잡일을 마쳤습니다. +50 G')
                  : null,
            ),
          ],
          if (!compact && autoControls != null) ...[
            const SizedBox(height: 20),
            Container(height: 1, color: Ink.border),
            const SizedBox(height: 16),
            autoControls,
          ],
        ],
      ),
    );
  }

  Widget _storage() {
    final next = state.sword.isRare
        ? null
        : Balance.gates.entries
              .where((entry) => entry.key >= state.sword.level)
              .firstOrNull;
    final ready = next == null
        ? 0
        : state.storage
              .whereType<Sword>()
              .where(
                (s) =>
                    !s.isRare &&
                    !s.locked &&
                    s.level >= next.value.minimumLevel &&
                    s.level < Balance.maxLevel,
              )
              .length;
    return PixelPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              assetIcon('storage', 20),
              const SizedBox(width: 8),
              const Text('보관함', style: TextStyle(fontSize: 18)),
              const Spacer(),
              Text(
                '${state.storage.whereType<Sword>().length} / ${state.storage.length}칸',
                style: const TextStyle(color: Ink.muted, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(state.maxStorageSlots, (slot) {
                final purchased = slot < state.storage.length;
                final sword = purchased ? state.storage[slot] : null;
                final columns = state.testAccount ? 4 : 5;
                return SizedBox(
                  width: (constraints.maxWidth - 8 * (columns - 1)) / columns,
                  child: Padding(
                    padding: EdgeInsets.zero,
                    child: Semantics(
                      button: true,
                      label: sword == null
                          ? purchased
                                ? '빈 보관 칸'
                                : '보관 칸 구매'
                          : '+${sword.level} ${sword.name}',
                      child: Material(
                        color: Ink.inset,
                        child: InkWell(
                          onTap: game.busy
                              ? null
                              : () => sword != null
                                    ? _slotMenu(slot)
                                    : purchased
                                    ? _storeInto(slot)
                                    : _shop(),
                          child: Container(
                            height: 96,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: sword?.isRare == true
                                    ? Ink.orange
                                    : Ink.border,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (sword != null)
                                  pixelImage(
                                    sword.image(thumbnail: true),
                                    constraints.maxWidth >= 500 ? 48 : 32,
                                  )
                                else if (!purchased)
                                  Opacity(
                                    opacity: .45,
                                    child: assetIcon('lock', 24),
                                  )
                                else
                                  const Icon(
                                    Icons.add,
                                    size: 24,
                                    color: Ink.border,
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  sword != null
                                      ? '+${sword.level}${sword.locked ? ' 잠금' : ''}'
                                      : purchased
                                      ? '빈칸'
                                      : '구매',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: sword != null ? Ink.text : Ink.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            next == null
                ? state.sword.isRare
                      ? '희귀 무기는 돌파 재료로 사용하지 않습니다.'
                      : '모든 돌파를 마쳤습니다.'
                : '다음 돌파 +${next.key} → +${next.key + 1}  ·  +${next.value.minimumLevel} 이상 ${min(ready, next.value.count)}/${next.value.count}자루',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: next != null && ready >= next.value.count
                  ? Ink.green
                  : Ink.muted,
            ),
          ),
        ],
      ),
    );
  }

  void _storeInto(int slot) {
    game.act((rules) => rules.store(slot: slot), '검을 보관했습니다.');
  }

  void _slotMenu(int slot) {
    _modal<void>((context) {
      final sword = state.storage[slot];
      if (sword == null) {
        return _dialog(context, '빈 보관 칸', const Text('검을 보관하면 이곳에 표시됩니다.'));
      }
      return _dialog(
        context,
        '+${sword.level} ${sword.name}',
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: pixelImage(sword.image(), 128)),
            const SizedBox(height: 16),
            PixelButton(
              label: !state.sword.canStore ? '모루로 꺼내기' : '모루 검과 교체',
              onPressed: () {
                Navigator.pop(context);
                game.act((rules) => rules.swap(slot), '보관 검을 모루로 가져왔습니다.');
              },
            ),
            const SizedBox(height: 10),
            PixelButton(
              label: sword.locked ? '잠금 해제' : '잠금',
              detail: '잠긴 검은 판매·자동 재료 선택에서 제외',
              onPressed: () => game.act(
                (rules) => rules.toggleLock(slot),
                sword.locked ? '잠금을 해제했습니다.' : '검을 잠갔습니다.',
              ),
            ),
            const SizedBox(height: 10),
            PixelButton(
              label: '판매',
              detail: '${money(game.rules.saleNet(sword))} G',
              onPressed: sword.canSell && !sword.locked
                  ? () {
                      Navigator.pop(context);
                      unawaited(_sellAfterModal(slot));
                    }
                  : null,
            ),
          ],
        ),
      );
    });
  }

  Future<void> _sellAfterModal(int slot) async {
    await Future<void>.delayed(Duration.zero);
    if (mounted) await _sell(slot: slot);
  }

  void _shop() => unawaited(
    _modal<void>(
      (context) => _dialog(
        context,
        '대장간 상점',
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '소지금 ${money(state.gold)} G',
              style: const TextStyle(color: Ink.gold),
            ),
            const SizedBox(height: 24),
            _stat('보관함', '${state.storage.length} / ${state.maxStorageSlots}칸'),
            const SizedBox(height: 8),
            const Text(
              '돌파 재료를 준비하거나 아끼는 검을 맡겨두세요.',
              style: TextStyle(color: Ink.muted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            PixelButton(
              label: state.storage.length < 5 ? '보관 칸 1개 추가' : '보관함 확장 완료',
              detail: state.storage.length < 5
                  ? '${money(Balance.slotPrices[state.storage.length])} G'
                  : null,
              onPressed:
                  state.storage.length < 5 &&
                      state.gold >= Balance.slotPrices[state.storage.length]
                  ? () => game.act((rules) => rules.buySlot(), '보관 칸을 확장했습니다.')
                  : null,
            ),
            const SizedBox(height: 28),
            _stat(
              '협상력',
              'Lv.${state.negotiation} · 수수료 ${(state.fee * 100).round()}%',
            ),
            const SizedBox(height: 8),
            const Text(
              '검을 팔 때 내는 수수료를 5%p 줄입니다.',
              style: TextStyle(color: Ink.muted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            PixelButton(
              label: state.negotiation < 5 ? '협상력 높이기' : '협상력 성장 완료',
              detail: state.negotiation < 5
                  ? '${money(Balance.negotiationPrices[state.negotiation])} G'
                  : null,
              onPressed:
                  state.negotiation < 5 &&
                      state.gold >= Balance.negotiationPrices[state.negotiation]
                  ? () => game.act(
                      (rules) => rules.buyNegotiation(),
                      '협상력이 올랐습니다.',
                    )
                  : null,
            ),
            const SizedBox(height: 28),
            _stat(
              '희귀 발견 확률',
              'Lv.${state.rareChanceLevel} · ${(state.rareChance * 100).toStringAsFixed(1)}% / 최대 5%',
            ),
            const SizedBox(height: 8),
            const Text(
              '일반 검이 실제로 파괴됐을 때 적용됩니다.\n구매하면 영구 유지되며, 희귀 발견 시 자동 강화가 멈춥니다.',
              style: TextStyle(color: Ink.muted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            PixelButton(
              key: const ValueKey('buy-rare-chance'),
              label: state.rareChanceLevel < Balance.rareChancePrices.length
                  ? '희귀 발견 확률 높이기'
                  : '희귀 발견 확률 최대 달성',
              detail: state.rareChanceLevel < Balance.rareChancePrices.length
                  ? '${(state.rareChance * 100).toStringAsFixed(1)}% → ${(Balance.rareChanceLevels[state.rareChanceLevel + 1] * 100).toStringAsFixed(1)}% · ${money(Balance.rareChancePrices[state.rareChanceLevel])} G'
                  : '최대 5.0%',
              onPressed:
                  state.rareChanceLevel < Balance.rareChancePrices.length &&
                      state.gold >=
                          Balance.rareChancePrices[state.rareChanceLevel]
                  ? () => game.act(
                      (rules) => rules.buyRareChance(),
                      '희귀 발견 확률이 ${(Balance.rareChanceLevels[state.rareChanceLevel + 1] * 100).toStringAsFixed(1)}%로 올랐습니다.',
                    )
                  : null,
            ),
            const SizedBox(height: 24),
            Container(height: 1, color: Ink.border),
            const SizedBox(height: 24),
            CheckpointShop(game: game),
            const SizedBox(height: 16),
            Text(
              game.message,
              style: const TextStyle(
                color: Ink.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  void _records() => unawaited(
    _modal<void>(
      (context) => _dialog(
        context,
        '대장간 기록',
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _stat('최고 강화', '+${state.bestLevel}'),
            const SizedBox(height: 16),
            _stat('강화 시도', '${money(state.attempts.toDouble())}회'),
            const SizedBox(height: 16),
            _stat('검 파괴', '${money(state.destructions.toDouble())}회'),
            const SizedBox(height: 16),
            _stat('사용 골드', '${money(state.spent)} G'),
            const SizedBox(height: 16),
            _stat('플레이 시간', playTime(state.playSeconds)),
            const SizedBox(height: 16),
            _stat(
              '희귀 무기 발견',
              '${state.rareFinds}회 · ${state.discovered.length}/7종',
            ),
            if (state.ending != null) ...[
              const SizedBox(height: 24),
              PixelButton(
                label: '완성한 전설 보기',
                onPressed: () {
                  Navigator.pop(context);
                  Future<void>.delayed(Duration.zero, _showEnding);
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
  void _codex() => unawaited(
    _modal<void>(
      (context) => DefaultTabController(
        length: 2,
        child: _dialog(
          context,
          '검 도감',
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TabBar(
                labelColor: Ink.gold,
                unselectedLabelColor: Ink.muted,
                indicatorColor: Ink.orange,
                tabs: [
                  Tab(text: '일반 검'),
                  Tab(text: '희귀 무기'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: min(400, MediaQuery.sizeOf(context).height * .55),
                child: TabBarView(
                  children: [
                    GridView.builder(
                      itemCount: Balance.maxLevel + 1,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 120,
                            mainAxisExtent: 148,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemBuilder: (context, level) {
                        final seen = level <= state.bestLevel;
                        return Container(
                          decoration: BoxDecoration(
                            color: Ink.inset,
                            border: Border.all(color: Ink.border),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (seen)
                                pixelImage(
                                  Sword(level: level).image(thumbnail: true),
                                  48,
                                )
                              else
                                const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Center(
                                    child: Text(
                                      '?',
                                      style: TextStyle(
                                        fontSize: 28,
                                        color: Ink.border,
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                '+$level',
                                style: const TextStyle(
                                  color: Ink.muted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                seen ? Balance.normalNames[level] : '미발견',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: seen ? Ink.text : Ink.muted,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    ListView.separated(
                      itemCount: rareWeapons.length,
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final rare = rareWeapons[index];
                        final seen = state.discovered.containsKey(rare.id);
                        return Container(
                          padding: const EdgeInsets.all(12),
                          color: Ink.inset,
                          child: Row(
                            children: [
                              if (seen)
                                pixelImage(
                                  Sword(rareId: rare.id).image(thumbnail: true),
                                  64,
                                )
                              else
                                const SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: Center(
                                    child: Text(
                                      '?',
                                      style: TextStyle(
                                        fontSize: 28,
                                        color: Ink.border,
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      seen ? rare.name : '미발견 무기',
                                      style: TextStyle(
                                        color: seen ? Ink.gold : Ink.muted,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      seen
                                          ? rare.description
                                          : '일반 검이 파괴되면 드물게 발견합니다.',
                                      style: const TextStyle(
                                        color: Ink.muted,
                                        fontSize: 12,
                                        height: 1.5,
                                      ),
                                    ),
                                    if (seen) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        '최고 +${state.discovered[rare.id]}',
                                        style: const TextStyle(
                                          color: Ink.green,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  void _help() => unawaited(
    _modal<void>(
      (context) => _dialog(
        context,
        '게임 도움말',
        const GameGuide(),
        maxWidth: 560,
        scrollContent: false,
      ),
    ),
  );

  void _settings() => unawaited(
    _modal<void>(
      (context) => _dialog(
        context,
        '설정 · 저장',
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('배경음악'),
              subtitle: const Text('자동 반복 재생 · 첫 클릭/터치에서 시작할 수 있습니다'),
              activeThumbColor: Ink.orange,
              value: state.musicEnabled,
              onChanged: (value) => game.setSettings(musicEnabled: value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('효과음'),
              subtitle: const Text('망치 타격 · 검 파괴 소리'),
              activeThumbColor: Ink.orange,
              value: state.soundEnabled,
              onChanged: (value) => game.setSettings(soundEnabled: value),
            ),
            if (state.audioMuted)
              const Text(
                '전체 음소거 중입니다. 상단의 소리 켜기로 해제하세요.',
                style: TextStyle(color: Ink.muted, fontSize: 12),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('짧은 강화 연출'),
              subtitle: const Text('수동 0.9초 → 0.4초 · 자동 0.3초 → 0.15초'),
              activeThumbColor: Ink.orange,
              value: state.shortAnimation,
              onChanged: (value) => game.setSettings(shortAnimation: value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('고강 검 실수 방지'),
              subtitle: const Text('+20 이상 무보호 강화·판매 전에 확인'),
              activeThumbColor: Ink.orange,
              value: state.confirmHigh,
              onChanged: (value) => game.setSettings(confirmHigh: value),
            ),
            const SizedBox(height: 16),
            const Text(
              '진행은 현재 브라우저에 자동 저장됩니다. 다른 기기로 옮기거나 브라우저 데이터를 지우기 전에 백업하세요.',
              style: TextStyle(color: Ink.muted, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 20),
            PixelButton(
              label: '백업 코드 내보내기',
              onPressed: () {
                Navigator.pop(context);
                Future<void>.delayed(Duration.zero, _backupText);
              },
            ),
            const SizedBox(height: 10),
            PixelButton(
              label: '백업 코드 가져오기',
              onPressed: () {
                Navigator.pop(context);
                Future<void>.delayed(Duration.zero, _importDialog);
              },
            ),
            const SizedBox(height: 24),
            const Divider(color: Ink.border),
            const SizedBox(height: 12),
            PixelButton(
              key: const ValueKey('reset-game'),
              label: '게임 초기화',
              danger: true,
              onPressed: () {
                Navigator.pop(context);
                Future<void>.delayed(Duration.zero, _resetDialog);
              },
            ),
          ],
        ),
      ),
    ),
  );
  Future<void> _resetDialog() async {
    bool resetting = false;
    String? error;
    await _modal<void>(
      (context) => StatefulBuilder(
        builder: (context, update) => _dialog(
          context,
          '게임을 초기화할까요?',
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '골드, 검, 보관함, 도감, 상점 구매와 엔딩 기록이 모두 초기화됩니다.\n필요한 진행은 먼저 백업 코드로 보관하세요.',
                style: TextStyle(color: Ink.red, height: 1.6),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, style: const TextStyle(color: Ink.red)),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: PixelButton(
                      label: '취소',
                      onPressed: resetting
                          ? null
                          : () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PixelButton(
                      key: const ValueKey('confirm-reset'),
                      label: resetting ? '초기화 중...' : '초기화하기',
                      danger: true,
                      onPressed: resetting
                          ? null
                          : () async {
                              update(() => resetting = true);
                              try {
                                await game.resetGame();
                                if (context.mounted) Navigator.pop(context);
                              } catch (_) {
                                if (context.mounted) {
                                  update(() {
                                    resetting = false;
                                    error = '초기화 내용을 저장하지 못했습니다. 현재 진행은 유지됩니다.';
                                  });
                                }
                              }
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _backupText() {
    final code = SaveRepository.encode(state);
    String? status;
    unawaited(
      _modal<void>(
        (context) => StatefulBuilder(
          builder: (context, update) => _dialog(
            context,
            '백업 코드',
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '아래 코드를 복사해서 보관하세요.',
                  style: TextStyle(color: Ink.muted, height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  color: Ink.inset,
                  padding: const EdgeInsets.all(12),
                  height: 180,
                  child: SingleChildScrollView(
                    child: SelectableText(
                      code,
                      semanticsLabel: code,
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                PixelButton(
                  label: '코드 복사',
                  onPressed: () async {
                    try {
                      await Clipboard.setData(ClipboardData(text: code));
                      if (context.mounted) update(() => status = '복사했습니다.');
                    } catch (_) {
                      if (context.mounted) {
                        update(() => status = '코드를 직접 선택해서 복사하세요.');
                      }
                    }
                  },
                ),
                if (status != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    status!,
                    style: const TextStyle(color: Ink.gold, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _importDialog() async {
    final text = TextEditingController();
    String? error;
    bool importing = false;
    await _modal<void>(
      (context) => StatefulBuilder(
        builder: (context, update) => _dialog(
          context,
          '백업 가져오기',
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '현재 진행을 백업 데이터로 교체합니다.',
                style: TextStyle(color: Ink.gold, height: 1.5),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: text,
                maxLines: 5,
                minLines: 3,
                enabled: !importing,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'SU1. 으로 시작하는 코드를 붙여넣으세요.',
                  border: OutlineInputBorder(),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!,
                  style: const TextStyle(color: Ink.red, height: 1.5),
                ),
              ],
              const SizedBox(height: 20),
              PixelButton(
                label: importing ? '불러오는 중...' : '가져오기',
                primary: true,
                onPressed: importing
                    ? null
                    : () async {
                        update(() => importing = true);
                        try {
                          await game.importBackup(text.text);
                          if (context.mounted) Navigator.pop(context);
                        } catch (failure) {
                          if (context.mounted) {
                            update(() {
                              importing = false;
                              error = failure is FormatException
                                  ? failure.message
                                  : '백업을 불러오지 못했습니다. 현재 진행은 유지됩니다.';
                            });
                          }
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
    text.dispose();
  }

  void _showEnding() => unawaited(
    _modal<void>(
      (context) => _dialog(
        context,
        '전설을 완성했습니다',
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 320 / 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/sword_upgrade/ending/ending_bg.png',
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                  pixelImage(Sword(level: Balance.maxLevel).image(), 192),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '+${Balance.maxLevel} 종언의 검',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, color: Ink.gold),
            ),
            const SizedBox(height: 12),
            const Text(
              '수없이 두드린 망치 끝에,\n당신의 대장간에 전설이 남았습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.8),
            ),
            const SizedBox(height: 24),
            _stat(
              '강화 시도',
              '${money(((state.ending?['attempts'] ?? state.attempts) as num).toDouble())}회',
            ),
            const SizedBox(height: 12),
            _stat(
              '플레이 시간',
              playTime(
                (state.ending?['playSeconds'] ?? state.playSeconds) as int,
              ),
            ),
            const SizedBox(height: 24),
            PixelButton(
              label: '대장간으로',
              primary: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _stat(String label, String value, {Color color = Ink.text}) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: Ink.muted, fontSize: 14),
        ),
      ),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 16, color: color),
        ),
      ),
    ],
  );
  Widget _dialog(
    BuildContext context,
    String title,
    Widget content, {
    double maxWidth = 480,
    bool scrollContent = true,
  }) => Dialog(
    backgroundColor: Ink.panel,
    shape: const BeveledRectangleBorder(side: BorderSide(color: Ink.border)),
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(color: Ink.gold, fontSize: 24),
                  ),
                ),
                IconButton(
                  tooltip: '닫기',
                  icon: const Icon(Icons.close, color: Ink.muted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: scrollContent
                  ? SingleChildScrollView(child: content)
                  : content,
            ),
          ],
        ),
      ),
    ),
  );
}
