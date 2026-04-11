import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final PageController _pageController = PageController();
  bool _scrollLocked = false;
  int _currentPage = 0;
  static const _scrollCooldown = Duration(milliseconds: 800);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    if (index < 0 || index > 1) return;
    _scrollLocked = true;
    setState(() => _currentPage = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    Future.delayed(_scrollCooldown, () {
      if (mounted) _scrollLocked = false;
    });
  }

  void _onScroll(double delta) {
    if (_scrollLocked) return;
    if (delta > 0 && _currentPage < 1) {
      _goToPage(1);
    } else if (delta < 0 && _currentPage > 0) {
      _goToPage(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: AppColors.abyss,
      body: Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            _onScroll(event.scrollDelta.dy);
          }
        },
        child: PageView(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Page 0: Hero intro
            _buildHeroPage(context, isMobile),
            // Page 1: Navigation cards + footer
            _buildCardsPage(context, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroPage(BuildContext context, bool isMobile) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Green radial glow
          Container(
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
          Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 48),
              // Scroll hint
              AnimatedOpacity(
                opacity: _currentPage == 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: () => _goToPage(1),
                  child: Column(
                    children: [
                      Text(
                        'Scroll',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.steel,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.steel,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardsPage(BuildContext context, bool isMobile) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 40,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: isMobile
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _buildCards(context, double.infinity),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildCards(context, null),
                        ),
                ),
              ),
            ),
          ),
        ),
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
        return Padding(
          padding: EdgeInsets.only(bottom: i < cards.length - 1 ? 16 : 0),
          child: card,
        );
      } else {
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
