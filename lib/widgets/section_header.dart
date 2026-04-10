import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SectionHeader extends StatelessWidget {
  final String label;
  final String title;

  const SectionHeader({
    super.key,
    required this.label,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.labelLarge,
        ),
        const SizedBox(height: 12),
        Text(title, style: theme.displayMedium),
      ],
    );
  }
}

class GlowingCard extends StatefulWidget {
  final Widget child;
  final bool accent;

  const GlowingCard({super.key, required this.child, this.accent = false});

  @override
  State<GlowingCard> createState() => _GlowingCardState();
}

class _GlowingCardState extends State<GlowingCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.carbon,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.accent || _hovered
                ? AppColors.signalGreen
                : AppColors.warmCharcoal,
            width: widget.accent || _hovered ? 2 : 1,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppColors.signalGreen.withValues(alpha: 0.1),
                    blurRadius: 20,
                  ),
                ]
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}
