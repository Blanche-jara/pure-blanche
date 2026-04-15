import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;
import '../theme/app_colors.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  // ── Page snap ──
  final PageController _pageController = PageController();
  bool _scrollLocked = false;
  int _currentPage = 0;
  static const _scrollCooldown = Duration(milliseconds: 800);

  // ── Intro state ──
  bool _introActive = false; // video overlay visible
  bool _videoFadingOut = false; // video fading out
  double _mainOpacity = 1.0; // main content opacity

  // ── Video ──
  static const _videoViewType = 'intro-video-player';
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _checkFirstVisit();
  }

  void _checkFirstVisit() {
    final storage = web.window.sessionStorage;
    final visited = storage.getItem('intro_played');

    if (visited == null) {
      storage.setItem('intro_played', '1');
      _registerVideoView();
      setState(() {
        _introActive = true;
        _mainOpacity = 0.0;
      });
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
            _finishIntro();
          }.toJS,
        );

        return video;
      },
    );
  }

  void _finishIntro() {
    if (!mounted || !_introActive) return;
    // Phase 1: fade out video
    setState(() => _videoFadingOut = true);
    // Phase 2: after video gone, fade in main
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _introActive = false;
        _videoFadingOut = false;
        _mainOpacity = 1.0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
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
    if (_scrollLocked || _introActive) return;
    if (delta > 0 && _currentPage < 1) {
      _goToPage(1);
    } else if (delta < 0 && _currentPage > 0) {
      _goToPage(0);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (_introActive &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _finishIntro();
      return KeyEventResult.handled;
    }
    // Block all other input during intro
    if (_introActive) return KeyEventResult.handled;
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: AppColors.abyss,
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Stack(
          children: [
            // Main content with fade-in
            IgnorePointer(
              ignoring: _introActive,
              child: AnimatedOpacity(
                opacity: _mainOpacity,
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOut,
                child: Listener(
                  onPointerSignal: (event) {
                    if (event is PointerScrollEvent) {
                      _onScroll(event.scrollDelta.dy);
                    }
                  },
                  child: PageView(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    physics: isMobile
                        ? const PageScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) =>
                        setState(() => _currentPage = i),
                    children: [
                      _buildHeroPage(context, isMobile),
                      _buildCardsPage(context, isMobile),
                    ],
                  ),
                ),
              ),
            ),

            // Video overlay
            if (_introActive)
              AnimatedOpacity(
                opacity: _videoFadingOut ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 800),
                child: const SizedBox.expand(
                  child: HtmlElementView(viewType: _videoViewType),
                ),
              ),
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
              AnimatedOpacity(
                opacity: _currentPage == 0 && !_introActive ? 1.0 : 0.0,
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
          child: isMobile
              ? SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _buildCards(context, double.infinity, true),
                  ),
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildCards(context, null, false),
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

  List<Widget> _buildCards(
      BuildContext context, double? fixedWidth, bool compact) {
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
        compact: compact,
        onTap: () => Navigator.pushNamed(context, data.route),
      );

      if (fixedWidth != null) {
        return Padding(
          padding: EdgeInsets.only(bottom: i < cards.length - 1 ? 12 : 0),
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
  final bool compact;

  const _NavigationCard({
    required this.data,
    required this.onTap,
    this.compact = false,
  });

  @override
  State<_NavigationCard> createState() => _NavigationCardState();
}

class _NavigationCardState extends State<_NavigationCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final pad = compact ? 20.0 : 32.0;
    final iconSize = compact ? 24.0 : 28.0;
    final titleSize = compact ? 20.0 : 24.0;
    final descSize = compact ? 14.0 : 15.0;
    final gapL = compact ? 16.0 : 24.0;
    final gapS = compact ? 6.0 : 8.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.all(pad),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    widget.data.icon,
                    size: iconSize,
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
              SizedBox(height: gapL),
              Text(
                widget.data.title,
                style: TextStyle(
                  fontFamily: 'Segoe UI',
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  height: 1.33,
                  letterSpacing: -0.6,
                  color: AppColors.snow,
                ),
              ),
              SizedBox(height: gapS),
              Text(
                widget.data.description,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: descSize,
                  height: 1.6,
                  color: AppColors.parchment,
                ),
              ),
              SizedBox(height: gapL),
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
