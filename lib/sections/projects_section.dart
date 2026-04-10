import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/section_header.dart';

class ProjectsSection extends StatelessWidget {
  const ProjectsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 1200),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: 80,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(label: '02 / Projects', title: 'What I Built'),
          const SizedBox(height: 48),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = isMobile ? 1 : (constraints.maxWidth > 900 ? 3 : 2);
              return Wrap(
                spacing: 24,
                runSpacing: 24,
                children: _projects.map((p) {
                  final width = isMobile
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 24 * (crossAxisCount - 1)) /
                          crossAxisCount;
                  return SizedBox(
                    width: width,
                    child: _ProjectCard(project: p),
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

class _Project {
  final String title;
  final String description;
  final String tech;
  final IconData icon;

  const _Project({
    required this.title,
    required this.description,
    required this.tech,
    required this.icon,
  });
}

const _projects = [
  _Project(
    title: 'Roulette App',
    description: 'A Flutter-based roulette application with smooth animations and interactive gameplay.',
    tech: 'Flutter · Dart',
    icon: Icons.casino_outlined,
  ),
  _Project(
    title: 'Jara Holdem',
    description: 'Texas Hold\'em poker game built with Flutter, featuring real-time multiplayer mechanics.',
    tech: 'Flutter · Dart',
    icon: Icons.style_outlined,
  ),
  _Project(
    title: 'Jamakase',
    description: 'An immersive web experience with rich audio-visual presentation and creative interactions.',
    tech: 'HTML · CSS · JS',
    icon: Icons.music_note_outlined,
  ),
];

class _ProjectCard extends StatefulWidget {
  final _Project project;
  const _ProjectCard({required this.project});

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

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
            Text(widget.project.title, style: theme.headlineLarge),
            const SizedBox(height: 12),
            Text(
              widget.project.description,
              style: theme.bodyLarge?.copyWith(fontSize: 15),
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
                  fontFamily: 'SFMono-Regular, Consolas, monospace',
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
