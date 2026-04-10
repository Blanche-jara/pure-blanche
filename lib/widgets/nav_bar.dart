import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NavBar extends StatelessWidget {
  final Function(String) onNavigate;

  const NavBar({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.abyss.withValues(alpha: 0.92),
        border: const Border(
          bottom: BorderSide(color: AppColors.warmCharcoal, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Brand
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '⚡',
                style: TextStyle(
                  fontSize: 20,
                  shadows: [
                    Shadow(
                      color: AppColors.signalGreen.withValues(alpha: 0.8),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Blanche',
                style: TextStyle(
                  fontFamily: 'Segoe UI',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  color: AppColors.snow,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (!isMobile) ...[
            _NavLink(label: 'About', onTap: () => onNavigate('about')),
            const SizedBox(width: 32),
            _NavLink(label: 'Projects', onTap: () => onNavigate('projects')),
            const SizedBox(width: 32),
            _NavLink(label: 'Contact', onTap: () => onNavigate('contact')),
          ],
        ],
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _NavLink({required this.label, required this.onTap});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _hovered ? AppColors.signalGreen : AppColors.fog,
          ),
          child: Text(widget.label),
        ),
      ),
    );
  }
}
