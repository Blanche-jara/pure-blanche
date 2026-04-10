import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/page_scaffold.dart';

class VideoProjectsPage extends StatelessWidget {
  const VideoProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Video Works',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VIDEO WORKS',
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
            'What I Created',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 16),
          const Text(
            '영상 링크를 추가하면 격자 형태로 표시됩니다.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              height: 1.65,
              color: AppColors.parchment,
            ),
          ),
          const SizedBox(height: 48),

          // Grid of video placeholders
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final isTablet = constraints.maxWidth < 900;
              final crossCount = isMobile ? 1 : (isTablet ? 2 : 3);
              final spacing = 20.0;
              final cardWidth =
                  (constraints.maxWidth - spacing * (crossCount - 1)) /
                      crossCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(6, (i) {
                  return SizedBox(
                    width: cardWidth,
                    child: _VideoCard(index: i + 1),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatefulWidget {
  final int index;
  const _VideoCard({required this.index});

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
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
            // Thumbnail placeholder (16:9 ratio)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.abyss,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(7)),
                ),
                child: Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    size: 48,
                    color: _hovered
                        ? AppColors.signalGreen
                        : AppColors.warmCharcoal,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Video #${widget.index}',
                    style: const TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.snow,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '링크를 추가해주세요',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.steel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
