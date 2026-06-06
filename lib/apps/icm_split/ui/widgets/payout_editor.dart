import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
import '../../core/payout_presets.dart';
import '../../models/payout_structure.dart';
import '../../state/persistence_providers.dart';
import '../../state/scenario_controller.dart';
import 'apple_widgets.dart';
import 'number_field.dart';

/// 상금 구조 입력 위젯. "직접 입력"과 "자동 분배" 두 모드를 토글.
class PayoutEditor extends ConsumerStatefulWidget {
  const PayoutEditor({super.key});

  @override
  ConsumerState<PayoutEditor> createState() => _PayoutEditorState();
}

enum _Mode { manual, auto }

class _PayoutEditorState extends ConsumerState<PayoutEditor> {
  _Mode _mode = _Mode.manual;

  // 자동 분배 모드의 로컬 입력값.
  double _pool = 1000000;
  int _autoPlaces = 3;

  @override
  Widget build(BuildContext context) {
    final payout = ref.watch(scenarioControllerProvider).payout;
    final controller = ref.read(scenarioControllerProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '상금 구조',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    letterSpacing: -0.374,
                  ),
                ),
                const Spacer(),
                Text(
                  '합계 ${Fmt.money(payout.total, whole: true)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<_Mode>(
              segments: const [
                ButtonSegment(value: _Mode.manual, label: Text('직접 입력')),
                ButtonSegment(value: _Mode.auto, label: Text('자동 분배')),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: 8),
            _buildPresetControls(controller),
            const SizedBox(height: 12),
            if (_mode == _Mode.manual)
              _ManualEditor(payout.payouts, controller)
            else
              _buildAuto(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetControls(ScenarioController controller) {
    final presets = ref.watch(savedPresetsProvider);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: presets.isEmpty
                ? null
                : () => _applyPresetSheet(controller),
            icon: const Icon(Icons.bookmark_border),
            label: Text(presets.isEmpty ? '저장된 프리셋 없음' : '프리셋 적용'),
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => _savePresetDialog(controller),
          icon: const Icon(Icons.bookmark_add_outlined),
          label: const Text('프리셋 저장'),
        ),
      ],
    );
  }

  Future<void> _applyPresetSheet(ScenarioController controller) async {
    final presets = ref.read(savedPresetsProvider);
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('프리셋 적용')),
            for (final p in presets)
              ListTile(
                leading: const Icon(Icons.bookmark),
                title: Text(p.name),
                subtitle: Text(
                  '${p.payouts.length}자리 · ${Fmt.money(p.total, whole: true)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    ref.read(savedPresetsProvider.notifier).remove(p.name);
                    Navigator.pop(ctx);
                  },
                ),
                onTap: () {
                  controller.applyPreset(p);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePresetDialog(ScenarioController controller) async {
    final current = ref.read(scenarioControllerProvider).payout;
    final name = await showTextPrompt(
      context,
      title: '프리셋 저장',
      confirmLabel: '저장',
      initial: current.name,
      label: '프리셋 이름',
      hint: '예: STT 3인 50/30/20',
    );
    if (name == null || name.trim().isEmpty) return;
    final preset = PayoutStructure(
      name: name.trim(),
      payouts: List<double>.from(current.payouts),
    );
    await ref.read(savedPresetsProvider.notifier).save(preset);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('프리셋 "${preset.name}" 저장됨')));
    }
  }

  Widget _buildAuto(ScenarioController controller) {
    final preset = PayoutPresets.forPlaces(_autoPlaces);
    final preview = preset.distribute(_pool);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: NumberField(
                label: 'GTD (총 상금)',
                prefixText: '₩ ',
                value: _pool,
                decimals: 0,
                onChanged: (v) => setState(() => _pool = v),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 150,
              child: NumberField(
                label: '인머니 인원',
                value: _autoPlaces.toDouble(),
                step: 1,
                min: 1,
                max: 30,
                onChanged: (v) => setState(() => _autoPlaces = v.round()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '프리셋: ${preset.name}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < preview.length; i++)
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text('${i + 1}등 ${Fmt.money(preview[i], whole: true)}'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => controller.autoDistribute(_pool, _autoPlaces),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('적용'),
          ),
        ),
      ],
    );
  }
}

class _ManualEditor extends StatelessWidget {
  const _ManualEditor(this.payouts, this.controller);
  final List<double> payouts;
  final ScenarioController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('지급 자리 수'),
            const Spacer(),
            IconButton.outlined(
              onPressed: payouts.length <= 1
                  ? null
                  : () => controller.setPayoutPlaces(payouts.length - 1),
              icon: const Icon(Icons.remove, size: 18),
              visualDensity: VisualDensity.compact,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${payouts.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton.outlined(
              onPressed: () => controller.setPayoutPlaces(payouts.length + 1),
              icon: const Icon(Icons.add, size: 18),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < payouts.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    '${i + 1}등',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: NumberField(
                    value: payouts[i],
                    prefixText: '₩ ',
                    decimals: 0,
                    dense: true,
                    onChanged: (v) => controller.updatePayoutAt(i, v),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
