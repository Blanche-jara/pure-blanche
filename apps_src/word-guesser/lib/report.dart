import 'dart:convert';

import 'package:http/http.dart' as http;

/// Word Guesser 가 수렴한 "오늘의 정답"을 pure-blanche 백엔드로 보고한다.
/// fire-and-forget — 실패해도 솔버 동작에 영향을 주지 않는다.
///
/// 계약: `docs/GUESTBOOK_BACKEND.md` 3.6장 (POST /api/wg/answer).
const String _apiBase = String.fromEnvironment(
  'WG_API',
  defaultValue: 'https://api.pure-blanche.com',
);

/// [variant] 는 kakao5 / kordle6 / kordle12 중 하나.
Future<void> reportAnswer(String variant, String answer) async {
  try {
    await http
        .post(
          Uri.parse('$_apiBase/api/wg/answer'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'variant': variant, 'answer': answer}),
        )
        .timeout(const Duration(seconds: 8));
  } catch (_) {
    // 통계 보고 실패는 무시.
  }
}
