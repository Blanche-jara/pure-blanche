import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../engine/models.dart';
import '../../engine/rules.dart';

const _effects = {
  'strike': 4,
  'success': 6,
  'destruction': 6,
  'protection': 6,
  'breakthrough': 8,
  'rare_discovery': 8,
};
final forgeEffectAssets = _effects.keys
    .map((name) => 'assets/sword_upgrade/fx/$name.png')
    .toList(growable: false);

class ForgeStage extends StatefulWidget {
  final Sword sword;
  final Outcome? outcome;
  final int sequence;
  final Duration duration;
  const ForgeStage({
    super.key,
    required this.sword,
    required this.sequence,
    required this.duration,
    this.outcome,
  });
  @override
  State<ForgeStage> createState() => _ForgeStageState();
}

class _ForgeStageState extends State<ForgeStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  final _sheets = <String, ImageInfo>{};
  final _streams = <(ImageStream, ImageStreamListener)>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_streams.isNotEmpty) return;
    // Retain all decoded sheets, including effects that have not occurred yet.
    // An attempt never waits for a new image decode.
    for (final name in _effects.keys) {
      final stream = AssetImage(
        'assets/sword_upgrade/fx/$name.png',
      ).resolve(createLocalImageConfiguration(context));
      final listener = ImageStreamListener((info, _) {
        if (!mounted) {
          info.dispose();
          return;
        }
        setState(() {
          _sheets.remove(name)?.dispose();
          _sheets[name] = info;
        });
      });
      _streams.add((stream, listener));
      stream.addListener(listener);
    }
  }

  @override
  void didUpdateWidget(ForgeStage old) {
    super.didUpdateWidget(old);
    if (old.sequence != widget.sequence && widget.outcome != null) {
      animation.duration = widget.duration;
      animation.forward(from: 0);
    } else if (widget.outcome == null) {
      animation.stop();
      animation.reset();
    }
  }

  @override
  void dispose() {
    animation.dispose();
    for (final (stream, listener) in _streams) {
      stream.removeListener(listener);
    }
    for (final sheet in _sheets.values) {
      sheet.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = max(1, (constraints.maxWidth / 320).floor());
      return SizedBox(
        height: 180.0 * scale,
        child: Center(
          child: SizedBox(
            width: 320.0 * scale,
            height: 180.0 * scale,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final moving = animation.isAnimating;
                final progress = animation.value;
                final outcome = widget.outcome;
                final kind = outcome?.kind;
                final resultProgress = ((progress - .18) / .82).clamp(0.0, 1.0);
                final resultVisible =
                    outcome != null && (!moving || progress >= .18);
                final destroyed = kind == OutcomeKind.destroyed;
                final rareFound = kind == OutcomeKind.rareFound;
                final special =
                    rareFound ||
                    kind == OutcomeKind.breakthrough ||
                    kind == OutcomeKind.ending;
                final color = _outcomeColor(kind);
                final pulse = moving && progress >= .18
                    ? sin(resultProgress * pi)
                    : 0.0;
                final shake = moving && destroyed && progress >= .18
                    ? (sin(resultProgress * pi * 12) * 4 * (1 - resultProgress))
                          .roundToDouble()
                    : 0.0;
                final sword =
                    moving &&
                        outcome != null &&
                        (progress < .18 ||
                            destroyed && progress < .66 ||
                            rareFound && progress < .45)
                    ? outcome.before
                    : widget.sword;
                final swordOpacity =
                    moving && destroyed && progress >= .3 && progress < .66
                    ? (1 - (progress - .3) / .36).clamp(0.0, 1.0)
                    : 1.0;
                Widget positioned(
                  double x,
                  double y,
                  double width,
                  double height,
                  String path,
                ) => Positioned(
                  left: x * scale,
                  top: y * scale,
                  width: width * scale,
                  height: height * scale,
                  child: Image.asset(
                    path,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                    isAntiAlias: false,
                  ),
                );
                Widget effect(
                  String name,
                  double p,
                  double size,
                  double x,
                  double y,
                  Key key,
                ) => Positioned(
                  left: (x - size / 2) * scale,
                  top: (y - size / 2) * scale,
                  width: size * scale,
                  height: size * scale,
                  child: SpriteEffect(
                    key: key,
                    sheet: _sheets[name]?.image,
                    frames: _effects[name]!,
                    progress: p,
                  ),
                );
                final hammerLift = moving && progress < .18
                    ? sin(progress / .18 * pi)
                    : 0.0;
                return ClipRect(
                  child: Stack(
                    children: [
                      positioned(
                        0,
                        0,
                        320,
                        180,
                        'assets/sword_upgrade/scene/forge_bg.png',
                      ),
                      positioned(
                        8,
                        59,
                        64,
                        96,
                        'assets/sword_upgrade/scene/furnace.png',
                      ),
                      positioned(
                        112 + shake,
                        104,
                        96,
                        64,
                        'assets/sword_upgrade/scene/anvil.png',
                      ),
                      positioned(
                        261,
                        127,
                        48,
                        32,
                        'assets/sword_upgrade/scene/storage_chest.png',
                      ),
                      if (moving)
                        Positioned.fill(
                          child: ColoredBox(
                            color: Colors.black.withValues(alpha: .45 * pulse),
                          ),
                        ),
                      Positioned(
                        left: (95 + shake) * scale,
                        top:
                            (12 +
                                (moving
                                    ? sin(progress * pi).roundToDouble() * 2
                                    : 0.0)) *
                            scale,
                        width: 128.0 * scale,
                        height: 128.0 * scale,
                        child: Opacity(
                          opacity: swordOpacity,
                          child: Image.asset(
                            sword.image(),
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.none,
                            isAntiAlias: false,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 208.0 * scale,
                        top: (55 - 22 * hammerLift).roundToDouble() * scale,
                        width: 32.0 * scale,
                        height: 48.0 * scale,
                        child: Transform.rotate(
                          angle: -.15 - .8 * hammerLift,
                          alignment: Alignment.bottomCenter,
                          child: Image.asset(
                            'assets/sword_upgrade/scene/hammer.png',
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.none,
                          ),
                        ),
                      ),
                      if (moving && progress >= .12 && progress < .36)
                        effect(
                          'strike',
                          ((progress - .12) / .24).clamp(0.0, 1.0),
                          96,
                          190,
                          86,
                          const ValueKey('forge-strike'),
                        ),
                      if (moving && progress >= .18 && outcome != null)
                        effect(
                          _effectName(outcome.kind),
                          resultProgress,
                          special ? 224 : 192,
                          159,
                          75,
                          const ValueKey('forge-result-effect'),
                        ),
                      if (moving && pulse > 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: color.withValues(alpha: .9 * pulse),
                                  width: 2.0 * scale,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (resultVisible)
                        Positioned(
                          left: 26.0 * scale,
                          right: 26.0 * scale,
                          bottom: 8.0 * scale,
                          child: Semantics(
                            liveRegion: true,
                            child: Container(
                              key: const ValueKey('forge-result-label'),
                              padding: EdgeInsets.symmetric(
                                vertical: 5.0 * scale,
                                horizontal: 8.0 * scale,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xee100f16),
                                border: Border.all(
                                  color: color,
                                  width: 1.0 * scale,
                                ),
                              ),
                              child: Text(
                                _outcomeLabel(outcome, widget.sword),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 16.0 * scale,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

String _effectName(OutcomeKind kind) => switch (kind) {
  OutcomeKind.destroyed => 'destruction',
  OutcomeKind.protected => 'protection',
  OutcomeKind.rareFound => 'rare_discovery',
  OutcomeKind.breakthrough || OutcomeKind.ending => 'breakthrough',
  OutcomeKind.success => 'success',
};

Color _outcomeColor(OutcomeKind? kind) => switch (kind) {
  OutcomeKind.destroyed => const Color(0xffff826c),
  OutcomeKind.protected => const Color(0xff69daff),
  OutcomeKind.rareFound => const Color(0xfff38bff),
  OutcomeKind.breakthrough || OutcomeKind.ending => const Color(0xffffd45a),
  _ => const Color(0xff72ffda),
};

String _outcomeLabel(Outcome outcome, Sword sword) => switch (outcome.kind) {
  OutcomeKind.success => '강화 성공  +${sword.level}',
  OutcomeKind.protected =>
    outcome.before.isRare ? '강화 실패 · 내구도 −1' : '보호 발동 · 검 유지',
  OutcomeKind.destroyed => '강화 실패 · 검 파괴',
  OutcomeKind.rareFound => '희귀 무기 발견!',
  OutcomeKind.breakthrough => '돌파 성공  +${sword.level}',
  OutcomeKind.ending => '전설 완성  +${sword.level}',
};

class SpriteEffect extends StatelessWidget {
  final ui.Image? sheet;
  final int frames;
  final double progress;
  const SpriteEffect({
    super.key,
    required this.sheet,
    required this.frames,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _FramePainter(
        sheet,
        frames,
        min(frames - 1, (progress * frames).floor()),
      ),
    ),
  );
}

class _FramePainter extends CustomPainter {
  final ui.Image? image;
  final int frames;
  final int frame;
  _FramePainter(this.image, this.frames, this.frame);
  @override
  void paint(Canvas canvas, Size size) {
    final image = this.image;
    if (image == null) return;
    final width = image.width / frames;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(frame * width, 0, width, image.height.toDouble()),
      Offset.zero & size,
      Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.frame != frame || old.image != image || old.frames != frames;
}
