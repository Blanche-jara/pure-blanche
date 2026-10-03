import 'package:flutter/material.dart';

abstract final class Ink {
  static const background = Color(0xff15120f);
  static const panel = Color(0xff211d18);
  static const inset = Color(0xff191613);
  static const border = Color(0xff493c2d);
  static const text = Color(0xfff3e7cb);
  static const muted = Color(0xffb5a58c);
  static const orange = Color(0xffe58e43);
  static const gold = Color(0xffffce73);
  static const green = Color(0xffa3cb88);
  static const red = Color(0xffe18a79);
  static Color tier(int level) => level >= 36
      ? const Color(0xffd6b9ff)
      : level >= 31
      ? red
      : level >= 26
      ? gold
      : level >= 21
      ? orange
      : level >= 16
      ? const Color(0xffcba6ed)
      : level >= 11
      ? const Color(0xff92cfde)
      : level >= 6
      ? green
      : text;
}

String money(double amount) {
  if (amount >= 1e100) return '최대';
  if (amount >= 1e24) return amount.toStringAsExponential(2);
  for (final unit in [
    (1e20, '해'),
    (1e16, '경'),
    (1e12, '조'),
    (1e8, '억'),
    (1e4, '만'),
  ]) {
    if (amount >= unit.$1) {
      final value = amount / unit.$1;
      final decimals = value >= 100
          ? 0
          : value >= 10
          ? 1
          : 2;
      var formatted = value.toStringAsFixed(decimals);
      if (formatted.contains('.')) {
        formatted = formatted
            .replaceFirst(RegExp(r'0+$'), '')
            .replaceFirst(RegExp(r'\.$'), '');
      }
      return '$formatted${unit.$2}';
    }
  }
  return amount.round().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
}

String playTime(int seconds) =>
    '${(seconds ~/ 3600).toString().padLeft(2, '0')}:${(seconds ~/ 60 % 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

class PixelButton extends StatelessWidget {
  final String label;
  final String? detail;
  final VoidCallback? onPressed;
  final bool primary;
  final bool selected;
  final bool danger;
  final Widget? icon;
  const PixelButton({
    super.key,
    required this.label,
    this.detail,
    this.onPressed,
    this.primary = false,
    this.selected = false,
    this.danger = false,
    this.icon,
  });
  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final color = danger
        ? Ink.red
        : primary || selected
        ? Ink.gold
        : Ink.text;
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: primary
            ? enabled
                  ? const Color(0xff8a4a23)
                  : Ink.inset
            : selected
            ? const Color(0xff3a2d1e)
            : Ink.inset,
        child: InkWell(
          onTap: onPressed,
          mouseCursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: enabled
                    ? (primary || selected ? Ink.orange : Ink.border)
                    : Ink.border.withValues(alpha: .45),
              ),
              boxShadow: enabled && primary
                  ? [
                      const BoxShadow(
                        color: Color(0xff2c1c10),
                        offset: Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[icon!, const SizedBox(width: 6)],
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: enabled
                              ? color
                              : Ink.muted.withValues(alpha: .5),
                        ),
                      ),
                    ),
                  ],
                ),
                if (detail != null) ...[
                  const SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      detail!,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: enabled
                            ? Ink.muted
                            : Ink.muted.withValues(alpha: .5),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PixelPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const PixelPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Ink.panel,
      border: Border.all(color: Ink.border),
    ),
    child: child,
  );
}

Widget pixelImage(String path, double size) => Image.asset(
  path,
  width: size,
  height: size,
  fit: BoxFit.fill,
  filterQuality: FilterQuality.none,
  isAntiAlias: false,
);
Widget assetIcon(String name, [double size = 24]) =>
    pixelImage('assets/sword_upgrade/ui/$name.png', size);
