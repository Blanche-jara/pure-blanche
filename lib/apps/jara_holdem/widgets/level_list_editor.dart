import 'package:flutter/material.dart';
import '../models/blind_level.dart';
import '../models/break_level.dart';

class LevelListEditor extends StatefulWidget {
  final List<dynamic> levels;
  final ValueChanged<List<dynamic>> onChanged;

  const LevelListEditor({
    super.key,
    required this.levels,
    required this.onChanged,
  });

  @override
  State<LevelListEditor> createState() => _LevelListEditorState();
}

class _LevelListEditorState extends State<LevelListEditor> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...List.generate(widget.levels.length, (index) {
          final level = widget.levels[index];
          final isExpanded = _expandedIndex == index;
          if (level is BlindLevel) {
            return _BlindLevelCard(
              level: level,
              isExpanded: isExpanded,
              onTap: () => setState(() {
                _expandedIndex = isExpanded ? null : index;
              }),
              onChanged: (updated) => _updateLevel(index, updated),
              onDelete: () => _deleteLevel(index),
            );
          } else if (level is BreakLevel) {
            return _BreakLevelCard(
              level: level,
              isExpanded: isExpanded,
              onTap: () => setState(() {
                _expandedIndex = isExpanded ? null : index;
              }),
              onChanged: (updated) => _updateLevel(index, updated),
              onDelete: () => _deleteLevel(index),
            );
          }
          return const SizedBox.shrink();
        }),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _addBlindLevel,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Level'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade800,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _addBreak,
              icon: const Icon(Icons.coffee, size: 18),
              label: const Text('Add Break'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _updateLevel(int index, dynamic newLevel) {
    final newLevels = List<dynamic>.from(widget.levels);
    newLevels[index] = newLevel;
    widget.onChanged(_renumberLevels(newLevels));
  }

  void _deleteLevel(int index) {
    final newLevels = List<dynamic>.from(widget.levels);
    newLevels.removeAt(index);
    if (_expandedIndex == index) {
      _expandedIndex = null;
    } else if (_expandedIndex != null && _expandedIndex! > index) {
      _expandedIndex = _expandedIndex! - 1;
    }
    widget.onChanged(_renumberLevels(newLevels));
  }

  void _addBreak() {
    final newLevels = List<dynamic>.from(widget.levels);
    newLevels.add(const BreakLevel(durationMinutes: 10));
    setState(() {
      _expandedIndex = newLevels.length - 1;
    });
    widget.onChanged(newLevels);
  }

  void _addBlindLevel() {
    BlindLevel lastBlind = const BlindLevel(level: 0, smallBlind: 0, bigBlind: 0);
    for (final l in widget.levels.reversed) {
      if (l is BlindLevel) {
        lastBlind = l;
        break;
      }
    }

    final nextLevel = BlindLevel(
      level: _countBlinds() + 1,
      smallBlind: lastBlind.smallBlind > 0 ? (lastBlind.smallBlind * 1.5).round() : 25,
      bigBlind: lastBlind.bigBlind > 0 ? (lastBlind.bigBlind * 1.5).round() : 50,
      ante: lastBlind.ante > 0 ? (lastBlind.ante * 1.5).round() : 0,
      durationMinutes: lastBlind.durationMinutes > 0 ? lastBlind.durationMinutes : 15,
    );

    final newLevels = List<dynamic>.from(widget.levels);
    newLevels.add(nextLevel);
    setState(() {
      _expandedIndex = newLevels.length - 1;
    });
    widget.onChanged(_renumberLevels(newLevels));
  }

  int _countBlinds() {
    return widget.levels.whereType<BlindLevel>().length;
  }

  List<dynamic> _renumberLevels(List<dynamic> levels) {
    int blindNum = 1;
    return levels.map((l) {
      if (l is BlindLevel) {
        final renumbered = l.copyWith(level: blindNum);
        blindNum++;
        return renumbered;
      }
      return l;
    }).toList();
  }
}

// ─── Blind Level Card ─────────────────────────────────────────

class _BlindLevelCard extends StatelessWidget {
  final BlindLevel level;
  final bool isExpanded;
  final VoidCallback onTap;
  final ValueChanged<BlindLevel> onChanged;
  final VoidCallback onDelete;

