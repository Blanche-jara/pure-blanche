import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../theme/app_colors.dart';
import '../widgets/page_scaffold.dart';

class CodeProjectsPage extends StatelessWidget {
  const CodeProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Code Projects',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CODE PROJECTS',
            style: TextStyle(
              fontFamily: 'Segoe UI',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.52,
              color: AppColors.signalGreen,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'What I Built',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 16),
          const Text(
            '직접 만든 프로젝트들을 모아둔 공간입니다.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              height: 1.65,
              color: AppColors.parchment,
            ),
          ),
          const SizedBox(height: 48),

          // Project cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final spacing = 24.0;
              final cardWidth = isMobile
                  ? constraints.maxWidth
                  : (constraints.maxWidth - spacing) / 2;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: _projects.map((p) {
                  return SizedBox(
                    width: cardWidth,
                    child: _CodeProjectCard(
                      project: p,
                      onTap: () => Navigator.pushNamed(context, p.route),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

class _ProjectData {
  final String title;
  final String subtitle;
  final String description;
  final List<String> techTags;
  final List<String> features;
  final IconData icon;
  final String type; // "flutter" | "web"
  final String route;
  final String? downloadUrl;
  final String downloadLabel;
  final String? privacyUrl;

  const _ProjectData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.techTags,
    required this.features,
    required this.icon,
    required this.type,
    required this.route,
    this.downloadUrl,
    this.downloadLabel = 'APK',
    this.privacyUrl,
  });
}

const _projects = [
  _ProjectData(
    title: 'Jara Holdem Timer',
    subtitle: 'jara-holdem',
    description:
        '포커 토너먼트 타이머 & 매니저. 블라인드 레벨 자동 진행, 사운드 알림, '
        '커스텀 토너먼트 구조 생성/파싱, 캐시게임 모드까지 지원하는 올인원 앱.',
    techTags: ['Flutter', 'Dart', 'Provider', 'audioplayers'],
    features: [
      '블라인드 레벨 타이머 & 자동 진행',
      '토너먼트 구조 생성기 / 파서',
      '프리셋 저장 & 불러오기',
      '사운드 알림 & 브레이크 관리',
    ],
    icon: Icons.style_outlined,
    type: 'flutter',
    route: '/app/jara-holdem',
    downloadUrl: 'https://drive.google.com/file/d/1UsKiAJHPsZe6JUVeP9EOWsg511bBOVSg/view?usp=sharing',
  ),
  _ProjectData(
    title: "Who's the Nut?",
    subtitle: 'whos-the-nut',
    description:
        '포커 미니게임 모음. 커뮤니티 5장만 보고 너트 핸드 맞히기 + '
        '다인원 올인 시 메인/사이드 팟 분배 계산.',
    techTags: ['Flutter', 'Dart', 'Poker Math'],
    features: [
      '7카드 핸드 평가 엔진',
      'C(47,2) 너트 핸드 자동 탐색',
      '사이드 팟 자동 계산 & 분배',
      '청크/타이 시 odd chip 처리',
    ],
    icon: Icons.psychology_outlined,
    type: 'flutter',
    route: '/app/whos-the-nut',
    downloadUrl: 'https://drive.google.com/file/d/1SliqndoB7B_Uoyxa52ZeaueQx3krhbeW/view?usp=sharing',
    privacyUrl: 'apps/whos-the-nut/privacy.html',
  ),
  _ProjectData(
    title: '자마카세 인원뽑기',
    subtitle: 'roulette_app',
    description:
        '자마카세 이벤트 참가자를 랜덤으로 뽑는 룰렛 앱. '
        '인원 추가/삭제, 뽑기 수 조절, 스피너 애니메이션으로 결과 발표.',
    techTags: ['Flutter', 'Dart', 'Pretendard'],
    features: [
      '참가자 리스트 관리 (최대 30명)',
      '뽑기 인원 수 조절',
      '룰렛 스피너 애니메이션',
      '페이드 페이지 전환',
    ],
    icon: Icons.casino_outlined,
    type: 'flutter',
    route: '/app/roulette',
  ),
  _ProjectData(
    title: 'Jamakase Notify',
    subtitle: 'Jamakase',
    description:
        '"자라 + 오마카세" 프라이빗 디너 이벤트 알림 페이지. '
        '배경 음악, 골드 톤 다크 테마, 구글 폼 연동 참가 신청까지 원페이지로 구성.',
    techTags: ['HTML', 'Tailwind CSS', 'JavaScript', 'Audio API'],
    features: [
      '다크 테마 + 골드(#D4AF37) 악센트',
      '배경 음악 재생/토글',
      'Google Forms 참가 신청 연동',
      '네이버 지도 위치 안내',
    ],
    icon: Icons.restaurant_outlined,
    type: 'web',
    route: '/app/jamakase',
  ),
  _ProjectData(
    title: '제 25회 자라 생일 선물 리스트',
    subtitle: '251228',
    description:
        '25번째 생일 선물 목록 & 감사 페이지. '
        '다크/라이트 모드 토글, 2열 선물 리스트, 기부자 표시와 감사 메시지.',
    techTags: ['HTML', 'Tailwind CSS', 'Noto Sans KR'],
    features: [
      '다크 / 라이트 모드 토글',
      '2열 반응형 선물 리스트',
      '기부자 익명 처리',
      '핑크(#ee2b8c) 포인트 컬러',
    ],
    icon: Icons.card_giftcard_outlined,
    type: 'web',
    route: '/app/birthday',
  ),
  _ProjectData(
    title: "It's Safe Link",
    subtitle: 'safe-link',
    description:
        '본인 도메인을 통한 trustable redirector. lz-string으로 압축된 '
        'URL을 hash에 담아 정적 페이지에서 디코드 → redirect.',
    techTags: ['Flutter', 'Dart', 'lz-string', 'Static HTML'],
    features: [
      '백엔드/DB/커밋 0 (완전 정적)',
      'lz-string 압축 + hash 인코딩',
      '도착지 미리보기 후 자동 이동 (피싱 방지)',
      'http/https 스킴만 허용',
    ],
    icon: Icons.link,
    type: 'flutter',
    route: '/app/safe-link',
  ),
  _ProjectData(
    title: 'THE CANNON',
    subtitle: 'cannon',
    description:
        '주사위 테마 랜덤 추첨기. 상한 숫자를 정하면 6단위로 주사위 개수가 '
        '자동 증가하고, DRAW 버튼을 누르면 주사위가 굴러가며 결과 발표.',
    techTags: ['Flutter', 'Dart', 'Stream-friendly'],
    features: [
      '상한별 주사위 개수 자동 결정 (1D~)',
      '70ms 텀블 애니메이션 (~1.7초)',
      '거대 폰트 결과 표시 (방송 1/4 크기 대비)',
      '커스텀 페인터 주사위 + 빠른 면 전환',
    ],
    icon: Icons.casino,
    type: 'flutter',
    route: '/app/cannon',
    downloadUrl: 'https://drive.google.com/uc?export=download&id=1v_DzUDF51JRhPviEllY_UmHQzNqTP-aj',
    downloadLabel: 'EXE',
  ),
];

// ---------------------------------------------------------------------------
// Card Widget
// ---------------------------------------------------------------------------

class _CodeProjectCard extends StatefulWidget {
  final _ProjectData project;
  final VoidCallback onTap;
  const _CodeProjectCard({required this.project, required this.onTap});

  @override
  State<_CodeProjectCard> createState() => _CodeProjectCardState();
}

class _CodeProjectCardState extends State<_CodeProjectCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.project;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.carbon,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _hovered ? AppColors.signalGreen : AppColors.warmCharcoal,
            width: _hovered ? 2 : 1,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppColors.signalGreen.withValues(alpha: 0.08),
                    blurRadius: 24,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: icon + download + type badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  p.icon,
                  size: 32,
                  color: _hovered ? AppColors.signalGreen : AppColors.steel,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (p.downloadUrl != null)
                      _DownloadButton(url: p.downloadUrl!, label: p.downloadLabel),
                    if (p.downloadUrl != null) const SizedBox(width: 8),
                    _TypeBadge(type: p.type),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              p.title,
              style: const TextStyle(
                fontFamily: 'Segoe UI',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.33,
                letterSpacing: -0.6,
                color: AppColors.snow,
              ),
            ),
            const SizedBox(height: 4),

            // Subtitle (folder name)
            Text(
              p.subtitle,
              style: const TextStyle(
                fontFamily: 'Consolas',
                fontSize: 13,
                color: AppColors.steel,
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              p.description,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                height: 1.65,
                color: AppColors.parchment,
              ),
            ),
            const SizedBox(height: 20),

            // Features
            ...p.features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(
                        Icons.circle,
                        size: 5,
                        color: AppColors.signalGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        f,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.parchment,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tech tags
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: p.techTags.map((t) => _TechTag(label: t)).toList(),
            ),

            // Privacy policy slot (always reserved so all cards align)
            const SizedBox(height: 14),
            SizedBox(
              height: 16,
              child: p.privacyUrl != null
                  ? _PrivacyLink(url: p.privacyUrl!)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small widgets
// ---------------------------------------------------------------------------

class _PrivacyLink extends StatefulWidget {
  final String url;
  const _PrivacyLink({required this.url});

  @override
  State<_PrivacyLink> createState() => _PrivacyLinkState();
}

class _PrivacyLinkState extends State<_PrivacyLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => web.window.open(widget.url, '_blank'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 11,
              color: _hovered ? AppColors.signalGreen : AppColors.steel,
            ),
            const SizedBox(width: 4),
            Text(
              'Privacy Policy',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: _hovered ? AppColors.signalGreen : AppColors.steel,
                decoration: _hovered ? TextDecoration.underline : null,
                decorationColor: AppColors.signalGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadButton extends StatefulWidget {
  final String url;
  final String label;
  const _DownloadButton({required this.url, this.label = 'APK'});

  @override
  State<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<_DownloadButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => web.window.open(widget.url, '_blank'),
          borderRadius: BorderRadius.circular(6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _hovered
                  ? AppColors.signalGreen.withValues(alpha: 0.12)
                  : Colors.transparent,
              border: Border.all(
                color: _hovered
                    ? AppColors.signalGreen.withValues(alpha: 0.4)
                    : AppColors.warmCharcoal,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.download_rounded,
                  size: 14,
                  color: _hovered ? AppColors.signalGreen : AppColors.steel,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Consolas',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _hovered ? AppColors.signalGreen : AppColors.steel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final isFlutter = type == 'flutter';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isFlutter
            ? AppColors.softPurple.withValues(alpha: 0.12)
            : AppColors.signalGreen.withValues(alpha: 0.10),
        border: Border.all(
          color: isFlutter
              ? AppColors.softPurple.withValues(alpha: 0.3)
              : AppColors.signalGreen.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        isFlutter ? 'Flutter App' : 'Web',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: isFlutter ? AppColors.softPurple : AppColors.mint,
        ),
      ),
    );
  }
}

class _TechTag extends StatelessWidget {
  final String label;
  const _TechTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.abyss,
        border: Border.all(color: AppColors.warmCharcoal),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Consolas',
          fontSize: 12,
          color: AppColors.steel,
        ),
      ),
    );
  }
}
