/// 카드 인코딩: 0..51 정수. `rank = card >> 2` (0=2 … 12=A), `suit = card & 3`.
/// 랭크 문자 `23456789TJQKA`, 수트 문자 `cdhs`(0=c,1=d,2=h,3=s).
class Cards {
  const Cards._();

  static const String ranks = '23456789TJQKA';
  static const String suits = 'cdhs';

  static int rankOf(int card) => card >> 2;
  static int suitOf(int card) => card & 3;

  static int make(int rank, int suit) => (rank << 2) | suit;

  /// "Ah" → 정수. 대소문자 무시. 실패 시 예외.
  static int parse(String s) {
    if (s.length != 2) throw FormatException('잘못된 카드: $s');
    final r = ranks.indexOf(s[0].toUpperCase());
    final su = suits.indexOf(s[1].toLowerCase());
    if (r < 0 || su < 0) throw FormatException('잘못된 카드: $s');
    return make(r, su);
  }

  /// 정수 → "Ah".
  static String toLabel(int card) =>
      '${ranks[rankOf(card)]}${suits[suitOf(card)]}';

  /// 표시용 수트 기호.
  static String suitSymbol(int suit) => const ['♣', '♦', '♥', '♠'][suit];

  /// 전체 52장 덱.
  static List<int> deck() => List<int>.generate(52, (i) => i);
}
