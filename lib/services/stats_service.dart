import 'dart:convert';

import 'package:http/http.dart' as http;

/// 접속 통계 + Word Guesser 정답 백엔드 클라이언트.
///
/// 계약: `docs/GUESTBOOK_BACKEND.md` 3.6장.
/// - [hit] 은 사이트 기능이 아니므로 실패를 조용히 삼킨다(사이트에 영향 X).
/// - [fetch] 는 관리자 통계 화면용.
class StatsService {
  StatsService({http.Client? client}) : _client = client ?? http.Client();

  static const String baseUrl = String.fromEnvironment(
    'GUESTBOOK_API',
    defaultValue: 'https://api.pure-blanche.com',
  );
  static const Duration _timeout = Duration(seconds: 8);

  final http.Client _client;

  /// 코드 프로젝트 페이지 접속 1건 기록(fire-and-forget). 실패해도 무시.
  static Future<void> hit(String page) async {
    try {
      await http
          .post(
            Uri.parse('$baseUrl/api/hit'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'page': page}),
          )
          .timeout(_timeout);
    } catch (_) {
      // 통계 실패는 사이트 동작과 무관 — 조용히 무시.
    }
  }

  /// 관리자 통계 조회. GET /api/stats (Bearer).
  Future<StatsData> fetch(String adminToken) async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/stats'),
      headers: {'Authorization': 'Bearer $adminToken'},
    ).timeout(_timeout);
    if (res.statusCode == 401) {
      throw const StatsException('관리자 인증이 만료되었습니다.', authExpired: true);
    }
    if (res.statusCode != 200) {
      throw const StatsException('통계를 불러오지 못했습니다.');
    }
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const StatsException('통계 응답 형식이 올바르지 않습니다.');
    }
    return StatsData.fromJson(decoded);
  }

  void dispose() => _client.close();
}

class StatsData {
  final List<PageStat> pages;
  final List<WgAnswerStat> wgToday;
  const StatsData({required this.pages, required this.wgToday});

  factory StatsData.fromJson(Map<String, dynamic> j) => StatsData(
        pages: (j['pages'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(PageStat.fromJson)
            .toList(),
        wgToday: (j['wgToday'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(WgAnswerStat.fromJson)
            .toList(),
      );
}

class PageStat {
  final String page;
  final int total;
  final int today;
  final int uniqueToday;
  const PageStat({
    required this.page,
    required this.total,
    required this.today,
    required this.uniqueToday,
  });

  factory PageStat.fromJson(Map<String, dynamic> j) => PageStat(
        page: (j['page'] ?? '').toString(),
        total: (j['total'] as num?)?.toInt() ?? 0,
        today: (j['today'] as num?)?.toInt() ?? 0,
        uniqueToday: (j['unique_today'] as num?)?.toInt() ?? 0,
      );
}

class WgAnswerStat {
  final String variant;
  final String answer;
  final int n;
  final int users;
  const WgAnswerStat({
    required this.variant,
    required this.answer,
    required this.n,
    required this.users,
  });

  factory WgAnswerStat.fromJson(Map<String, dynamic> j) => WgAnswerStat(
        variant: (j['variant'] ?? '').toString(),
        answer: (j['answer'] ?? '').toString(),
        n: (j['n'] as num?)?.toInt() ?? 0,
        users: (j['users'] as num?)?.toInt() ?? 0,
      );
}

class StatsException implements Exception {
  const StatsException(this.message, {this.authExpired = false});
  final String message;
  final bool authExpired;
  @override
  String toString() => message;
}
