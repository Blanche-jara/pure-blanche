import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.warmCharcoal, width: 1),
        ),
      ),
      child: const Column(
        children: [
          Text(
            'Built with Flutter & designed with intention.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.steel,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '© 2026 Blanche. All rights reserved.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.steel,
            ),
          ),
        ],
      ),
    );
  }
}
