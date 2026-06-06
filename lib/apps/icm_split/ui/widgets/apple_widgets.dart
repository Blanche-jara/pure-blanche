import 'package:flutter/material.dart';

import '../design_tokens.dart';

/// iOS 설정앱식 inset-grouped 섹션.
///
/// 위에 muted 캡션 헤더, 아래 흰색 라운드 카드 안에 [rows]를 헤어라인으로 구분해 쌓는다.
class AppleGroup extends StatelessWidget {
  const AppleGroup({
    super.key,
    this.header,
    this.headerTrailing,
    required this.rows,
  });

  final String? header;
  final Widget? headerTrailing;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i < rows.length - 1) {
        children.add(const Divider(height: 1, indent: 16, endIndent: 16));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 18, 6, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    header!,
                    style: t.textTheme.labelMedium?.copyWith(
                      color: t.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ?headerTrailing,
              ],
            ),
          ),
        Card(
          margin: const EdgeInsets.only(bottom: 4),
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// 그룹 내 한 행: 왼쪽 라벨/리딩, 오른쪽 값(또는 [trailing]). iOS 행 높이·패딩.
class AppleRow extends StatelessWidget {
  const AppleRow({
    super.key,
    required this.label,
    this.value,
    this.secondary,
    this.trailing,
    this.leading,
    this.onTap,
    this.dense = false,
  });

  final String label;

  /// 오른쪽 큰 값(굵게).
  final String? value;

  /// 값 아래 보조 텍스트(muted).
  final String? secondary;

  /// 값 대신 커스텀 trailing 위젯.
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final right =
        trailing ??
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != null)
              Text(
                value!,
                style: t.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (secondary != null)
              Text(
                secondary!,
                style: t.textTheme.bodySmall?.copyWith(
                  color: t.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        );

    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: dense ? 10 : 14),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(child: Text(label, style: t.textTheme.bodyLarge)),
          const SizedBox(width: 12),
          Flexible(
            child: Align(alignment: Alignment.centerRight, child: right),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}

/// 텍스트 입력 다이얼로그. 컨트롤러를 내부 State가 소유·해제해
/// "controller used after disposed" 류 lifecycle 버그를 막는다. 취소 시 null 반환.
Future<String?> showTextPrompt(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initial = '',
  String? label,
  String? hint,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _TextPromptDialog(
      title: title,
      confirmLabel: confirmLabel,
      initial: initial,
      label: label,
      hint: hint,
    ),
  );
}

class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.confirmLabel,
    required this.initial,
    this.label,
    this.hint,
  });
  final String title;
  final String confirmLabel;
  final String initial;
  final String? label;
  final String? hint;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

/// 카지노 칩 도트 — 플레이어 식별색. 흰 링으로 어두운 칩도 또렷하게(칩 테두리 느낌).
class ChipDot extends StatelessWidget {
  const ChipDot(this.color, {super.key, this.size = 16});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: size * 0.14,
        ),
      ),
    );
  }
}

/// 화면 상단 대형 타이틀 + 선택적 서브타이틀.
class AppleLargeTitle extends StatelessWidget {
  const AppleLargeTitle({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, AppSpacing.xs, 6, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.textTheme.headlineMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: t.textTheme.bodyMedium?.copyWith(
                color: t.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 그림자 없는 강조 패널(섹션 헤더가 필요 없는 차트/요약용 카드).
class ApplePanel extends StatelessWidget {
  const ApplePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: padding, child: child),
    );
  }
}
