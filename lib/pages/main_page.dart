import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: AppColors.abyss,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero area
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 40,
                vertical: isMobile ? 80 : 140,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Green radial glow
                  Center(
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
                  Column(
                    children: [
                      // Logo
                      Image.asset(
                        'assets/Blanche_Logo.png',
                        width: 48,
                        height: 48,
                      ),
                      const SizedBox(height: 24),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: "Hi, I'm "),
                            TextSpan(
                              text: 'Blanche',
                              style: TextStyle(
                                color: AppColors.signalGreen,
                                shadows: [
                                  Shadow(
                                    color: AppColors.signalGreen
                                        .withValues(alpha: 0.3),
                                    blurRadius: 40,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(fontSize: isMobile ? 36 : 60),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Developer & Creator',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: isMobile ? 16 : 18,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3 Navigation Cards
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 40,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: isMobile
                      ? Column(
                          children: _buildCards(context, double.infinity),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildCards(context, null),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 120),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.warmCharcoal),
                ),
              ),
              child: const Text(
                '© 2026 Blanche. All rights reserved.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.steel,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCards(BuildContext context, double? fixedWidth) {
    final cards = [
      _NavCardData(
        icon: Icons.code,
        label: '01',
        title: 'Code Projects',
        description: '코딩으로 만든 프로젝트들',
        route: '/code',
      ),
      _NavCardData(
        icon: Icons.videocam_outlined,
        label: '02',
        title: 'Video Works',
        description: '영상으로 만든 작업들',
        route: '/video',
      ),
      _NavCardData(
        icon: Icons.chat_bubble_outline,
        label: '03',
        title: 'Guestbook',
        description: '방명록 & 문의',
        route: '/guestbook',
      ),
    ];

    return cards.asMap().entries.map((entry) {
      final i = entry.key;
      final data = entry.value;
      final card = _NavigationCard(
        data: data,
        onTap: () => Navigator.pushNamed(context, data.route),
      );

      if (fixedWidth != null) {
        // Mobile: full width, vertical gap
        return Padding(
          padding: EdgeInsets.only(bottom: i < cards.length - 1 ? 16 : 0),
          child: card,
        );
      } else {
        // Desktop: flex row with gap
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: i > 0 ? 12 : 0,
              right: i < cards.length - 1 ? 12 : 0,
            ),
            child: card,
          ),
        );
      }
    }).toList();
  }
}

class _NavCardData {
  final IconData icon;
  final String label;
  final String title;
  final String description;
  final String route;

  const _NavCardData({
    required this.icon,
    required this.label,
    required this.title,
    required this.description,
    required this.route,
  });
}

class _NavigationCard extends StatefulWidget {
  final _NavCardData data;
  final VoidCallback onTap;

  const _NavigationCard({required this.data, required this.onTap});

  @override
  State<_NavigationCard> createState() => _NavigationCardState();
}

class _NavigationCardState extends State<_NavigationCard> {
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
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.carbon,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  _hovered ? AppColors.signalGreen : AppColors.warmCharcoal,
              width: _hovered ? 2 : 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.signalGreen.withValues(alpha: 0.1),
                      blurRadius: 24,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    widget.data.icon,
                    size: 28,
                    color: _hovered
                        ? AppColors.signalGreen
                        : AppColors.steel,
                  ),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.52,
                      color: _hovered
                          ? AppColors.signalGreen
                          : AppColors.warmCharcoal,
                    ),
                    child: Text(widget.data.label),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                widget.data.title,
                style: const TextStyle(
                  fontFamily: 'Segoe UI',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.33,
                  letterSpacing: -0.6,
                  color: AppColors.snow,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.data.description,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.parchment,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _hovered
                          ? AppColors.mint
                          : AppColors.fog,
                    ),
                    child: const Text('View more'),
                  ),
                  const SizedBox(width: 6),
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 200),
                    offset: _hovered
                        ? const Offset(0.15, 0)
                        : Offset.zero,
                    child: Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: _hovered
                          ? AppColors.mint
                          : AppColors.fog,
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
