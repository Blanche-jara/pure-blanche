import 'package:flutter/material.dart' hide Ink;
import '../../engine/checkpoints.dart';
import '../../engine/models.dart';
import '../../engine/rare.dart';
import '../../state/game_controller.dart';
import '../design_tokens.dart';

class CheckpointShop extends StatefulWidget {
  final GameController game;
  const CheckpointShop({super.key, required this.game});
  @override
  State<CheckpointShop> createState() => _CheckpointShopState();
}

class _CheckpointShopState extends State<CheckpointShop> {
  String rareId = rareWeapons.first.id;
  GameController get game => widget.game;
  GameState get state => game.state;

  void select({int level = 0, String? id}) => game.act(
    (rules) => rules.selectStart(level: level, rareId: id),
    '시작점을 선택했습니다. 다음 새 검부터 적용됩니다.',
  );

  @override
  Widget build(BuildContext context) {
    final selected = state.startRareId == null
        ? 'normal:${state.startLevel}'
        : 'rare:${state.startRareId}';
    final ownedRare = state.rareStarts.contains(rareId);
    final foundRare = state.discovered.containsKey(rareId);
    final rare = rareWeapons.firstWhere((w) => w.id == rareId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('세이브포인트', style: TextStyle(color: Ink.gold, fontSize: 20)),
        const SizedBox(height: 12),
        const Text(
          '구매한 시작점은 영구 유지됩니다. 파괴·판매·보관 후 새 검에 적용하며, 강화한 모루 검은 교체하지 않습니다.',
          style: TextStyle(color: Ink.muted, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 12),
        const Text('새 검 시작점', style: TextStyle(color: Ink.muted, fontSize: 14)),
        DropdownButton<String>(
          key: const ValueKey('start-point'),
          value: selected,
          isExpanded: true,
          dropdownColor: Ink.panel,
          items: [
            const DropdownMenuItem(value: 'normal:0', child: Text('일반 검 +0')),
            for (final level in Checkpoints.normalLevels)
              if (level <= state.unlockedStartLevel)
                DropdownMenuItem(
                  value: 'normal:$level',
                  child: Text('일반 검 +$level'),
                ),
            for (final weapon in rareWeapons)
              if (state.rareStarts.contains(weapon.id))
                DropdownMenuItem(
                  value: 'rare:${weapon.id}',
                  child: Text('${weapon.name} +0'),
                ),
          ],
          onChanged: (value) {
            if (value == null) return;
            final parts = value.split(':');
            if (parts[0] == 'normal') {
              select(level: int.parse(parts[1]));
            } else {
              select(id: parts[1]);
            }
          },
        ),
        const SizedBox(height: 12),
        const Text('일반 검 시작점', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        const Text(
          '해당 단계에 도달하면 구매할 수 있습니다. 높은 구간은 낮은 구간도 포함하며, 추가 구매는 차액만 냅니다.',
          style: TextStyle(color: Ink.muted, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 12),
        for (final level in Checkpoints.normalLevels) ...[
          _normal(level),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 18),
        const Text(
          '희귀 무기 +0 시작점',
          style: TextStyle(color: Ink.gold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Text(
          '발견한 종류만 구매할 수 있습니다. 가격은 일반 +31 시작점의 30배. 기본 가치 34.8조 G·내구도 3으로 시작합니다.',
          style: TextStyle(color: Ink.muted, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 12),
        DropdownButton<String>(
          key: const ValueKey('rare-start-choice'),
          value: rareId,
          isExpanded: true,
          dropdownColor: Ink.panel,
          items: [
            for (final weapon in rareWeapons)
              DropdownMenuItem(
                value: weapon.id,
                child: Text(
                  '${weapon.name}${state.rareStarts.contains(weapon.id)
                      ? ' · 구매함'
                      : state.discovered.containsKey(weapon.id)
                      ? ''
                      : ' · 미발견'}',
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => rareId = value);
          },
        ),
        Row(
          children: [
            pixelImage(Sword(rareId: rareId).image(thumbnail: true), 48),
            const SizedBox(width: 12),
            Expanded(
              child: PixelButton(
                key: const ValueKey('buy-rare-start'),
                label: ownedRare
                    ? '${rare.name} +0 선택'
                    : '${rare.name} +0 시작 구매',
                detail: ownedRare
                    ? '구매 완료'
                    : '${money(Checkpoints.rarePrice)} G${foundRare ? '' : ' · 발견 후 구매'}',
                selected: state.startRareId == rareId,
                onPressed: ownedRare
                    ? () => select(id: rareId)
                    : foundRare && state.gold >= Checkpoints.rarePrice
                    ? () => game.act(
                        (rules) => rules.buyRareStart(rareId),
                        '희귀 +0 시작점을 구매했습니다.',
                      )
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          '시작 검은 한 번 강화해야 판매·보관 가능합니다. 판매액은 늘어난 가치 기준입니다. +11·21·31은 직전 돌파를 건너뛰며 이후 돌파에는 재료가 필요합니다. +0 시작은 언제든 무료로 선택할 수 있습니다.',
          style: TextStyle(color: Ink.muted, fontSize: 12, height: 1.5),
        ),
      ],
    );
  }

  Widget _normal(int level) {
    final owned = level <= state.unlockedStartLevel;
    final available = state.bestLevel >= level;
    final cost = game.rules.normalStartCost(level);
    return Row(
      children: [
        pixelImage(Sword(level: level).image(thumbnail: true), 48),
        const SizedBox(width: 12),
        Expanded(
          child: PixelButton(
            key: ValueKey('buy-start-$level'),
            label: owned ? '+$level 시작 선택' : '+$level 시작 구매',
            detail: owned
                ? '구매 완료'
                : '${money(cost)} G${available ? '' : ' · 최고 +$level 필요'}',
            selected: state.startRareId == null && state.startLevel == level,
            onPressed: owned
                ? () => select(level: level)
                : available && state.gold >= cost
                ? () => game.act(
                    (rules) => rules.buyNormalStart(level),
                    '+$level 시작점을 구매했습니다.',
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
