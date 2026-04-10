import 'package:flutter/material.dart';
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
          // Section header
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
            'ex-work 폴더의 프로젝트들이 여기에 표시됩니다.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              height: 1.65,
              color: AppColors.parchment,
            ),
          ),
          const SizedBox(height: 48),

          // Placeholder cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final crossCount = isMobile ? 1 : 2;
              final spacing = 24.0;
              final cardWidth = isMobile
                  ? constraints.maxWidth
                  : (constraints.maxWidth - spacing) / crossCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: _placeholderProjects.map((p) {
                  return SizedBox(
                    width: cardWidth,
                    child: _CodeProjectCard(project: p),
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

class _ProjectData {
  final String title;
  final String description;
  final String tech;
  final IconData icon;

  const _ProjectData({
    required this.title,
    required this.description,
    required this.tech,
    required this.icon,
  });
}

const _placeholderProjects = [
  _ProjectData(
    title: 'Roulette App',
    description: 'Flutter 기반 룰렛 애플리케이션. 부드러운 애니메이션과 인터랙티브 게임플레이.',
    tech: 'Flutter · Dart',
    icon: Icons.casino_outlined,
  ),
  _ProjectData(
    title: 'Jara Holdem',
    description: '텍사스 홀덤 포커 게임. 실시간 멀티플레이어 메커니즘 구현.',
    tech: 'Flutter · Dart',
    icon: Icons.style_outlined,
  ),
  _ProjectData(
    title: 'Jamakase',
    description: '몰입감 있는 웹 경험. 오디오-비주얼 프레젠테이션과 크리에이티브 인터랙션.',
    tech: 'HTML · CSS · JS',
    icon: Icons.music_note_outlined,
  ),
];

class _CodeProjectCard extends StatefulWidget {
  final _ProjectData project;
  const _CodeProjectCard({required this.project});

  @override
  State<_CodeProjectCard> createState() => _CodeProjectCardState();
}

class _CodeProjectCardState extends State<_CodeProjectCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
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
            Icon(
              widget.project.icon,
              size: 32,
              color: _hovered ? AppColors.signalGreen : AppColors.steel,
            ),
            const SizedBox(height: 20),
            Text(
              widget.project.title,
              style: const TextStyle(
                fontFamily: 'Segoe UI',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1.33,
                letterSpacing: -0.6,
                color: AppColors.snow,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.project.description,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                height: 1.63,
                color: AppColors.parchment,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.warmCharcoal.withValues(alpha: 0.6),
                ),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                widget.project.tech,
                style: const TextStyle(
                  fontFamily: 'Consolas',
                  fontSize: 12,
                  color: AppColors.steel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