  const _BlindLevelCard({
    required this.level,
    required this.isExpanded,
    required this.onTap,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isExpanded ? Colors.green.shade600 : Colors.transparent,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: Column(
          children: [
            // ── Summary row (only this area toggles expand) ──
            GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 14, bottom: 14, right: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green.shade800,
                      radius: 18,
                      child: Text(
                        '${level.level}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // SB / BB display
                    Expanded(
                      child: Row(
                        children: [
                          _ValueChip(label: 'SB', value: level.smallBlind),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text('/', style: TextStyle(color: Colors.white24, fontSize: 18)),
                          ),
                          _ValueChip(label: 'BB', value: level.bigBlind),
                          if (level.ante > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade900.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'A ${level.ante}',
                                style: const TextStyle(color: Colors.orange, fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Duration badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${level.durationMinutes}m',
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                    // Delete button (always visible)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.close, size: 18, color: Colors.white24),
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      splashRadius: 18,
                    ),
                  ],
                ),
              ),
            ),
            // ── Expanded editor (touches here do NOT close the card) ──
            if (isExpanded) _buildEditor(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    return GestureDetector(
      // Block taps from propagating up to the card's toggle
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          children: [
            // ── SB / BB inline text fields ──
            Row(
              children: [
                Expanded(
                  child: _InlineTextField(
                    label: 'Small Blind',
                    value: level.smallBlind,
                    color: Colors.green,
                    onChanged: (v) => onChanged(level.copyWith(smallBlind: v)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InlineTextField(
                    label: 'Big Blind',
                    value: level.bigBlind,
                    color: Colors.green,
                    onChanged: (v) => onChanged(level.copyWith(bigBlind: v)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // ── Duration dial ──
            _DurationDial(
              minutes: level.durationMinutes,
              onChanged: (v) => onChanged(level.copyWith(durationMinutes: v)),
            ),
            const SizedBox(height: 14),
            // ── Ante toggle ──
            _AnteToggle(
              ante: level.ante,
              onChanged: (v) => onChanged(level.copyWith(ante: v)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Break Level Card ─────────────────────────────────────────

class _BreakLevelCard extends StatelessWidget {
  final BreakLevel level;
  final bool isExpanded;
  final VoidCallback onTap;
  final ValueChanged<BreakLevel> onChanged;
  final VoidCallback onDelete;

  const _BreakLevelCard({
    required this.level,
    required this.isExpanded,
    required this.onTap,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber.shade900.withValues(alpha: 0.3),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isExpanded ? Colors.amber.shade600 : Colors.transparent,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: Column(
          children: [
            // ── Summary row ──
            GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 14, bottom: 14, right: 8),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.amber,
                      radius: 18,
                      child: Icon(Icons.coffee, size: 18, color: Colors.black),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'BREAK',
                        style: TextStyle(
                          color: Colors.amber.shade300,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${level.durationMinutes}m',
                        style: TextStyle(color: Colors.amber.shade300, fontSize: 13),
                      ),
                    ),
                    // Delete button (always visible)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.close, size: 18, color: Colors.white24),
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      splashRadius: 18,
                    ),
                  ],
                ),
              ),
            ),
            // ── Expanded editor ──
            if (isExpanded)
              GestureDetector(
                onTap: () {},
                behavior: HitTestBehavior.opaque,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    border: Border(top: BorderSide(color: Colors.amber.withValues(alpha: 0.15))),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: _DurationDial(
                    minutes: level.durationMinutes,
                    color: Colors.amber,
                    onChanged: (v) => onChanged(level.copyWith(durationMinutes: v)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Components ──────────────────────────────────────

/// Small chip showing label + value (used in summary row)
class _ValueChip extends StatelessWidget {
  final String label;
  final int value;

  const _ValueChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade900.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline editable text field for SB/BB — tap to focus, type directly
class _InlineTextField extends StatefulWidget {
  final String label;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  const _InlineTextField({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  State<_InlineTextField> createState() => _InlineTextFieldState();
}

class _InlineTextFieldState extends State<_InlineTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_InlineTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update text if value changed externally and field is not focused
    if (oldWidget.value != widget.value && !_isFocused) {
      _controller.text = '${widget.value}';
    }
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    if (_focusNode.hasFocus) {
      // Select all text on focus
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    } else {
      // Commit value on blur
      _commitValue();
    }
  }

  void _commitValue() {
    final parsed = int.tryParse(_controller.text);
    if (parsed != null && parsed > 0 && parsed != widget.value) {
      widget.onChanged(parsed);
    } else {
      // Revert to original value if invalid
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: _isFocused ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isFocused
              ? widget.color
              : widget.color.withValues(alpha: 0.3),
          width: _isFocused ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            widget.label,
            style: TextStyle(
              color: widget.color.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          IntrinsicWidth(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _commitValue(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dial-style duration picker (scroll wheel)
class _DurationDial extends StatefulWidget {
  final int minutes;
  final Color color;
  final ValueChanged<int> onChanged;

  const _DurationDial({
    required this.minutes,
    this.color = Colors.green,
    required this.onChanged,
  });

  @override
  State<_DurationDial> createState() => _DurationDialState();
}

class _DurationDialState extends State<_DurationDial> {
  late final FixedExtentScrollController _scrollController;

  static const _minVal = 1;
  static const _maxVal = 50;

  @override
  void initState() {
    super.initState();
    final index = (widget.minutes.clamp(_minVal, _maxVal)) - _minVal;
    _scrollController = FixedExtentScrollController(initialItem: index);
  }

  @override
  void didUpdateWidget(_DurationDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.minutes != widget.minutes) {
      final index = (widget.minutes.clamp(_minVal, _maxVal)) - _minVal;
      if (_scrollController.selectedItem != index) {
        _scrollController.animateToItem(index,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.color.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: widget.color.withValues(alpha: 0.6), size: 20),
          const SizedBox(width: 10),
          Text(
            'Duration',
            style: TextStyle(color: widget.color.withValues(alpha: 0.7), fontSize: 13),
          ),
          const Spacer(),
          // Dial wheel
          SizedBox(
            height: 48,
            width: 70,
            child: ListWheelScrollView.useDelegate(
              controller: _scrollController,
              itemExtent: 32,
              physics: const FixedExtentScrollPhysics(),
              perspective: 0.003,
              diameterRatio: 1.5,
              onSelectedItemChanged: (index) {
                widget.onChanged(index + _minVal);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: _maxVal - _minVal + 1,
                builder: (context, index) {
                  final val = index + _minVal;
                  final isSelected = val == widget.minutes;
                  return Center(
                    child: Text(
                      '$val',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white30,
                        fontSize: isSelected ? 22 : 15,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'min',
            style: TextStyle(color: widget.color.withValues(alpha: 0.5), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Ante checkbox toggle with inline editable value
class _AnteToggle extends StatefulWidget {
  final int ante;
  final ValueChanged<int> onChanged;

  const _AnteToggle({required this.ante, required this.onChanged});

  @override
  State<_AnteToggle> createState() => _AnteToggleState();
}

class _AnteToggleState extends State<_AnteToggle> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  bool get _enabled => widget.ante > 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.ante > 0 ? '${widget.ante}' : '25',
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_onBlur);
  }

  @override
  void didUpdateWidget(_AnteToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ante != widget.ante && widget.ante > 0 && !_focusNode.hasFocus) {
      _controller.text = '${widget.ante}';
    }
  }

  void _onBlur() {
    if (!_focusNode.hasFocus && _enabled) {
      _commitValue();
    }
  }

  void _commitValue() {
    final parsed = int.tryParse(_controller.text);
    if (parsed != null && parsed > 0 && parsed != widget.ante) {
      widget.onChanged(parsed);
    } else if (parsed == null || parsed <= 0) {
      _controller.text = '${widget.ante > 0 ? widget.ante : 25}';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onBlur);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _enabled
            ? Colors.orange.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _enabled
              ? Colors.orange.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _enabled,
              onChanged: (checked) {
                if (checked == true) {
                  final val = int.tryParse(_controller.text) ?? 25;
                  widget.onChanged(val > 0 ? val : 25);
                } else {
                  widget.onChanged(0);
                }
              },
              activeColor: Colors.orange,
              side: const BorderSide(color: Colors.white24),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Ante',
            style: TextStyle(
              color: _enabled ? Colors.orange : Colors.white30,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          if (_enabled)
            SizedBox(
              width: 80,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: Colors.orange.withValues(alpha: 0.15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.orange),
                  ),
                ),
                onSubmitted: (_) => _commitValue(),
              ),
            ),
        ],
      ),
    );
  }
}
