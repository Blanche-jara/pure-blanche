import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tournament_provider.dart';

class ControlButtons extends StatelessWidget {
  final VoidCallback? onSettingsTap;

  const ControlButtons({super.key, this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = (screenWidth * 0.06).clamp(36.0, 64.0);
    final iconSize = buttonSize * 0.5;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main controls row (hide prev/next for cash game)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!provider.isCashGame) ...[
              _ControlButton(
                icon: Icons.skip_previous_rounded,
                onTap: provider.currentLevelIndex > 0 ? provider.previousLevel : null,
                size: buttonSize,
                iconSize: iconSize,
              ),
              const SizedBox(width: 16),
            ],
            // Play / Pause
            _ControlButton(
              icon: provider.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              onTap: provider.structure.levels.isNotEmpty ? provider.toggleStartPause : null,
              size: buttonSize * 1.4,
              iconSize: iconSize * 1.4,
              isPrimary: true,
              color: provider.isRunning ? Colors.orange : Colors.green,
            ),
            if (!provider.isCashGame) ...[
              const SizedBox(width: 16),
              _ControlButton(
                icon: Icons.skip_next_rounded,
                onTap: !provider.isLastLevel ? provider.nextLevelManual : null,
                size: buttonSize,
                iconSize: iconSize,
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        // Secondary controls row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!provider.isInfiniteLevel) ...[
              _SmallButton(
                label: '-1 min',
                onTap: provider.remainingSeconds > 60 ? provider.subtractMinute : null,
              ),
              const SizedBox(width: 8),
              _SmallButton(
                label: '+1 min',
                onTap: provider.addMinute,
              ),
              const SizedBox(width: 16),
            ],
            if (!provider.isCashGame)
              _ControlButton(
                icon: provider.soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                onTap: provider.toggleSound,
                size: buttonSize * 0.7,
                iconSize: iconSize * 0.7,
                color: provider.soundEnabled ? Colors.white54 : Colors.red.shade300,
              ),
            if (!provider.isCashGame) const SizedBox(width: 8),
            _ControlButton(
              icon: Icons.restart_alt_rounded,
              onTap: () => _showResetDialog(context, provider),
              size: buttonSize * 0.7,
              iconSize: iconSize * 0.7,
            ),
            if (onSettingsTap != null) ...[
              const SizedBox(width: 8),
              _ControlButton(
                icon: Icons.settings_rounded,
                onTap: onSettingsTap,
                size: buttonSize * 0.7,
                iconSize: iconSize * 0.7,
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _showResetDialog(BuildContext context, TournamentProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Reset Tournament', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Reset to Level 1? Current progress will be lost.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.resetTournament();
              Navigator.pop(ctx);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final bool isPrimary;
  final Color? color;

  const _ControlButton({
    required this.icon,
    this.onTap,
    required this.size,
    required this.iconSize,
    this.isPrimary = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    final effectiveColor = isDisabled ? Colors.white24 : (color ?? Colors.white54);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isPrimary ? effectiveColor : effectiveColor.withValues(alpha: 0.3),
              width: isPrimary ? 3 : 1.5,
            ),
            color: isPrimary ? effectiveColor.withValues(alpha: 0.15) : Colors.transparent,
          ),
          child: Icon(icon, size: iconSize, color: effectiveColor),
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _SmallButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDisabled ? Colors.white12 : Colors.white24),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isDisabled ? Colors.white24 : Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
