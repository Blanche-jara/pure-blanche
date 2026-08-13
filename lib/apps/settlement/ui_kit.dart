/// 정산표 — 공용 UI 조각.
/// 색상은 전부 [AppColors] 상수만 쓴다(design/DESIGN.md).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../theme/app_colors.dart';

final _won = NumberFormat('#,###');

/// 12345 → "12,345".
String formatWon(int amount) => _won.format(amount);

/// 12345 → "12,345원".
String formatWonUnit(int amount) => '${_won.format(amount)}원';

/// 날짜를 "MM.DD" 로.
String formatDay(DateTime d) =>
    '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

/// 섹션 제목 + 옵션 액션.
class SectionTitle extends StatelessWidget {
  final String text;
  final String? trailingText;
  final Widget? action;

  const SectionTitle(this.text, {super.key, this.trailingText, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Segoe UI',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.snow,
            ),
          ),
          if (trailingText != null) ...[
            const SizedBox(width: 8),
            Text(
              trailingText!,
              style: const TextStyle(fontSize: 12, color: AppColors.steel),
            ),
          ],
          const Spacer(),
          ?action,
        ],
      ),
    );
  }
}

/// 카본 배경 + 차콜 보더 카드. [hoverable] 이면 호버 시 보더가 signalGreen 으로.
class PanelCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool highlighted;
  final Color? borderColor;

  const PanelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.highlighted = false,
    this.borderColor,
  });

  @override
  State<PanelCard> createState() => _PanelCardState();
}

class _PanelCardState extends State<PanelCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = _hover && widget.onTap != null;
    final border = active
        ? AppColors.signalGreen
        : widget.highlighted
            ? AppColors.signalGreen.withValues(alpha: 0.45)
            : (widget.borderColor ?? AppColors.warmCharcoal);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: AppColors.carbon,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.signalGreen.withValues(alpha: 0.12),
                      blurRadius: 18,
                    )
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// signalGreen 채움 버튼(주 액션).
class PrimaryButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool dense;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.dense = false,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: widget.dense ? 12 : 18,
            vertical: widget.dense ? 8 : 12,
          ),
          decoration: BoxDecoration(
            color: !enabled
                ? AppColors.warmCharcoal.withValues(alpha: 0.35)
                : (_hover ? AppColors.signalGreen : AppColors.emerald),
            borderRadius: BorderRadius.circular(8),
            boxShadow: enabled && _hover
                ? [
                    BoxShadow(
                      color: AppColors.signalGreen.withValues(alpha: 0.3),
                      blurRadius: 16,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon,
                    size: widget.dense ? 14 : 16,
                    color: enabled ? AppColors.abyss : AppColors.steel),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: widget.dense ? 12.5 : 14,
                  fontWeight: FontWeight.w700,
                  color: enabled ? AppColors.abyss : AppColors.steel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 보더만 있는 보조 버튼.
class GhostButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? color;
  final bool dense;

  const GhostButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.color,
    this.dense = false,
  });

  @override
  State<GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<GhostButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final base = widget.color ?? AppColors.signalGreen;
    final enabled = widget.onTap != null;
    final fg = !enabled
        ? AppColors.steel
        : _hover
            ? base
            : AppColors.parchment;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: widget.dense ? 10 : 16,
            vertical: widget.dense ? 7 : 11,
          ),
          decoration: BoxDecoration(
            color: _hover && enabled
                ? base.withValues(alpha: 0.08)
                : Colors.transparent,
            border: Border.all(
              color: _hover && enabled ? base : AppColors.warmCharcoal,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: widget.dense ? 14 : 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: widget.dense ? 12.5 : 13.5,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 라벨 + 입력칸 한 세트.
class LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool numeric;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;

  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.numeric = false,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: AppColors.steel,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          inputFormatters: [
            if (numeric) FilteringTextInputFormatter.digitsOnly,
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
          ],
          style: TextStyle(
            fontFamily: numeric ? 'Consolas' : null,
            fontSize: 14.5,
            color: AppColors.snow,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.steel, fontSize: 13.5),
            filled: true,
            fillColor: AppColors.abyss,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            counterText: '',
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.warmCharcoal),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.signalGreen),
            ),
          ),
        ),
      ],
    );
  }
}

