enum Suit { spades, hearts, diamonds, clubs }

class PlayingCard {
  /// 2..14 (J=11, Q=12, K=13, A=14)
  final int rank;
  final Suit suit;

  const PlayingCard(this.rank, this.suit);

  String get rankSymbol {
    switch (rank) {
      case 14:
        return 'A';
      case 13:
        return 'K';
      case 12:
        return 'Q';
      case 11:
        return 'J';
      case 10:
        return 'T';
      default:
        return rank.toString();
    }
  }

  String get suitSymbol {
    switch (suit) {
      case Suit.spades:
        return '♠';
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
      case Suit.clubs:
        return '♣';
    }
  }

  bool get isRed => suit == Suit.hearts || suit == Suit.diamonds;

  @override
  bool operator ==(Object other) =>
      other is PlayingCard && other.rank == rank && other.suit == suit;

  @override
  int get hashCode => rank * 4 + suit.index;

  @override
  String toString() => '$rankSymbol$suitSymbol';
}

/// All 52 cards in canonical order: spades, hearts, diamonds, clubs × 2..A
final List<PlayingCard> kAllCards = [
  for (final suit in Suit.values)
    for (int rank = 2; rank <= 14; rank++) PlayingCard(rank, suit),
];
