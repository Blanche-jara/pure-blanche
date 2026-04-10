import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/section_header.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
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
          const SectionHeader(label: '01 / About', title: 'About Me'),
          const SizedBox(height: 48),
          LayoutBuilder(
            builder: (context, constraints) {
              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDescription(theme),
                    const SizedBox(height: 40),
                    _buildSkills(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildDescription(theme)),
                  const SizedBox(width: 48),
                  Expanded(flex: 2, child: _buildSkills()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(TextTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "I'm a developer who loves building creative digital experiences. "
          "From mobile apps to web platforms, I enjoy exploring new technologies "
          "and turning ideas into reality.",
          style: theme.bodyLarge,
        ),
        const SizedBox(height: 20),
        Text(
          "Currently focused on Flutter development, creating interactive "
          "applications that combine clean design with solid engineering.",
          style: theme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildSkills() {
    const skills = [
      'Flutter / Dart',
      'Web Development',
      'UI / UX Design',
      'Firebase',
      'Git / GitHub',
      'Problem Solving',
    ];

    return GlowingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SKILLS',
            style: TextStyle(
              fontFamily: 'Segoe UI',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.52,
              color: AppColors.signalGreen,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((s) => _SkillChip(label: s)).toList(),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  const _SkillChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.abyss,
        border: Border.all(color: AppColors.warmCharcoal),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.parchment,
        ),
      ),
    );
  }
}
