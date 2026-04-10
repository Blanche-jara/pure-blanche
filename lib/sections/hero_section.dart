import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 80 : 120,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Green radial glow behind hero
          Positioned.fill(
            child: Center(
              child: Container(
                width: 600,
                height: 600,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.signalGreen.withValues(alpha: 0.12),
                      AppColors.emerald.withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.4, 0.7],
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: "Hi, I'm "),
                    TextSpan(
                      text: 'Blanche',
                      style: theme.displayLarge?.copyWith(
                        color: AppColors.signalGreen,
                        shadows: [
                          Shadow(
                            color:
                                AppColors.signalGreen.withValues(alpha: 0.3),
                            blurRadius: 40,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                style: theme.displayLarge?.copyWith(
                  fontSize: isMobile ? 36 : 60,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Text(
                  'Developer & Creator building things with code.\nPassionate about Flutter, Web, and creative projects.',
                  style: theme.bodyLarge?.copyWith(
                    fontSize: isMobile ? 16 : 18,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _HeroButton(
                    label: 'View Projects',
                    isPrimary: true,
                    onTap: () {},
                  ),
                  _HeroButton(
                    label: 'Contact Me',
                    isPrimary: false,
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _HeroButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_HeroButton> createState() => _HeroButtonState();
}

class _HeroButtonState extends State<_HeroButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? (_hovered
                    ? AppColors.carbon.withValues(alpha: 0.8)
                    : AppColors.carbon)
                : (_hovered
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.transparent),
            border: Border.all(color: AppColors.warmCharcoal),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: widget.isPrimary ? AppColors.mint : AppColors.snow,
            ),
          ),
        ),
      ),
    );
  }
}
