import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../theme/app_colors.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  // ── Page snap ──
  final PageController _pageController = PageController();
  bool _scrollLocked = false;
  int _currentPage = 0;
  static const _scrollCooldown = Duration(milliseconds: 800);

  // ── Intro state ──
  bool _showIntro = false;
  bool _videoPlaying = false;
  bool _videoFadingOut = false;
  bool _heroAnimating = false;
  bool _introDone = false;

  // ── Hero stagger animations ──
  late AnimationController _heroStaggerController;
  late Animation<double> _glowFade;
  late Animation<Offset> _glowSlide;
  late Animation<double> _logoFade;
  late Animation<Offset> _logoSlide;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleFade;
  late Animation<Offset> _subtitleSlide;

  // ── Video element ──
  static const _videoViewType = 'intro-video-player';

  @override
  void initState() {
    super.initState();
    _setupHeroAnimations();
    _checkFirstVisit();
  }

  void _setupHeroAnimations() {
    _heroStaggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // 1. Glow: 0.0 ~ 0.3
    _glowFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroStaggerController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    _glowSlide = Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _heroStaggerController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    // 2. Logo: 0.15 ~ 0.45
    _logoFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroStaggerController,
        curve: const Interval(0.15, 0.45, curve: Curves.easeOut),
      ),
    );
    _logoSlide = Tween(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _heroStaggerController,
        curve: const Interval(0.15, 0.45, curve: Curves.easeOut),
      ),
    );

    // 3. Title: 0.3 ~ 0.65
    _titleFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroStaggerController,
        curve: const Interval(0.3, 0.65, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _heroStaggerController,
        curve: const Interval(0.3, 0.65, curve: Curves.easeOut),
      ),
    );

    // 4. Subtitle + scroll: 0.5 ~ 0.85
    _subtitleFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroStaggerController,
        curve: const Interval(0.5, 0.85, curve: Curves.easeOut),
      ),
    );
    _subtitleSlide =
        Tween(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _heroStaggerController,
        curve: const Interval(0.5, 0.85, curve: Curves.easeOut),
      ),
    );

    _heroStaggerController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _introDone = true);
      }
    });
  }

  void _checkFirstVisit() {
    final storage = web.window.sessionStorage;
    final visited = storage.getItem('intro_played');

    if (visited == null) {
      // First visit this session → play intro
      storage.setItem('intro_played', '1');
      _registerVideoView();
      setState(() {
        _showIntro = true;
        _videoPlaying = true;
      });
    } else {
      // Already visited → skip intro, show hero directly
      setState(() => _introDone = true);
      _heroStaggerController.value = 1.0;
    }
  }

  void _registerVideoView() {
    ui_web.platformViewRegistry.registerViewFactory(
      _videoViewType,
      (int viewId) {
        final video =
            web.document.createElement('video') as web.HTMLVideoElement;
        video.src = 'assets/Blanche_Animation.mp4';
        video.autoplay = true;
        video.muted = true;
        video.playsInline = true;
        video.style.width = '100%';
        video.style.height = '100%';
        video.style.objectFit = 'cover';
        video.style.backgroundColor = '#050507';

        video.addEventListener(
          'ended',
          (web.Event e) {
            _onVideoEnded();
          }.toJS,
        );

        return video;
      },
    );
  }

  void _onVideoEnded() {
    if (!mounted) return;
    // Fade out video
    setState(() {
      _videoFadingOut = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _videoPlaying = false;
        _videoFadingOut = false;
        _heroAnimating = true;
      });
      // Start hero stagger animation
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _heroStaggerController.forward();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heroStaggerController.dispose();
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
    if (_scrollLocked || !_introDone) return;
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
      body: Stack(
        children: [
          // Main content (always mounted)
          Listener(
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
                _buildHeroPage(context, isMobile),
                _buildCardsPage(context, isMobile),
              ],
            ),
          ),

          // Video overlay (intro)
          if (_showIntro && _videoPlaying)
            AnimatedOpacity(
              opacity: _videoFadingOut ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 800),
              child: const SizedBox.expand(
                child: HtmlElementView(viewType: _videoViewType),
              ),
            ),

          // Black overlay during hero stagger (covers until animation starts)
          if (_showIntro && _heroAnimating && !_introDone)
            const SizedBox.expand(
              child: ColoredBox(color: AppColors.abyss),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroPage(BuildContext context, bool isMobile) {
    // If intro hasn't played or is done, show static
    final bool animate = _showIntro && !_introDone;

    return Center(
      child: AnimatedBuilder(
        animation: _heroStaggerController,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Green radial glow
              SlideTransition(
                position: animate ? _glowSlide : _alwaysZero,
                child: Opacity(
                  opacity: animate ? _glowFade.value : 1.0,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  SlideTransition(
                    position: animate ? _logoSlide : _alwaysZero,
                    child: Opacity(
                      opacity: animate ? _logoFade.value : 1.0,
                      child: Image.asset(
                        'assets/Blanche_Logo.png',
                        width: 48,
                        height: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  SlideTransition(
                    position: animate ? _titleSlide : _alwaysZero,
                    child: Opacity(
                      opacity: animate ? _titleFade.value : 1.0,
                      child: Text.rich(
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
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Subtitle + Scroll
                  SlideTransition(
                    position: animate ? _subtitleSlide : _alwaysZero,
                    child: Opacity(
                      opacity: animate ? _subtitleFade.value : 1.0,
                      child: Column(
                        children: [
                          Text(
                            'Developer & Creator',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontSize: isMobile ? 16 : 18,
                                    ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),
                          AnimatedOpacity(
                            opacity: _currentPage == 0 && _introDone ? 1.0 : 0.0,
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
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static final _alwaysZero = ConstantTween(Offset.zero).animate(
    kAlwaysCompleteAnimation,
  );

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
