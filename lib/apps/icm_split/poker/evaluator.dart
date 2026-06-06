/// 텍사스 홀덤 핸드 평가기.
///
/// `eval7`은 7장에서 최선의 5장을 골라 비교 가능한 정수를 반환한다(클수록 강함, 동일 정수=정확한 타이).
/// 정확성 우선으로 C(7,5)=21 조합을 [eval5]로 평가해 최댓값을 취한다.
/// 점수 패킹: `(category<<20) | t1<<16 | t2<<12 | t3<<8 | t4<<4 | t5`.
/// category 8=스트레이트플러시 … 0=하이카드, tier는 랭크값(0..12).
class HandEvaluator {
  const HandEvaluator._();

  // 카테고리 상수.
  static const int highCard = 0;
  static const int pair = 1;
  static const int twoPair = 2;
  static const int trips = 3;
  static const int straight = 4;
  static const int flush = 5;
  static const int fullHouse = 6;
  static const int quads = 7;
  static const int straightFlush = 8;

  /// 5장 평가 → 패킹 점수.
  static int eval5(List<int> cards) {
    assert(cards.length == 5);
    final counts = List<int>.filled(13, 0);
    final suitCounts = List<int>.filled(4, 0);
    for (final c in cards) {
      counts[c >> 2]++;
      suitCounts[c & 3]++;
    }
    final isFlush = suitCounts.any((s) => s >= 5);

    var mask = 0;
    for (var r = 0; r < 13; r++) {
      if (counts[r] > 0) mask |= 1 << r;
    }
    final sh = _straightHigh(mask);

    final quad = _rankWithCount(counts, 4);
    final trip = _rankWithCount(counts, 3);
    final pairsDesc = <int>[
      for (var r = 12; r >= 0; r--)
        if (counts[r] == 2) r,
    ];

    if (isFlush && sh >= 0) return _score(straightFlush, [sh]);
    if (quad >= 0) {
      return _score(quads, [
        quad,
        _topExcluding(counts, {quad}, 1).first,
      ]);
    }
    if (trip >= 0 && pairsDesc.isNotEmpty) {
      return _score(fullHouse, [trip, pairsDesc.first]);
    }
    if (isFlush) return _score(flush, _topExcluding(counts, {}, 5));
    if (sh >= 0) return _score(straight, [sh]);
    if (trip >= 0) {
      return _score(trips, [
        trip,
        ..._topExcluding(counts, {trip}, 2),
      ]);
    }
    if (pairsDesc.length >= 2) {
      final hi = pairsDesc[0], lo = pairsDesc[1];
      return _score(twoPair, [
        hi,
        lo,
        _topExcluding(counts, {hi, lo}, 1).first,
      ]);
    }
    if (pairsDesc.length == 1) {
      final p = pairsDesc[0];
      return _score(pair, [
        p,
        ..._topExcluding(counts, {p}, 3),
      ]);
    }
    return _score(highCard, _topExcluding(counts, {}, 5));
  }

  /// 7장 평가 → 패킹 점수(최선 5장).
  static int eval7(List<int> cards) {
    assert(cards.length == 7);
    var best = -1;
    final five = List<int>.filled(5, 0);
    for (var i = 0; i < 7; i++) {
      for (var j = i + 1; j < 7; j++) {
        var idx = 0;
        for (var k = 0; k < 7; k++) {
          if (k == i || k == j) continue;
          five[idx++] = cards[k];
        }
        final s = eval5(five);
        if (s > best) best = s;
      }
    }
    return best;
  }

  // ---- 내부 헬퍼 ----

  /// 13비트 랭크 마스크에서 스트레이트 최고 랭크. 없으면 -1. 휠(A2345)=5(랭크3).
  static int _straightHigh(int mask) {
    for (var h = 12; h >= 4; h--) {
      final need =
          (1 << h) |
          (1 << (h - 1)) |
          (1 << (h - 2)) |
          (1 << (h - 3)) |
          (1 << (h - 4));
      if ((mask & need) == need) return h;
    }
    const wheel = (1 << 12) | (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3);
    if ((mask & wheel) == wheel) return 3; // 5-high
    return -1;
  }

  static int _rankWithCount(List<int> counts, int n) {
    for (var r = 12; r >= 0; r--) {
      if (counts[r] == n) return r;
    }
    return -1;
  }

  /// counts에서 [exclude]를 뺀 나머지 중 상위 [n]개 랭크(내림차순).
  static List<int> _topExcluding(List<int> counts, Set<int> exclude, int n) {
    final out = <int>[];
    for (var r = 12; r >= 0 && out.length < n; r--) {
      if (counts[r] > 0 && !exclude.contains(r)) out.add(r);
    }
    return out;
  }

  static int _score(int category, List<int> tiers) {
    var s = category;
    for (var i = 0; i < 5; i++) {
      s = (s << 4) | (i < tiers.length ? tiers[i] : 0);
    }
    return s;
  }
}
