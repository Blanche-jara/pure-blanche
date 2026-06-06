import 'package:intl/intl.dart';

/// 숫자/통화/비율 표시 포맷. 통화는 한국 원(₩). 로케일 ko_KR.
class Fmt {
  const Fmt._();

  static final NumberFormat _chips = NumberFormat.decimalPattern('ko');
  static final NumberFormat _won = NumberFormat.currency(
    locale: 'ko_KR',
    symbol: '₩',
    decimalDigits: 0,
  );
  static final NumberFormat _plain = NumberFormat.decimalPattern('ko');
  static final NumberFormat _pct = NumberFormat('0.0', 'ko');
  static final DateFormat _dt = DateFormat('yy.MM.dd HH:mm');

  /// 칩 스택: 천 단위 구분(예: 12,500).
  static String chips(num value) => _chips.format(value);

  /// 금액(원): ₩ + 천 단위 구분, 소수점 없음(예: ₩383,929).
  /// 원화는 소수 단위가 없으므로 [whole] 여부와 무관하게 정수로 표시.
  static String money(num value, {bool whole = false}) => _won.format(value);

  /// 큰 원화 금액 축약(만/억). 차트 축·좁은 표 셀용. 기호 없이 숫자만.
  /// 예: 1,000,000 → "100만", 3,839,290 → "384만", 1.2e9 → "12억", 5,000 → "5,000".
  static String wonCompact(num value) {
    final n = value.abs();
    if (n >= 1e8) {
      final v = value / 1e8;
      return '${v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1)}억';
    }
    if (n >= 1e4) {
      return '${(value / 1e4).round()}만';
    }
    return _plain.format(value);
  }

  /// 비율(%): 소수 첫째 자리(예: 33.3%).
  static String percent(num value) => '${_pct.format(value)}%';

  /// 날짜·시각(예: 26.06.07 01:30).
  static String dateTime(DateTime d) => _dt.format(d);
}
