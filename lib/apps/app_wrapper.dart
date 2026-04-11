import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Wraps a sub-app (jara-holdem, roulette) in a page with a back button bar.
class AppWrapper extends StatelessWidget {
  final String title;
  final Widget child;

  const AppWrapper({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.width > size.height && size.height < 500;

    return Scaffold(
      backgroundColor: AppColors.abyss,
      body: Column(
        children: [
          // Top bar
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 16,
              vertical: isCompact ? 6 : 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.abyss.withValues(alpha: 0.92),
              border: const Border(
                bottom: BorderSide(color: AppColors.warmCharcoal),
              ),
            ),
            child: Row(
              children: [
                _BackButton(onTap: () => Navigator.of(context).pop()),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Segoe UI',
                    fontSize: isCompact ? 14 : 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: AppColors.snow,
                  ),
                ),
              ],
            ),
          ),
          // Sub-app fills remaining space
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _BackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: _hovered ? AppColors.signalGreen : AppColors.warmCharcoal,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.arrow_back,
            size: 18,
            color: _hovered ? AppColors.signalGreen : AppColors.fog,
          ),
        ),
      ),
    );
  }
}
