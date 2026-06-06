import 'package:flutter/material.dart';

import '../../poker/cards.dart';

/// 카드 한 장 표시(미선택이면 빈 슬롯). 탭하면 [onTap].
class CardSlotChip extends StatelessWidget {
  const CardSlotChip({super.key, required this.card, required this.onTap});

  /// 0..51 또는 null(빈 슬롯).
  final int? card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = card;
    final isRed = c != null && (Cards.suitOf(c) == 1 || Cards.suitOf(c) == 2);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 44,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c == null ? scheme.surfaceContainerHighest : Colors.white,
          border: Border.all(color: scheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: c == null
            ? Icon(Icons.add, color: scheme.outline)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    Cards.ranks[Cards.rankOf(c)],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isRed ? Colors.red.shade700 : Colors.black,
                    ),
                  ),
                  Text(
                    Cards.suitSymbol(Cards.suitOf(c)),
                    style: TextStyle(
                      fontSize: 16,
                      color: isRed ? Colors.red.shade700 : Colors.black,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// 카드 선택 바텀시트. [used]는 이미 쓰인 카드(비활성). 선택 시 카드 정수 반환, 취소 시 null.
/// "비우기"를 누르면 [clearSentinel](-1) 반환.
const int clearSentinel = -1;

Future<int?> showCardPicker(BuildContext context, Set<int> used) {
  return showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '카드 선택',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      letterSpacing: -0.374,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => Navigator.pop(ctx, clearSentinel),
                    icon: const Icon(Icons.clear),
                    label: const Text('비우기'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // 수트별 행(c,d,h,s), 각 행에 13개 랭크.
              for (var suit = 0; suit < 4; suit++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      for (var rank = 0; rank < 13; rank++)
                        _PickCell(
                          card: Cards.make(rank, suit),
                          disabled: used.contains(Cards.make(rank, suit)),
                          onTap: () =>
                              Navigator.pop(ctx, Cards.make(rank, suit)),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _PickCell extends StatelessWidget {
  const _PickCell({
    required this.card,
    required this.disabled,
    required this.onTap,
  });
  final int card;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final suit = Cards.suitOf(card);
    final isRed = suit == 1 || suit == 2;
    return Expanded(
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Opacity(
          opacity: disabled ? 0.25 : 1,
          child: Container(
            margin: const EdgeInsets.all(1),
            padding: const EdgeInsets.symmetric(vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FittedBox(
              child: Text(
                '${Cards.ranks[Cards.rankOf(card)]}${Cards.suitSymbol(suit)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isRed ? Colors.red.shade700 : Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
