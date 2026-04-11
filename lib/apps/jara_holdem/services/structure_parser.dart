import '../models/blind_level.dart';
import '../models/break_level.dart';

class StructureParseResult {
  final List<dynamic> levels;
  final List<String> errors;

  const StructureParseResult({required this.levels, required this.errors});

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccess => errors.isEmpty && levels.isNotEmpty;
}

/// Parses a text block into a tournament structure.
///
/// Format:
///   ante: Y             ← ante enabled, all blind lines MUST have /ANTE
///   ante: N             ← ante disabled (default), blind lines MUST NOT have /ANTE
///   10-100/200          ← ante: N mode
///   10-100/200/0        ← ante: Y mode (ante value can be 0)
///   15-brk              ← break
///
class StructureParser {
  static StructureParseResult parse(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const StructureParseResult(
        levels: [],
        errors: ['No input provided.'],
      );
    }

    final List<dynamic> levels = [];
    final List<String> errors = [];
    bool anteEnabled = false;
    bool anteDeclarationFound = false;
    int blindNum = 1;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNum = i + 1;

      // Check for ante declaration: ante: Y or ante: N
      final anteMatch = RegExp(r'^ante\s*:\s*([YNyn])$', caseSensitive: false).firstMatch(line);
      if (anteMatch != null) {
        if (anteDeclarationFound) {
          errors.add('Line $lineNum: duplicate ante declaration');
          continue;
        }
        anteEnabled = anteMatch.group(1)!.toUpperCase() == 'Y';
        anteDeclarationFound = true;
        continue;
      }

      // Catch old numeric ante format
      if (RegExp(r'^ante\s*:', caseSensitive: false).hasMatch(line)) {
        errors.add('Line $lineNum: "$line" — ante must be Y or N (e.g. ante: Y)');
        continue;
      }

      // Check for level line: DURATION-BODY
      final levelMatch = RegExp(r'^(\d+)\s*-\s*(.+)$').firstMatch(line);
      if (levelMatch == null) {
        errors.add('Line $lineNum: "$line" — expected format: DURATION-SB/BB or DURATION-brk');
        continue;
      }

      final duration = int.parse(levelMatch.group(1)!);
      final body = levelMatch.group(2)!.trim();
      final bodyLower = body.toLowerCase();

      if (duration <= 0) {
        errors.add('Line $lineNum: duration must be greater than 0');
        continue;
      }

      if (duration > 50) {
        errors.add('Line $lineNum: duration cannot exceed 50 minutes');
        continue;
      }

      // Break
      if (bodyLower == 'brk' || bodyLower == 'break') {
        levels.add(BreakLevel(durationMinutes: duration));
        continue;
      }

      // Blind level: SB/BB or SB/BB/ANTE
      final withAnte = RegExp(r'^(\d+)\s*/\s*(\d+)\s*/\s*(\d+)$').firstMatch(body);
      final withoutAnte = RegExp(r'^(\d+)\s*/\s*(\d+)$').firstMatch(body);

      if (withAnte != null) {
        // Has three values: SB/BB/ANTE
        if (!anteEnabled) {
          errors.add('Line $lineNum: ante is N — cannot use SB/BB/ANTE format. Use SB/BB instead');
          continue;
        }
        final sb = int.parse(withAnte.group(1)!);
        final bb = int.parse(withAnte.group(2)!);
        final ante = int.parse(withAnte.group(3)!);

        if (sb <= 0 || bb <= 0) {
          errors.add('Line $lineNum: SB and BB must be greater than 0');
          continue;
        }

        levels.add(BlindLevel(
          level: blindNum,
          smallBlind: sb,
          bigBlind: bb,
          ante: ante,
          durationMinutes: duration,
        ));
        blindNum++;
      } else if (withoutAnte != null) {
        // Has two values: SB/BB
        if (anteEnabled) {
          errors.add('Line $lineNum: ante is Y — must use SB/BB/ANTE format (e.g. $body/0)');
          continue;
        }
        final sb = int.parse(withoutAnte.group(1)!);
        final bb = int.parse(withoutAnte.group(2)!);

        if (sb <= 0 || bb <= 0) {
          errors.add('Line $lineNum: SB and BB must be greater than 0');
          continue;
        }

        levels.add(BlindLevel(
          level: blindNum,
          smallBlind: sb,
          bigBlind: bb,
          ante: 0,
          durationMinutes: duration,
        ));
        blindNum++;
      } else {
        errors.add('Line $lineNum: "$body" — expected SB/BB or SB/BB/ANTE or brk');
        continue;
      }
    }

    if (errors.isEmpty && levels.isEmpty) {
      errors.add('No valid levels found. Check format.');
    }

    return StructureParseResult(levels: levels, errors: errors);
  }

  /// Generates a format help string.
  static String get formatHelp => '''ante: N
10-100/200
10-200/400
10-300/600
15-brk
7-500/1000''';

  static String get aiPrompt =>
      '포커 토너먼트 블라인드 스트럭쳐를 아래 포맷에 맞춰 생성해줘.\n'
      '\n'
      '=== Format Rules ===\n'
      '- 첫 줄(필수): "ante: Y" 또는 "ante: N"\n'
      '  - Y: 앤티 사용. 모든 블라인드 라인에 반드시 /ANTE 포함 (예: 10-100/200/50)\n'
      '  - N: 앤티 미사용. 블라인드 라인에 /ANTE 절대 불가 (예: 10-100/200)\n'
      '- 블라인드 레벨:\n'
      '  - ante: N → "DURATION-SB/BB" (예: 10-100/200)\n'
      '  - ante: Y → "DURATION-SB/BB/ANTE" (예: 10-100/200/0)\n'
      '- 휴식: "DURATION-brk" (예: 15-brk)\n'
      '- Duration은 1~50 (분)\n'
      '- 각 항목은 줄바꿈으로 구분\n'
      '\n'
      '=== Example (ante: N) ===\n'
      'ante: N\n'
      '10-100/200\n'
      '10-200/400\n'
      '15-brk\n'
      '10-500/1000\n'
      '\n'
      '=== Example (ante: Y) ===\n'
      'ante: Y\n'
      '10-100/200/0\n'
      '10-200/400/0\n'
      '15-brk\n'
      '10-500/1000/500\n'
      '10-1000/2000/1000\n'
      '\n'
      '위 포맷만 사용해서 결과를 텍스트로 출력해줘. 다른 설명 없이 포맷 텍스트만 출력해.';

  static String get formatDescription =>
      'ante: Y/N  →  Ante on or off (required)\n'
      'ante: N → DURATION-SB/BB\n'
      'ante: Y → DURATION-SB/BB/ANTE\n'
      'DURATION-brk  →  Break';
}
