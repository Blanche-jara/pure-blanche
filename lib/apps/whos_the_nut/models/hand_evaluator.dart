import 'playing_card.dart';

enum HandCategory {
  highCard,
  onePair,
  twoPair,
  threeOfAKind,
  straight,
  flush,
  fullHouse,
  fourOfAKind,
  straightFlush,
  royalFlush,
}

extension HandCategoryLabel on HandCategory {
  String get label {
    switch (this) {
      case HandCategory.highCard:
        return 'High Card';
      case HandCategory.onePair:
        return 'One Pair';
      case HandCategory.twoPair:
        return 'Two Pair';
      case HandCategory.threeOfAKind:
        return 'Three of a Kind';
      case HandCategory.straight:
        return 'Straight';
      case HandCategory.flush:
        return 'Flush';
      case HandCategory.fullHouse:
        return 'Full House';
      case HandCategory.fourOfAKind:
        return 'Four of a Kind';
      case HandCategory.straightFlush:
        return 'Straight Flush';
      case HandCategory.royalFlush:
        return 'Royal Flush';
    }
  }
}

/// (category, tiebreakers) — comparing tiebreakers lexicographically
/// gives the correct within-category order.
class HandRank implements Comparable<HandRank> {
  final HandCategory category;
  final List<int> tiebreakers;

  const HandRank(this.category, this.tiebreakers);

  @override
  int compareTo(HandRank other) {
    if (category != other.category) {
      return category.index.compareTo(other.category.index);
    }
    for (int i = 0; i < tiebreakers.length && i < other.tiebreakers.length; i++) {
      final c = tiebreakers[i].compareTo(other.tiebreakers[i]);
      if (c != 0) return c;
    }
    return 0;
  }

  bool operator >(HandRank other) => compareTo(other) > 0;
  bool operator >=(HandRank other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is HandRank &&
      other.category == category &&
      _listEq(other.tiebreakers, tiebreakers);

  @override
  int get hashCode =>
      Object.hash(category, Object.hashAll(tiebreakers));

  static bool _listEq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Rank exactly 5 cards.
HandRank evaluateFive(List<PlayingCard> cards) {
  assert(cards.length == 5);

  final ranks = cards.map((c) => c.rank).toList()..sort((a, b) => b - a);
  final suits = cards.map((c) => c.suit).toSet();
  final isFlush = suits.length == 1;

  // Straight detection (incl. wheel A-2-3-4-5)
  final unique = ranks.toSet().toList()..sort((a, b) => b - a);
  bool isStraight = false;
  int straightHigh = 0;
  if (unique.length == 5) {
    if (unique.first - unique.last == 4) {
      isStraight = true;
      straightHigh = unique.first;
    } else if (unique[0] == 14 && unique[1] == 5 && unique[4] == 2) {
      isStraight = true;
      straightHigh = 5;
    }
  }

  // Group by rank, sorted by (count desc, rank desc)
  final counts = <int, int>{};
  for (final r in ranks) {
    counts[r] = (counts[r] ?? 0) + 1;
  }
  final groups = counts.entries.toList()
    ..sort((a, b) {
      if (a.value != b.value) return b.value - a.value;
      return b.key - a.key;
    });
  final countSeq = groups.map((e) => e.value).toList();
  final rankSeq = groups.map((e) => e.key).toList();

  if (isStraight && isFlush) {
    if (straightHigh == 14) return const HandRank(HandCategory.royalFlush, [14]);
    return HandRank(HandCategory.straightFlush, [straightHigh]);
  }
  if (countSeq[0] == 4) return HandRank(HandCategory.fourOfAKind, rankSeq);
  if (countSeq[0] == 3 && countSeq.length > 1 && countSeq[1] == 2) {
    return HandRank(HandCategory.fullHouse, rankSeq);
  }
  if (isFlush) return HandRank(HandCategory.flush, ranks);
  if (isStraight) return HandRank(HandCategory.straight, [straightHigh]);
  if (countSeq[0] == 3) return HandRank(HandCategory.threeOfAKind, rankSeq);
  if (countSeq[0] == 2 && countSeq.length > 1 && countSeq[1] == 2) {
    return HandRank(HandCategory.twoPair, rankSeq);
  }
  if (countSeq[0] == 2) return HandRank(HandCategory.onePair, rankSeq);
  return HandRank(HandCategory.highCard, ranks);
}

/// Best 5-card hand from 7 cards (try all C(7,5) = 21 combos).
HandRank bestOfSeven(List<PlayingCard> seven) {
  assert(seven.length == 7);
  HandRank? best;
  for (int i = 0; i < 7; i++) {
    for (int j = i + 1; j < 7; j++) {
      final five = <PlayingCard>[];
      for (int k = 0; k < 7; k++) {
        if (k != i && k != j) five.add(seven[k]);
      }
      final h = evaluateFive(five);
      if (best == null || h > best) best = h;
    }
  }
  return best!;
}

/// Find the best HandRank achievable by ANY hole-card combo
/// given the 5 community cards. This is "the nuts."
HandRank findNutRank(List<PlayingCard> community) {
  assert(community.length == 5);
  final available = kAllCards.where((c) => !community.contains(c)).toList();
  HandRank? best;
  for (int i = 0; i < available.length; i++) {
    for (int j = i + 1; j < available.length; j++) {
      final h = bestOfSeven([available[i], available[j], ...community]);
      if (best == null || h > best) best = h;
    }
  }
  return best!;
}
