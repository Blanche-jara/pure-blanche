import 'dart:math';

import '../models/blind_level.dart';
import '../models/break_level.dart';

/// Auto-generates a tournament blind structure based on tournament parameters.
///
/// Ported from holdem_structure.py.
class StructureGeneratorOptions {
  final bool hasAnte;
  final int startChips;
  final int minChip;
  final int playTime; // minutes
  final int numPlayers;
  final int levelDuration; // 0 = auto
  final int anteStart;
  final String anteType; // 'bb' | 'half' | 'classic'

  /// Whether to insert breaks between blind levels.
  final bool insertBreaks;

  /// Insert a break after every N blind levels (1+).
  final int breakInterval;

  /// Duration of each inserted break, in minutes.
  final int breakDuration;

  const StructureGeneratorOptions({
    this.hasAnte = false,
    this.startChips = 20000,
    this.minChip = 100,
    this.playTime = 180,
    this.numPlayers = 9,
    this.levelDuration = 0,
    this.anteStart = 3,
    this.anteType = 'bb',
    this.insertBreaks = true,
    this.breakInterval = 4,
    this.breakDuration = 15,
  });
}

class StructureGenerator {
  /// Poker-friendly blind values.
  static const List<int> niceStops = [
    25, 50, 75, 100, 150, 200, 300, 400, 500, 600, 800,
    1000, 1200, 1500, 2000, 2500, 3000, 4000, 5000, 6000, 8000,
    10000, 12000, 15000, 20000, 25000, 30000, 40000, 50000,
    60000, 80000, 100000, 150000, 200000, 300000, 500000,
  ];

  /// Round value to the closest poker-friendly number that is a
  /// multiple of [minChip]. Falls back to a plain min-chip multiple
  /// when no nice stop matches.
  static int roundToNice(double value, int minChip) {
    final candidates = niceStops.where((s) => s % minChip == 0).toList();
    if (candidates.isEmpty) {
      return max(minChip, (value / minChip).round() * minChip);
    }
    return candidates.reduce(
      (a, b) => (a - value).abs() <= (b - value).abs() ? a : b,
    );
  }

  /// Round value to the nearest [minChip] multiple, with a floor of [minChip].
  static int roundToChip(double value, int minChip) {
    return max(minChip, (value / minChip).round() * minChip);
  }

  /// Auto-derive level duration from total play time and player count.
  static int calcLevelDuration(int playTime, int numPlayers) {
    final estLevels = max(
      8,
      min(20, (12 + (log(numPlayers) / ln2)).round()),
    );
    var dur = (playTime / estLevels).round();
    dur = max(10, min(30, dur));
    // Snap to 5-minute increments.
    return (dur / 5).round() * 5;
  }

  static int calcAnte(int bb, int sb, String anteType, int minChip) {
    switch (anteType) {
      case 'bb':
        return bb;
      case 'half':
        return sb;
      case 'classic':
        return roundToChip(bb * 0.1, minChip);
    }
    return 0;
  }

  /// Generates a structure (mix of [BlindLevel] and [BreakLevel]) based on [opts].
  ///
  /// Breaks are inserted after every [StructureGeneratorOptions.breakInterval]
  /// blind levels when [StructureGeneratorOptions.insertBreaks] is true. A break
  /// is never appended after the very last blind level.
  static List<dynamic> generate(StructureGeneratorOptions opts) {
    var levelDur = opts.levelDuration;
    if (levelDur <= 0) {
      levelDur = calcLevelDuration(opts.playTime, opts.numPlayers);
    }

    final totalLevels = max(1, (opts.playTime / levelDur).round());

    // Starting BB based on a 100 BB stack.
    var startBb = roundToNice(opts.startChips / 100, opts.minChip);
    startBb = max(opts.minChip, startBb);

    final List<dynamic> result = [];
    var bb = startBb;

    final interval = opts.breakInterval > 0 ? opts.breakInterval : 1;

    for (int i = 0; i < totalLevels; i++) {
      final levelNum = i + 1;
      final sb = roundToNice(bb / 2, opts.minChip);

      var ante = 0;
      if (opts.hasAnte && levelNum >= opts.anteStart) {
        ante = calcAnte(bb, sb, opts.anteType, opts.minChip);
      }

      result.add(BlindLevel(
        level: levelNum,
        smallBlind: sb,
        bigBlind: bb,
        ante: ante,
        durationMinutes: levelDur,
      ));

      // Insert a break after every `interval` blind levels, but never after
      // the last level.
      final isLast = i == totalLevels - 1;
      if (opts.insertBreaks && !isLast && levelNum % interval == 0) {
        result.add(BreakLevel(durationMinutes: opts.breakDuration));
      }

      // Early/middle 1.5×, late/final 1.6×.
      final multiplier = i < totalLevels * 0.5 ? 1.5 : 1.6;
      bb = roundToNice(bb * multiplier, opts.minChip);
    }

    return result;
  }
}
