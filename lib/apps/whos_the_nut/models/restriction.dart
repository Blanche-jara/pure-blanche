import 'dart:math';
import 'hand_evaluator.dart';
import 'playing_card.dart';

/// A preflop / made-hand restriction applied in EXTRA HARD MODE.
///
/// Each restriction has zero or more predicates:
///   - [holePredicate]: returns true if the 2-card hole satisfies the rule.
///   - [handPredicate]: returns true if the final HandRank category satisfies it.
///   - [flopOnly]: when true, only the first 3 community cards are used.
class Restriction {
  final String label;
  final bool Function(List<PlayingCard> hole)? holePredicate;
  final bool Function(HandRank rank)? handPredicate;
  final bool flopOnly;

  const Restriction({
    required this.label,
    this.holePredicate,
    this.handPredicate,
    this.flopOnly = false,
  });

  bool allowsHole(List<PlayingCard> hole) =>
      holePredicate == null || holePredicate!(hole);

  bool allowsHand(HandRank rank) =>
      handPredicate == null || handPredicate!(rank);
}

// ───────────────────────── Predicate helpers ─────────────────────────

bool _isPair(List<PlayingCard> h) => h[0].rank == h[1].rank;

bool _isSuited(List<PlayingCard> h) => h[0].suit == h[1].suit;

bool _isConnected(List<PlayingCard> h) {
  final diff = (h[0].rank - h[1].rank).abs();
  if (diff == 1) return true;
  // Wheel: A-2 also connected
  if ((h[0].rank == 14 && h[1].rank == 2) ||
      (h[1].rank == 14 && h[0].rank == 2)) {
    return true;
  }
  return false;
}

bool _isOneGapper(List<PlayingCard> h) {
  final diff = (h[0].rank - h[1].rank).abs();
  if (diff == 2) return true;
  // Wheel: A-3 one-gapper
  if ((h[0].rank == 14 && h[1].rank == 3) ||
      (h[1].rank == 14 && h[0].rank == 3)) {
    return true;
  }
  return false;
}

bool _isBroadway(int rank) => rank >= 10; // T,J,Q,K,A
bool _isFace(int rank) => rank >= 11 && rank <= 13; // J,Q,K
bool _isAce(int rank) => rank == 14;

// ───────────────────────── Fixed restrictions ─────────────────────────

final List<Restriction> _fixedRestrictions = [
  // Hole-card composition
  Restriction(label: 'NO POCKETS', holePredicate: (h) => !_isPair(h)),
  Restriction(label: 'ONLY POCKETS', holePredicate: (h) => _isPair(h)),
  Restriction(label: 'NO SUITED', holePredicate: (h) => !_isSuited(h)),
  Restriction(label: 'ONLY SUITED', holePredicate: (h) => _isSuited(h)),
  Restriction(label: 'NO CONNECTED', holePredicate: (h) => !_isConnected(h)),
  Restriction(label: 'ONLY CONNECTED', holePredicate: (h) => _isConnected(h)),
  Restriction(label: 'NO ONE-GAPPER', holePredicate: (h) => !_isOneGapper(h)),
  Restriction(
    label: 'NO BROADWAYS',
    holePredicate: (h) => !_isBroadway(h[0].rank) && !_isBroadway(h[1].rank),
  ),
  Restriction(
    label: 'ONLY BROADWAYS',
    holePredicate: (h) => _isBroadway(h[0].rank) && _isBroadway(h[1].rank),
  ),
  Restriction(
    label: 'NO FACE',
    holePredicate: (h) => !_isFace(h[0].rank) && !_isFace(h[1].rank),
  ),
  Restriction(
    label: 'NO ACES',
    holePredicate: (h) => !_isAce(h[0].rank) && !_isAce(h[1].rank),
  ),
  Restriction(
    label: 'MUST INCLUDE ACE',
    holePredicate: (h) => _isAce(h[0].rank) || _isAce(h[1].rank),
  ),
  Restriction(
    label: 'NO AA',
    holePredicate: (h) => !(h[0].rank == 14 && h[1].rank == 14),
  ),

  // Made-hand category blocks
  Restriction(
    label: 'NO PAIR',
    handPredicate: (r) => r.category != HandCategory.onePair,
  ),
  Restriction(
    label: 'NO TWO PAIR',
    handPredicate: (r) => r.category != HandCategory.twoPair,
  ),
  Restriction(
    label: 'NO TRIPS',
    handPredicate: (r) => r.category != HandCategory.threeOfAKind,
  ),
  Restriction(
    label: 'NO STRAIGHT',
    handPredicate: (r) => r.category != HandCategory.straight,
  ),
  Restriction(
    label: 'NO FLUSH',
    handPredicate: (r) => r.category != HandCategory.flush,
  ),
  Restriction(
    label: 'NO FULL HOUSE',
    handPredicate: (r) => r.category != HandCategory.fullHouse,
  ),
  Restriction(
    label: 'NO QUADS',
    handPredicate: (r) => r.category != HandCategory.fourOfAKind,
  ),
  Restriction(
    label: 'NO STRAIGHT FLUSH',
    handPredicate: (r) => r.category != HandCategory.straightFlush,
  ),
  Restriction(
    label: 'NO ROYAL',
    handPredicate: (r) => r.category != HandCategory.royalFlush,
  ),

  // Meta
  Restriction(label: 'NO TURN/RIVER', flopOnly: true),
];

