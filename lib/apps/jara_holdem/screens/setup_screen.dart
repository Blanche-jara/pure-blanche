import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/blind_level.dart';
import '../models/break_level.dart';
import '../models/tournament_structure.dart';
import '../presets/default_presets.dart';
import '../providers/tournament_provider.dart';
import '../services/structure_generator.dart';
import '../services/structure_parser.dart';
import '../widgets/level_list_editor.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late TextEditingController _nameController;
  late List<dynamic> _levels;
  late bool _isCashGame;

  @override
  void initState() {
    super.initState();
    final provider = context.read<TournamentProvider>();
    _nameController = TextEditingController(text: provider.structure.name);
    _levels = List.from(provider.structure.levels);
    _isCashGame = provider.structure.isCashGame;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Tournament Setup', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Preset selector
          _buildPresetSelector(),
          const Divider(color: Colors.white12, height: 1),
          // Tournament name
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: const InputDecoration(
                labelText: 'Tournament Name',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
            ),
          ),
          // Cash game: SB/BB editor only
          if (_isCashGame) _buildCashGameEditor(),
          // Empty slate with import option
          if (!_isCashGame && _levels.isEmpty) _buildImportView(),
          // Tournament: full level editor
          if (!_isCashGame && _levels.isNotEmpty)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 80),
                child: LevelListEditor(
                  levels: _levels,
                  onChanged: (newLevels) {
                    setState(() {
                      _levels = newLevels;
                    });
                  },
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF1E1E1E),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Save & Start', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text('Preset:', style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(width: 12),
          _PresetChip(
            label: 'Classic Tournament',
            selected: !_isCashGame && _nameController.text == classicTournament.name,
            onTap: () => _applyPreset(classicTournament),
          ),
          const SizedBox(width: 8),
          _PresetChip(
            label: 'Classic Cash',
            selected: _isCashGame,
            onTap: () => _applyPreset(classicCash),
          ),
          const SizedBox(width: 8),
          _PresetChip(
            label: 'Empty Slate',
            selected: !_isCashGame && _levels.isEmpty,
            onTap: () => _applyPreset(emptySlate),
          ),
        ],
      ),
    );
  }

  void _applyPreset(TournamentStructure preset) {
    setState(() {
      _nameController.text = preset.name;
      _levels = List.from(preset.levels);
      _isCashGame = preset.isCashGame;
    });
  }

  Widget _buildCashGameEditor() {
    final blind = _levels.isNotEmpty ? _levels[0] as BlindLevel : const BlindLevel(level: 0, smallBlind: 100, bigBlind: 200, durationMinutes: 0);
    final sbController = TextEditingController(text: blind.smallBlind.toString());
    final bbController = TextEditingController(text: blind.bigBlind.toString());

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.casino, color: Colors.cyan, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Cash Game Mode',
              style: TextStyle(color: Colors.cyan, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Single level with no time limit',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: sbController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'Small Blind',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                    ),
                    onChanged: (val) {
                      final sb = int.tryParse(val) ?? blind.smallBlind;
                      setState(() {
                        _levels = [blind.copyWith(smallBlind: sb, durationMinutes: 0)];
                      });
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('/', style: TextStyle(color: Colors.white38, fontSize: 28)),
                ),
                Expanded(
                  child: TextField(
                    controller: bbController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'Big Blind',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                    ),
                    onChanged: (val) {
                      final bb = int.tryParse(val) ?? blind.bigBlind;
                      setState(() {
                        _levels = [blind.copyWith(bigBlind: bb, durationMinutes: 0)];
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportView() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Format guide
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.white38),
                      const SizedBox(width: 6),
                      const Text(
                        'Format Guide',
                        style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: StructureParser.aiPrompt));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('AI prompt copied to clipboard'),
                              duration: Duration(seconds: 2),
                              backgroundColor: Color(0xFF2A2A2A),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.smart_toy_outlined, size: 13, color: Colors.blue),
                              SizedBox(width: 4),
                              Text(
                                'Copy AI Prompt',
                                style: TextStyle(color: Colors.blue, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    StructureParser.formatDescription,
                    style: const TextStyle(color: Colors.white30, fontSize: 12, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Import text area
            Expanded(
              child: _StructureImportField(
                onImport: (levels) {
                  setState(() {
                    _levels = levels;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            // Or add manually
            Row(
              children: [
                const Expanded(child: Divider(color: Colors.white12)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12)),
                ),
                const Expanded(child: Divider(color: Colors.white12)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _showAutoGenerateDialog,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Auto Generate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _levels = [
                        const BlindLevel(level: 1, smallBlind: 25, bigBlind: 50, durationMinutes: 15),
                      ];
                    });
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Manually'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade800,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAutoGenerateDialog() {
    showDialog<List<dynamic>>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => const _AutoGenerateDialog(),
    ).then((generated) {
      if (generated != null && generated.isNotEmpty) {
        setState(() {
          _levels = List<dynamic>.from(generated);
        });
      }
    });
  }

  void _save() {
    final structure = TournamentStructure(
      name: _nameController.text.trim().isEmpty ? 'Tournament' : _nameController.text.trim(),
      levels: _levels,
      isCashGame: _isCashGame,
    );
    context.read<TournamentProvider>().setStructure(structure);
    Navigator.pop(context);
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PresetChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected ? Colors.green.shade800 : Colors.transparent,
          border: Border.all(color: selected ? Colors.green : Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white54,
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _StructureImportField extends StatefulWidget {
  final ValueChanged<List<dynamic>> onImport;

  const _StructureImportField({required this.onImport});

  @override
  State<_StructureImportField> createState() => _StructureImportFieldState();
}

class _StructureImportFieldState extends State<_StructureImportField> {
  final _controller = TextEditingController();
  List<String>? _errors;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tryImport() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final result = StructureParser.parse(text);
    if (result.hasErrors) {
      setState(() {
        _errors = result.errors;
      });
    } else {
      setState(() {
        _errors = null;
      });
      widget.onImport(result.levels);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'monospace',
              height: 1.6,
            ),
            decoration: InputDecoration(
              hintText: StructureParser.formatHelp,
              hintStyle: const TextStyle(color: Colors.white12, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              contentPadding: const EdgeInsets.all(14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: _errors != null ? Colors.red.withValues(alpha: 0.5) : Colors.white12,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: _errors != null ? Colors.red : Colors.green,
                ),
              ),
            ),
            onChanged: (_) {
              if (_errors != null) {
                setState(() { _errors = null; });
              }
            },
          ),
        ),
        // Error display
        if (_errors != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            constraints: const BoxConstraints(maxHeight: 80),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _errors!
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            e,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: _tryImport,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Import Structure'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}

class _AutoGenerateDialog extends StatefulWidget {
  const _AutoGenerateDialog();

  @override
  State<_AutoGenerateDialog> createState() => _AutoGenerateDialogState();
}

class _AutoGenerateDialogState extends State<_AutoGenerateDialog> {
  bool _hasAnte = false;
  int _startChips = 20000;
  int _minChip = 100;
  int _playTime = 180;
  int _numPlayers = 9;
  int _levelDuration = 0; // 0 = auto
  int _anteStart = 3;
  String _anteType = 'bb';

  bool _insertBreaks = true;
  int _breakInterval = 4;
  int _breakDuration = 15;

  late final TextEditingController _startChipsCtrl;
  late final TextEditingController _minChipCtrl;
  late final TextEditingController _playTimeCtrl;
  late final TextEditingController _numPlayersCtrl;
  late final TextEditingController _levelDurationCtrl;
  late final TextEditingController _anteStartCtrl;
  late final TextEditingController _breakIntervalCtrl;
  late final TextEditingController _breakDurationCtrl;

  @override
  void initState() {
    super.initState();
    _startChipsCtrl = TextEditingController(text: _startChips.toString());
    _minChipCtrl = TextEditingController(text: _minChip.toString());
    _playTimeCtrl = TextEditingController(text: _playTime.toString());
    _numPlayersCtrl = TextEditingController(text: _numPlayers.toString());
    _levelDurationCtrl = TextEditingController(text: _levelDuration.toString());
    _anteStartCtrl = TextEditingController(text: _anteStart.toString());
    _breakIntervalCtrl = TextEditingController(text: _breakInterval.toString());
    _breakDurationCtrl = TextEditingController(text: _breakDuration.toString());
  }

  @override
  void dispose() {
    _startChipsCtrl.dispose();
    _minChipCtrl.dispose();
    _playTimeCtrl.dispose();
    _numPlayersCtrl.dispose();
    _levelDurationCtrl.dispose();
    _anteStartCtrl.dispose();
    _breakIntervalCtrl.dispose();
    _breakDurationCtrl.dispose();
    super.dispose();
  }

  StructureGeneratorOptions _buildOptions() => StructureGeneratorOptions(
        hasAnte: _hasAnte,
        startChips: _startChips,
        minChip: _minChip,
        playTime: _playTime,
        numPlayers: _numPlayers,
        levelDuration: _levelDuration,
        anteStart: _anteStart,
        anteType: _anteType,
        insertBreaks: _insertBreaks,
        breakInterval: _breakInterval,
        breakDuration: _breakDuration,
      );

  void _generate() {
    final levels = StructureGenerator.generate(_buildOptions());
    Navigator.of(context).pop(levels);
  }

  @override
  Widget build(BuildContext context) {
    final preview = StructureGenerator.generate(_buildOptions());
    final effectiveDuration =
        _levelDuration > 0 ? _levelDuration : StructureGenerator.calcLevelDuration(_playTime, _numPlayers);

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.deepPurpleAccent, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Auto Generate Structure',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _NumberField(
                              label: 'Starting Chips',
                              controller: _startChipsCtrl,
                              onChanged: (v) => setState(() => _startChips = v.clamp(100, 10000000)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _NumberField(
                              label: 'Min Chip',
                              controller: _minChipCtrl,
                              onChanged: (v) => setState(() => _minChip = v.clamp(1, 10000)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _NumberField(
                              label: 'Play Time (min)',
                              controller: _playTimeCtrl,
                              onChanged: (v) => setState(() => _playTime = v.clamp(30, 1440)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _NumberField(
                              label: 'Players',
                              controller: _numPlayersCtrl,
                              onChanged: (v) => setState(() => _numPlayers = v.clamp(2, 1000)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _NumberField(
                        label: 'Level Duration (min, 0 = auto)',
                        controller: _levelDurationCtrl,
                        onChanged: (v) => setState(() => _levelDuration = v.clamp(0, 60)),
                      ),
                      const SizedBox(height: 16),
                      _AnteSection(
                        hasAnte: _hasAnte,
                        anteStart: _anteStart,
                        anteStartCtrl: _anteStartCtrl,
                        anteType: _anteType,
                        onHasAnteChanged: (v) => setState(() => _hasAnte = v),
                        onAnteStartChanged: (v) => setState(() => _anteStart = v.clamp(1, 99)),
                        onAnteTypeChanged: (v) => setState(() => _anteType = v),
                      ),
                      const SizedBox(height: 12),
                      _BreakSection(
                        insertBreaks: _insertBreaks,
                        breakInterval: _breakInterval,
                        breakDuration: _breakDuration,
                        breakIntervalCtrl: _breakIntervalCtrl,
                        breakDurationCtrl: _breakDurationCtrl,
                        onInsertBreaksChanged: (v) => setState(() => _insertBreaks = v),
                        onIntervalChanged: (v) => setState(() => _breakInterval = v.clamp(1, 99)),
                        onDurationChanged: (v) => setState(() => _breakDuration = v.clamp(1, 120)),
                      ),
                      const SizedBox(height: 16),
                      _PreviewBox(
                        levels: preview,
                        levelDuration: effectiveDuration,
                        totalChips: _startChips * _numPlayers,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white54,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: preview.isEmpty ? null : _generate,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Use This Structure'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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
}

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<int> onChanged;

  const _NumberField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.deepPurpleAccent),
        ),
      ),
      onChanged: (val) {
        final parsed = int.tryParse(val);
        if (parsed != null) onChanged(parsed);
      },
    );
  }
}

class _AnteSection extends StatelessWidget {
  final bool hasAnte;
  final int anteStart;
  final TextEditingController anteStartCtrl;
  final String anteType;
  final ValueChanged<bool> onHasAnteChanged;
  final ValueChanged<int> onAnteStartChanged;
  final ValueChanged<String> onAnteTypeChanged;

  const _AnteSection({
    required this.hasAnte,
    required this.anteStart,
    required this.anteStartCtrl,
    required this.anteType,
    required this.onHasAnteChanged,
    required this.onAnteStartChanged,
    required this.onAnteTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('Ante', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              Switch(
                value: hasAnte,
                activeColor: Colors.deepPurpleAccent,
                onChanged: onHasAnteChanged,
              ),
            ],
          ),
          if (hasAnte) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    label: 'Ante Start Level',
                    controller: anteStartCtrl,
                    onChanged: onAnteStartChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: anteType,
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Ante Type',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.deepPurpleAccent),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'bb', child: Text('BB Ante')),
                      DropdownMenuItem(value: 'half', child: Text('Half BB (= SB)')),
                      DropdownMenuItem(value: 'classic', child: Text('Classic (10% BB)')),
                    ],
                    onChanged: (val) {
                      if (val != null) onAnteTypeChanged(val);
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BreakSection extends StatelessWidget {
  final bool insertBreaks;
  final int breakInterval;
  final int breakDuration;
  final TextEditingController breakIntervalCtrl;
  final TextEditingController breakDurationCtrl;
  final ValueChanged<bool> onInsertBreaksChanged;
  final ValueChanged<int> onIntervalChanged;
  final ValueChanged<int> onDurationChanged;

  const _BreakSection({
    required this.insertBreaks,
    required this.breakInterval,
    required this.breakDuration,
    required this.breakIntervalCtrl,
    required this.breakDurationCtrl,
    required this.onInsertBreaksChanged,
    required this.onIntervalChanged,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('Breaks', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              Switch(
                value: insertBreaks,
                activeColor: Colors.deepPurpleAccent,
                onChanged: onInsertBreaksChanged,
              ),
            ],
          ),
          if (insertBreaks) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    label: 'Every N Levels',
                    controller: breakIntervalCtrl,
                    onChanged: onIntervalChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberField(
                    label: 'Break Length (min)',
                    controller: breakDurationCtrl,
                    onChanged: onDurationChanged,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewBox extends StatelessWidget {
  final List<dynamic> levels;
  final int levelDuration;
  final int totalChips;

  const _PreviewBox({
    required this.levels,
    required this.levelDuration,
    required this.totalChips,
  });

  String _fmt(int n) {
    final str = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final blindCount = levels.whereType<BlindLevel>().length;
    final breakCount = levels.whereType<BreakLevel>().length;
    final totalMinutes = levels.fold<int>(0, (sum, lv) {
      if (lv is BlindLevel) return sum + lv.durationMinutes;
      if (lv is BreakLevel) return sum + lv.durationMinutes;
      return sum;
    });

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.preview, size: 14, color: Colors.white38),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Preview — $blindCount lv × ${levelDuration}m'
                  '${breakCount > 0 ? ' + $breakCount brk' : ''}'
                  ' · ${totalMinutes}m',
                  style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                'Total chips: ${_fmt(totalChips)}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: SingleChildScrollView(
              child: Column(
                children: levels.map<Widget>((lv) {
                  if (lv is BreakLevel) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 28,
                            child: Icon(Icons.coffee, size: 12, color: Colors.orangeAccent),
                          ),
                          Expanded(
                            child: Text(
                              'BREAK · ${lv.durationMinutes}m',
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  if (lv is BlindLevel) {
                    final anteStr = lv.ante > 0 ? ' / ${_fmt(lv.ante)}' : '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              'L${lv.level}',
                              style: const TextStyle(color: Colors.white38, fontSize: 12, fontFamily: 'monospace'),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${_fmt(lv.smallBlind)} / ${_fmt(lv.bigBlind)}$anteStr',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