/// 선택 가능한 인원 칩(참여자 고르기 / 결제자 고르기).
class MemberChip extends StatefulWidget {
  final String name;
  final bool selected;
  final VoidCallback? onTap;
  final Color accent;
  final String? badge;

  const MemberChip({
    super.key,
    required this.name,
    required this.selected,
    this.onTap,
    this.accent = AppColors.signalGreen,
    this.badge,
  });

  @override
  State<MemberChip> createState() => _MemberChipState();
}

class _MemberChipState extends State<MemberChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.selected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: on
                ? widget.accent.withValues(alpha: 0.14)
                : (_hover ? AppColors.warmCharcoal.withValues(alpha: 0.3) :
                    Colors.transparent),
            border: Border.all(
              color: on
                  ? widget.accent
                  : (_hover ? AppColors.parchment : AppColors.warmCharcoal),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                  color: on ? widget.accent : AppColors.parchment,
                ),
              ),
              if (widget.badge != null) ...[
                const SizedBox(width: 6),
                Text(
                  widget.badge!,
                  style: TextStyle(
                    fontFamily: 'Consolas',
                    fontSize: 11.5,
                    color: on
                        ? widget.accent.withValues(alpha: 0.8)
                        : AppColors.steel,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 금액 텍스트(Consolas + 강조색).
class Money extends StatelessWidget {
  final int amount;
  final double size;
  final Color color;
  final FontWeight weight;
  final bool unit;

  const Money(
    this.amount, {
    super.key,
    this.size = 14,
    this.color = AppColors.snow,
    this.weight = FontWeight.w700,
    this.unit = true,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      unit ? formatWonUnit(amount) : formatWon(amount),
      style: TextStyle(
        fontFamily: 'Consolas',
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: -0.2,
      ),
    );
  }
}

/// 진행률 바.
class ProgressBar extends StatelessWidget {
  final double value; // 0.0 ~ 1.0
  final double height;

  const ProgressBar({super.key, required this.value, this.height = 6});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LayoutBuilder(
        builder: (context, c) => Stack(
          children: [
            Container(
              height: height,
              width: c.maxWidth,
              color: AppColors.warmCharcoal.withValues(alpha: 0.5),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: height,
              width: c.maxWidth * value.clamp(0.0, 1.0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.emerald, AppColors.signalGreen],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 빈 상태 안내.
class EmptyHint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyHint({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.warmCharcoal.withValues(alpha: 0.6),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: AppColors.warmCharcoal),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.parchment),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: AppColors.steel),
            ),
          ],
        ],
      ),
    );
  }
}

/// 정산표 공통 다이얼로그 셸.
Future<T?> showSettlementDialog<T>({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext context) builder,
  double maxWidth = 460,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.carbon,
            border: Border.all(color: AppColors.warmCharcoal),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Segoe UI',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.snow,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close,
                          size: 18, color: AppColors.steel),
                      splashRadius: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                builder(ctx),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// 삭제 등 되돌릴 수 없는 동작 확인.
Future<bool> confirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = '삭제',
}) async {
  final result = await showSettlementDialog<bool>(
    context: context,
    title: title,
    maxWidth: 400,
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          style: const TextStyle(
              fontSize: 13.5, color: AppColors.parchment, height: 1.6),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GhostButton(
              label: '취소',
              onTap: () => Navigator.of(ctx).pop(false),
            ),
            const SizedBox(width: 8),
            GhostButton(
              label: confirmLabel,
              color: AppColors.danger,
              onTap: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      ],
    ),
  );
  return result ?? false;
}

/// 하단 토스트.
void showToast(BuildContext context, String message, {bool danger = false}) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontSize: 13.5,
            color: danger ? AppColors.danger : AppColors.mint,
          ),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.carbon,
        behavior: SnackBarBehavior.floating,
        width: 320,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: danger ? AppColors.danger : AppColors.warmCharcoal,
          ),
        ),
      ),
    );
}