// Suit blocks
final List<Restriction> _suitBlocks = [
  Restriction(
    label: 'NO HEARTS',
    holePredicate: (h) =>
        h[0].suit != Suit.hearts && h[1].suit != Suit.hearts,
  ),
  Restriction(
    label: 'NO SPADES',
    holePredicate: (h) =>
        h[0].suit != Suit.spades && h[1].suit != Suit.spades,
  ),
  Restriction(
    label: 'NO DIAMONDS',
    holePredicate: (h) =>
        h[0].suit != Suit.diamonds && h[1].suit != Suit.diamonds,
  ),
  Restriction(
    label: 'NO CLUBS',
    holePredicate: (h) =>
        h[0].suit != Suit.clubs && h[1].suit != Suit.clubs,
  ),
];

String _rankSym(int rank) {
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

// Rank blocks (2..K — Ace is covered by NO ACES)
final List<Restriction> _rankBlocks = [
  for (int rank = 2; rank <= 13; rank++)
    Restriction(
      label: 'NO ${_rankSym(rank)}s',
      holePredicate: (h) => h[0].rank != rank && h[1].rank != rank,
    ),
];

/// Master pool of all available restrictions.
final List<Restriction> kAllRestrictions = [
  ..._fixedRestrictions,
  ..._suitBlocks,
  ..._rankBlocks,
];

// ───────────────────────── Conflict rules ─────────────────────────

/// Pairs of restriction labels that cannot coexist.
const Set<String> _suitBlockLabels = {
  'NO HEARTS', 'NO SPADES', 'NO DIAMONDS', 'NO CLUBS',
};

bool _isSuitBlock(String label) => _suitBlockLabels.contains(label);

bool _isRankBlock(String label) =>
    label.startsWith('NO ') && label.endsWith('s') &&
    !_suitBlockLabels.contains(label) &&
    label != 'NO POCKETS' && label != 'NO BROADWAYS';

const List<List<String>> _hardConflicts = [
  // Direct opposites
  ['NO POCKETS', 'ONLY POCKETS'],
  ['NO SUITED', 'ONLY SUITED'],
  ['NO CONNECTED', 'ONLY CONNECTED'],
  ['NO BROADWAYS', 'ONLY BROADWAYS'],
  ['NO ACES', 'MUST INCLUDE ACE'],
  ['NO BROADWAYS', 'MUST INCLUDE ACE'],
  // Subsets / redundancies
  ['NO BROADWAYS', 'NO ACES'],
  ['NO BROADWAYS', 'NO FACE'],
  ['NO ACES', 'NO AA'],
  // Indirect contradictions
  ['ONLY POCKETS', 'ONLY SUITED'],
  ['ONLY POCKETS', 'ONLY CONNECTED'],
];

bool _conflicts(String a, String b) {
  if (a == b) return true;
  // Direct/indirect
  for (final pair in _hardConflicts) {
    if (pair.contains(a) && pair.contains(b)) return true;
  }
  // At most one suit block
  if (_isSuitBlock(a) && _isSuitBlock(b)) return true;
  // At most one rank block
  if (_isRankBlock(a) && _isRankBlock(b)) return true;
  return false;
}

// ───────────────────────── Random picker ─────────────────────────

/// Picks 1..[maxCount] non-conflicting restrictions at random.
List<Restriction> pickRandomRestrictions(Random rng, {int maxCount = 3}) {
  final pool = [...kAllRestrictions]..shuffle(rng);
  final picked = <Restriction>[];
  final n = 1 + rng.nextInt(maxCount); // 1..maxCount
  for (final r in pool) {
    if (picked.length >= n) break;
    final ok = picked.every((p) => !_conflicts(p.label, r.label));
    if (ok) picked.add(r);
  }
  return picked;
}
