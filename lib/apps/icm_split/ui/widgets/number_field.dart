import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 숫자 입력 필드. 선택적으로 +/- 스텝 버튼을 붙일 수 있다.
///
/// 외부 [value]가 (스텝 버튼 등으로) 바뀌면 텍스트를 동기화하되, 사용자가 타이핑 중인
/// 커서 위치는 보존한다. [decimals]==0이면 정수 입력으로 취급.
class NumberField extends StatefulWidget {
  const NumberField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.prefixText,
    this.step = 0,
    this.decimals = 0,
    this.min = 0,
    this.max = double.infinity,
    this.dense = false,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final String? label;
  final String? hint;
  final String? prefixText;

  /// 0보다 크면 +/- 버튼을 표시하고 그 크기만큼 증감한다.
  final double step;

  /// 표시 소수 자리. 0이면 정수.
  final int decimals;
  final double min;
  final double max;
  final bool dense;

  @override
  State<NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
    _focus = FocusNode();
    // 포커스 시 전체 선택 → 타이핑으로 바로 교체(빠른 숫자 입력 UX).
    _focus.addListener(() {
      if (_focus.hasFocus) {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      }
    });
  }

  @override
  void didUpdateWidget(NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부 값이 바뀌었고, 현재 입력칸 파싱값과 다르면 동기화(타이핑 충돌 방지).
    final current = double.tryParse(_controller.text);
    if (widget.value != oldWidget.value &&
        (current == null || (current - widget.value).abs() > 1e-9)) {
      final text = _format(widget.value);
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _format(double v) => widget.decimals == 0
      ? v.round().toString()
      : v.toStringAsFixed(widget.decimals);

  double _clamp(double v) => v.clamp(widget.min, widget.max);

  void _emit(double v) => widget.onChanged(_clamp(v));

  void _bump(double delta) {
    final base = double.tryParse(_controller.text) ?? widget.value;
    final next = _clamp(base + delta);
    final text = _format(next);
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: _controller,
      focusNode: _focus,
      keyboardType: TextInputType.numberWithOptions(
        decimal: widget.decimals > 0,
        signed: false,
      ),
      inputFormatters: [
        widget.decimals > 0
            ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            : FilteringTextInputFormatter.digitsOnly,
      ],
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixText: widget.prefixText,
        isDense: widget.dense,
        border: const OutlineInputBorder(),
        contentPadding: widget.dense
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
            : null,
      ),
      onChanged: (t) {
        final v = double.tryParse(t);
        if (v != null) _emit(v);
      },
    );

    if (widget.step <= 0) return field;

    return Row(
      children: [
        _StepButton(icon: Icons.remove, onTap: () => _bump(-widget.step)),
        const SizedBox(width: 4),
        Expanded(child: field),
        const SizedBox(width: 4),
        _StepButton(icon: Icons.add, onTap: () => _bump(widget.step)),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
    );
  }
}
