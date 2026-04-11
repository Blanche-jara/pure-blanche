import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/youtube_player.dart';

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

class _VideoClip {
  final String title;
  final String? youtubeId; // YouTube video ID

  const _VideoClip({required this.title, this.youtubeId});

  bool get hasVideo => youtubeId != null && youtubeId!.isNotEmpty;

  /// YouTube auto-generated thumbnail (mqdefault = 320x180, middle frame)
  String get thumbnailUrl =>
      'https://img.youtube.com/vi/$youtubeId/mqdefault.jpg';

  /// High-quality thumbnail
  String get thumbnailHqUrl =>
      'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg';
}

class _Era {
  final String year;
  final String label;
  final String description;
  final _VideoClip hero;
  final List<_VideoClip> subs;

  const _Era({
    required this.year,
    required this.label,
    required this.description,
    required this.hero,
    this.subs = const [],
  });
}

const _eras = [
  _Era(
    year: '2016',
    label: '입문기',
    description: '영상 편집을 처음 시작한 시기. 기초 편집, 자막, 간단한 모션.',
    hero: _VideoClip(title: '메인 영상'),
    subs: [
      _VideoClip(title: '서브 영상 1'),
      _VideoClip(title: '서브 영상 2'),
      _VideoClip(title: '서브 영상 3'),
    ],
  ),
  _Era(
    year: '2018',
    label: '동인계',
    description: '동인계 영상 작업. 팬 무비, MAD, AMV 등 2차 창작 기반의 영상 편집을 시작한 시기.',
    hero: _VideoClip(title: '메인 영상'),
    subs: [
      _VideoClip(title: '서브 영상 1'),
      _VideoClip(title: '서브 영상 2'),
      _VideoClip(title: '서브 영상 3'),
    ],
  ),
  _Era(
    year: '2019',
    label: '게임 그래픽',
    description: '게임 그래픽 작업으로 전환. 인게임 트레일러, 모션 그래픽, UI 애니메이션 등.',
    hero: _VideoClip(title: '메인 영상'),
    subs: [
      _VideoClip(title: '서브 영상 1'),
      _VideoClip(title: '서브 영상 2'),
    ],
  ),
  _Era(
    year: '2021',
    label: '청년 작가',
    description: '청년 작가로 활동. 독립 영상, 실험 영화, 아트 필름 등 개인 창작 중심.',
    hero: _VideoClip(title: '메인 영상'),
    subs: [
      _VideoClip(title: '서브 영상 1', youtubeId: 'L1vaet56r2U'),
      _VideoClip(title: '서브 영상 2'),
      _VideoClip(title: '서브 영상 3'),
      _VideoClip(title: '서브 영상 4'),
    ],
  ),
  _Era(
    year: '2023',
    label: '지자체 외주',
    description: '지자체 영상 외주 작업. 홍보 영상, 행사 기록, 다큐멘터리 등 공공 프로젝트.',
    hero: _VideoClip(title: '메인 영상'),
    subs: [
      _VideoClip(title: '서브 영상 1'),
      _VideoClip(title: '서브 영상 2'),
      _VideoClip(title: '서브 영상 3'),
    ],
  ),
  _Era(
    year: '2025',
    label: '커미션',
    description: '과제 영상, 결혼식 영상 등 커미션 작업. 의뢰 기반의 다양한 영상 제작.',
    hero: _VideoClip(title: '메인 영상'),
    subs: [
      _VideoClip(title: '서브 영상 1'),
      _VideoClip(title: '서브 영상 2'),
    ],
  ),
  _Era(
    year: '2026',
    label: '현재',
    description: '현재 진행 중인 작업들.',
    hero: _VideoClip(title: '메인 영상'),
    subs: [
      _VideoClip(title: '서브 영상 1'),
      _VideoClip(title: '서브 영상 2'),
      _VideoClip(title: '서브 영상 3'),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class VideoProjectsPage extends StatefulWidget {
  const VideoProjectsPage({super.key});

  @override
  State<VideoProjectsPage> createState() => _VideoProjectsPageState();
}

class _VideoProjectsPageState extends State<VideoProjectsPage>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _scrollLocked = false;
  static const _scrollCooldown = Duration(milliseconds: 800);

  // Intro animation
  bool _introPlaying = true;
  late final AnimationController _introController;
  late final Animation<double> _introTimelineScale;
  late final Animation<double> _introTimelineOpacity;
  late final Animation<Alignment> _introTimelineAlign;
  late final Animation<double> _introSidebarSlide;
  late final Animation<double> _introContentFade;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // Phase 1 (0~0.45): big timeline in center
    // Phase 2 (0.45~0.75): shrink & slide to left
    // Phase 3 (0.75~1.0): content fades in

    _introTimelineOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1), weight: 80),
    ]).animate(CurvedAnimation(parent: _introController, curve: Curves.easeOut));

    _introTimelineScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.5), weight: 45),
      TweenSequenceItem(
        tween: Tween(begin: 1.5, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 25),
    ]).animate(_introController);

    _introTimelineAlign = TweenSequence<Alignment>([
      TweenSequenceItem(
          tween: ConstantTween(Alignment.center), weight: 45),
      TweenSequenceItem(
        tween: AlignmentTween(begin: Alignment.center, end: Alignment.centerLeft)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
          tween: ConstantTween(Alignment.centerLeft), weight: 25),
    ]).animate(_introController);

    _introSidebarSlide = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(-200), weight: 60),
      TweenSequenceItem(
        tween: Tween(begin: -200.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
    ]).animate(_introController);

    _introContentFade = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0), weight: 70),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_introController);

    _introController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _introPlaying = false);
      }
    });

    // Small delay then play
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _introController.forward();
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    if (index == _currentPage) return;
    _lockScroll();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _onScroll(double delta) {
    if (_scrollLocked) return;
    if (delta > 0 && _currentPage < _eras.length - 1) {
      _goToPage(_currentPage + 1);
    } else if (delta < 0 && _currentPage > 0) {
      _goToPage(_currentPage - 1);
    }
  }

  void _lockScroll() {
    _scrollLocked = true;
    Future.delayed(_scrollCooldown, () {
      if (mounted) _scrollLocked = false;
    });
  }

  void _showVideoPopup(BuildContext context, _VideoClip clip) {
    showDialog(
      context: context,
      builder: (_) => _VideoPopup(clip: clip),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Scaffold(
      backgroundColor: AppColors.abyss,
      body: AnimatedBuilder(
        animation: _introController,
        builder: (context, _) {
          if (_introPlaying && !isMobile) {
            return _buildIntroOverlay(context, isMobile);
          }
          return Column(
            children: [
              // Top bar fades in
              FadeTransition(
                opacity: _introContentFade,
                child: _buildTopBar(context, isMobile),
              ),
              Expanded(
                child: isMobile
                    ? FadeTransition(
                        opacity: _introContentFade,
                        child: _buildMobileBody(),
                      )
                    : _buildDesktopBodyWithIntro(),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Full-screen intro: big timeline in center, then shrinks to sidebar
  Widget _buildIntroOverlay(BuildContext context, bool isMobile) {
    return Stack(
      children: [
        // The big centered timeline that scales & moves
        Align(
          alignment: _introTimelineAlign.value,
          child: Opacity(
            opacity: _introTimelineOpacity.value,
            child: Transform.scale(
              scale: _introTimelineScale.value,
              child: SizedBox(
                width: 200,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_eras.length, (i) {
                    return _IntroTimelineItem(
                      era: _eras[i],
                      isFirst: i == 0,
                      isLast: i == _eras.length - 1,
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Desktop body with sidebar slide-in & content fade-in after intro
  Widget _buildDesktopBodyWithIntro() {
    return Row(
      children: [
        // Sidebar slides in from left
        Transform.translate(
          offset: Offset(_introSidebarSlide.value, 0),
          child: Container(
            width: 200,
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.warmCharcoal)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Expanded(
                  child: _TimelineRail(
                    eras: _eras,
                    activeIndex: _currentPage,
                    onTap: _goToPage,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        // Content fades in
        Expanded(
          child: FadeTransition(
            opacity: _introContentFade,
            child: Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  _onScroll(event.scrollDelta.dy);
                }
              },
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _eras.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) => _EraPage(
                  era: _eras[i],
                  onSubTap: (clip) => _showVideoPopup(context, clip),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 16,
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
          const Text(
            'Video Works',
            style: TextStyle(
              fontFamily: 'Segoe UI',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: AppColors.snow,
            ),
          ),
          const Spacer(),
          // Current era indicator
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              '${_eras[_currentPage].year} — ${_eras[_currentPage].label}',
              key: ValueKey(_currentPage),
              style: const TextStyle(
                fontFamily: 'Consolas',
                fontSize: 13,
                color: AppColors.signalGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Mobile: no sidebar, vertical PageView ----

  Widget _buildMobileBody() {
    return Stack(
      children: [
        Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              _onScroll(event.scrollDelta.dy);
            }
          },
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _eras.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, i) => _EraPage(
              era: _eras[i],
              isMobile: true,
              onSubTap: (clip) => _showVideoPopup(context, clip),
            ),
          ),
        ),
        // Floating page dots
        Positioned(
          left: 12,
          top: 0,
          bottom: 0,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_eras.length, (i) {
                final isActive = i == _currentPage;
                return GestureDetector(
                  onTap: () => _goToPage(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isActive ? 10 : 6,
                    height: isActive ? 10 : 6,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? AppColors.signalGreen : AppColors.warmCharcoal,
                      boxShadow: isActive
                          ? [BoxShadow(color: AppColors.signalGreen.withValues(alpha: 0.5), blurRadius: 8)]
                          : null,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline Rail (desktop sidebar)
// ---------------------------------------------------------------------------

class _TimelineRail extends StatelessWidget {
  final List<_Era> eras;
  final int activeIndex;
  final ValueChanged<int> onTap;

  const _TimelineRail({
    required this.eras,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(eras.length, (i) {
            final era = eras[i];
            final isActive = i == activeIndex;
            return _TimelineNodeDesktop(
              era: era,
              isActive: isActive,
              isFirst: i == 0,
              isLast: i == eras.length - 1,
              onTap: () => onTap(i),
            );
          }),
        );
      },
    );
  }
}

class _TimelineNodeDesktop extends StatefulWidget {
  final _Era era;
  final bool isActive;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _TimelineNodeDesktop({
    required this.era,
    required this.isActive,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  @override
  State<_TimelineNodeDesktop> createState() => _TimelineNodeDesktopState();
}

class _TimelineNodeDesktopState extends State<_TimelineNodeDesktop> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          height: 80,
          child: Row(
            children: [
              const SizedBox(width: 28),
              // Vertical line + dot
              SizedBox(
                width: 20,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: widget.isFirst ? 0 : 1,
                        color: AppColors.warmCharcoal,
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: widget.isActive ? 14 : 8,
                      height: widget.isActive ? 14 : 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isActive
                            ? AppColors.signalGreen
                            : (_hovered ? AppColors.steel : AppColors.carbon),
                        border: Border.all(
                          color: widget.isActive || _hovered
                              ? AppColors.signalGreen
                              : AppColors.warmCharcoal,
                          width: 2,
                        ),
                        boxShadow: widget.isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.signalGreen.withValues(alpha: 0.5),
                                  blurRadius: 12,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: widget.isLast ? 0 : 1,
                        color: AppColors.warmCharcoal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Label
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 18,
                        fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w400,
                        color: widget.isActive
                            ? AppColors.signalGreen
                            : (_hovered ? AppColors.snow : AppColors.steel),
                      ),
                      child: Text(widget.era.year),
                    ),
                    const SizedBox(height: 2),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: widget.isActive
                            ? AppColors.parchment
                            : AppColors.warmCharcoal,
                      ),
                      child: Text(widget.era.label),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Era Page (one full-screen section)
// ---------------------------------------------------------------------------

class _EraPage extends StatelessWidget {
  final _Era era;
  final bool isMobile;
  final ValueChanged<_VideoClip> onSubTap;

  const _EraPage({
    required this.era,
    this.isMobile = false,
    required this.onSubTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Era header
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                era.year,
                style: TextStyle(
                  fontFamily: 'Segoe UI',
                  fontSize: isMobile ? 36 : 48,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                  letterSpacing: -0.65,
                  color: AppColors.signalGreen,
                  shadows: [
                    Shadow(
                      color: AppColors.signalGreen.withValues(alpha: 0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  era.label,
                  style: TextStyle(
                    fontFamily: 'Segoe UI',
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w700,
                    height: 1.33,
                    letterSpacing: -0.6,
                    color: AppColors.snow,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            era.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              height: 1.6,
              color: AppColors.parchment,
            ),
          ),
          const SizedBox(height: 24),

          // Hero video (large)
          Expanded(
            flex: 3,
            child: _HeroVideo(clip: era.hero),
          ),
          const SizedBox(height: 16),

          // Sub videos with pagination arrows
          if (era.subs.isNotEmpty)
            SizedBox(
              height: isMobile ? 100 : 120,
              child: _SubVideoStrip(
                subs: era.subs,
                isMobile: isMobile,
                onTap: onSubTap,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero Video (big, auto-play placeholder)
// ---------------------------------------------------------------------------

class _HeroVideo extends StatefulWidget {
  final _VideoClip clip;
  const _HeroVideo({required this.clip});

  @override
  State<_HeroVideo> createState() => _HeroVideoState();
}

class _HeroVideoState extends State<_HeroVideo> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    // If youtubeId exists, show embedded player
    if (widget.clip.hasVideo) {
      return Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.carbon,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.warmCharcoal),
        ),
        child: YoutubePlayer(
          youtubeId: widget.clip.youtubeId!,
          autoplay: true,
        ),
      );
    }

    // Placeholder when no video
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.carbon,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _hovered ? AppColors.signalGreen : AppColors.warmCharcoal,
            width: _hovered ? 2 : 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.abyss,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.videocam_off_outlined,
                  size: 48,
                  color: _hovered ? AppColors.signalGreen : AppColors.warmCharcoal,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Google Drive ID를 추가하세요',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.steel,
                  ),
                ),
              ],
            ),
            // Title overlay
            Positioned(
              left: 20,
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.carbon.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.warmCharcoal),
                ),
                child: Text(
                  widget.clip.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.snow,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub Video Strip (horizontal list with arrow pagination)
// ---------------------------------------------------------------------------

class _SubVideoStrip extends StatefulWidget {
  final List<_VideoClip> subs;
  final bool isMobile;
  final ValueChanged<_VideoClip> onTap;

  const _SubVideoStrip({
    required this.subs,
    required this.isMobile,
    required this.onTap,
  });

  @override
  State<_SubVideoStrip> createState() => _SubVideoStripState();
}

class _SubVideoStripState extends State<_SubVideoStrip> {
  final ScrollController _controller = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateArrows() {
    if (!_controller.hasClients) return;
    setState(() {
      _canScrollLeft = _controller.offset > 8;
      _canScrollRight =
          _controller.offset < _controller.position.maxScrollExtent - 8;
    });
  }

  void _scrollBy(double delta) {
    _controller.animateTo(
      (_controller.offset + delta).clamp(
        0.0,
        _controller.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = widget.isMobile ? 150.0 : 180.0;

    return Stack(
      children: [
        ListView.separated(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 36),
          itemCount: widget.subs.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, i) => _SubVideoCard(
            clip: widget.subs[i],
            width: cardWidth,
            onTap: () => widget.onTap(widget.subs[i]),
          ),
        ),
        // Left arrow
        if (_canScrollLeft)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: _ArrowButton(
                icon: Icons.chevron_left,
                onTap: () => _scrollBy(-(cardWidth + 12) * 2),
              ),
            ),
          ),
        // Right arrow
        if (_canScrollRight)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: _ArrowButton(
                icon: Icons.chevron_right,
                onTap: () => _scrollBy((cardWidth + 12) * 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _ArrowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowButton({required this.icon, required this.onTap});

  @override
  State<_ArrowButton> createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<_ArrowButton> {
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.carbon
                : AppColors.carbon.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            border: Border.all(
              color: _hovered ? AppColors.signalGreen : AppColors.warmCharcoal,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: _hovered ? AppColors.signalGreen : AppColors.fog,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub Video Card (small, clickable)
// ---------------------------------------------------------------------------

class _SubVideoCard extends StatefulWidget {
  final _VideoClip clip;
  final double width;
  final VoidCallback onTap;

  const _SubVideoCard({
    required this.clip,
    required this.width,
    required this.onTap,
  });

  @override
  State<_SubVideoCard> createState() => _SubVideoCardState();
}

class _SubVideoCardState extends State<_SubVideoCard> {
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
          width: widget.width,
          decoration: BoxDecoration(
            color: AppColors.carbon,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _hovered ? AppColors.signalGreen : AppColors.warmCharcoal,
            ),
          ),
          child: Column(
            children: [
              // Thumbnail
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.abyss,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                        image: widget.clip.hasVideo
                            ? DecorationImage(
                                image: NetworkImage(
                                  widget.clip.thumbnailUrl,
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                    ),
                    // Play overlay
                    Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _hovered
                              ? AppColors.carbon.withValues(alpha: 0.85)
                              : AppColors.carbon.withValues(alpha: 0.6),
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: 20,
                          color: _hovered ? AppColors.signalGreen : AppColors.snow,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Text(
                  widget.clip.title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _hovered ? AppColors.snow : AppColors.steel,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Video Popup (modal player)
// ---------------------------------------------------------------------------

class _VideoPopup extends StatelessWidget {
  final _VideoClip clip;
  const _VideoPopup({required this.clip});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 600),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.carbon,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warmCharcoal),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 60,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.warmCharcoal),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.play_circle, size: 18, color: AppColors.signalGreen),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        clip.title,
                        style: const TextStyle(
                          fontFamily: 'Segoe UI',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.snow,
                        ),
                      ),
                    ),
                    _CloseButton(onTap: () => Navigator.of(context).pop()),
                  ],
                ),
              ),
              // Player area
              Expanded(
                child: clip.hasVideo
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(7)),
                        child: YoutubePlayer(youtubeId: clip.youtubeId!),
                      )
                    : Container(
                        width: double.infinity,
                        color: AppColors.abyss,
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.videocam_off_outlined,
                                  size: 48, color: AppColors.warmCharcoal),
                              SizedBox(height: 12),
                              Text(
                                'Google Drive ID를 추가하세요',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: AppColors.steel,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Intro timeline item (centered, large)
// ---------------------------------------------------------------------------

class _IntroTimelineItem extends StatelessWidget {
  final _Era era;
  final bool isFirst;
  final bool isLast;

  const _IntroTimelineItem({
    required this.era,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          const SizedBox(width: 28),
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: isFirst ? 0 : 1,
                    color: AppColors.warmCharcoal,
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.signalGreen,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.signalGreen.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: isLast ? 0 : 1,
                    color: AppColors.warmCharcoal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  era.year,
                  style: const TextStyle(
                    fontFamily: 'Consolas',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.signalGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  era.label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.parchment,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Common small widgets
// ---------------------------------------------------------------------------

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

class _CloseButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Icon(
          Icons.close,
          size: 20,
          color: _hovered ? AppColors.snow : AppColors.steel,
        ),
      ),
    );
  }
}
