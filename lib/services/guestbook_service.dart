import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// 방명록 백엔드 API 클라이언트.
///
/// 계약 문서: `docs/GUESTBOOK_BACKEND.md` (3장 API 계약).
/// 모든 네트워크/타임아웃/파싱 오류는 [GuestbookException]으로 변환되어
/// 사용자용 한국어 메시지를 담는다. 앱을 크래시시키지 않는다.
class GuestbookService {
  GuestbookService({http.Client? client}) : _client = client ?? http.Client();

  /// Base URL. 로컬 개발 시:
  /// `flutter run -d chrome --dart-define=GUESTBOOK_API=http://localhost:8787`
  static const String baseUrl = String.fromEnvironment(
    'GUESTBOOK_API',
    defaultValue: 'https://api.pure-blanche.com',
  );

  static const Duration _timeout = Duration(seconds: 10);

  final http.Client _client;

  /// 최신 방명록 목록(최신순). GET /api/guestbook
  /// [adminToken] 을 주면 Bearer 로 요청 → 응답에 ip/지역 필드가 포함된다(관리자).
  Future<List<GuestEntry>> fetchEntries({String? adminToken}) async {
    final uri = Uri.parse('$baseUrl/api/guestbook');
    try {
      final headers =
          adminToken != null ? {'Authorization': 'Bearer $adminToken'} : null;
      final res = await _client.get(uri, headers: headers).timeout(_timeout);
      if (res.statusCode != 200) {
        throw GuestbookException(_detailFromBody(res.bodyBytes) ??
            '방명록을 불러오지 못했습니다. (${res.statusCode})');
      }
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final list = (decoded is Map<String, dynamic>) ? decoded['messages'] : null;
      if (list is! List) {
        throw const GuestbookException('방명록 응답 형식이 올바르지 않습니다.');
      }
      return list
          .whereType<Map<String, dynamic>>()
          .map(GuestEntry.fromJson)
          .toList();
    } on GuestbookException {
      rethrow;
    } on TimeoutException {
      throw const GuestbookException('서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해주세요.');
    } catch (_) {
      throw const GuestbookException('방명록을 불러오지 못했습니다. 네트워크 상태를 확인해주세요.');
    }
  }

  /// 새 방명록 작성. POST /api/guestbook → 201이면 생성된 [GuestEntry] 반환.
  Future<GuestEntry> submit({
    required String name,
    required String message,
  }) async {
    final uri = Uri.parse('$baseUrl/api/guestbook');
    try {
      final res = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'name': name, 'message': message}),
          )
          .timeout(_timeout);

      if (res.statusCode == 201) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        final msg = (decoded is Map<String, dynamic>) ? decoded['message'] : null;
        if (msg is! Map<String, dynamic>) {
          throw const GuestbookException('작성 응답 형식이 올바르지 않습니다.');
        }
        return GuestEntry.fromJson(msg);
      }

      // 그 외 상태코드: 백엔드가 내려준 detail/error를 사용자 메시지로.
      throw GuestbookException(
          _detailFromBody(res.bodyBytes) ?? '작성에 실패했습니다. (${res.statusCode})');
    } on GuestbookException {
      rethrow;
    } on TimeoutException {
      throw const GuestbookException('서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해주세요.');
    } catch (_) {
      throw const GuestbookException('작성에 실패했습니다. 네트워크 상태를 확인해주세요.');
    }
  }

  /// 관리자 비밀번호(토큰) 검증. POST /api/admin/verify (Bearer).
  /// 올바르면 true, 틀리면 false. 네트워크/타임아웃 오류는 예외.
  Future<bool> verifyAdmin(String token) async {
    final uri = Uri.parse('$baseUrl/api/admin/verify');
    try {
      final res = await _client.post(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(_timeout);
      return res.statusCode == 200;
    } on TimeoutException {
      throw const GuestbookException('서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해주세요.');
    } catch (_) {
      throw const GuestbookException('인증 서버에 연결할 수 없습니다.');
    }
  }

  /// 관리자: 글 삭제. DELETE /api/guestbook/{id} (Bearer).
  Future<void> deleteEntry(int id, {required String adminToken}) async {
    final uri = Uri.parse('$baseUrl/api/guestbook/$id');
    try {
      final res = await _client.delete(
        uri,
        headers: {'Authorization': 'Bearer $adminToken'},
      ).timeout(_timeout);
      if (res.statusCode == 200) return;
      if (res.statusCode == 401) {
        throw const GuestbookException('관리자 인증이 만료되었습니다. 다시 로그인해주세요.',
            authExpired: true);
      }
      throw GuestbookException(
          _detailFromBody(res.bodyBytes) ?? '삭제에 실패했습니다. (${res.statusCode})');
    } on GuestbookException {
      rethrow;
    } on TimeoutException {
      throw const GuestbookException('서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해주세요.');
    } catch (_) {
      throw const GuestbookException('삭제에 실패했습니다. 네트워크 상태를 확인해주세요.');
    }
  }

  /// 관리자: 글 수정. PATCH /api/guestbook/{id} (Bearer). 수정된 [GuestEntry] 반환.
  Future<GuestEntry> updateEntry(
    int id, {
    required String name,
    required String message,
    required String adminToken,
  }) async {
    final uri = Uri.parse('$baseUrl/api/guestbook/$id');
    try {
      final res = await _client
          .patch(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $adminToken',
            },
            body: jsonEncode({'name': name, 'message': message}),
          )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        final msg = (decoded is Map<String, dynamic>) ? decoded['message'] : null;
        if (msg is! Map<String, dynamic>) {
          throw const GuestbookException('수정 응답 형식이 올바르지 않습니다.');
        }
        return GuestEntry.fromJson(msg);
      }
      if (res.statusCode == 401) {
        throw const GuestbookException('관리자 인증이 만료되었습니다. 다시 로그인해주세요.',
            authExpired: true);
      }
      throw GuestbookException(
          _detailFromBody(res.bodyBytes) ?? '수정에 실패했습니다. (${res.statusCode})');
    } on GuestbookException {
      rethrow;
    } on TimeoutException {
      throw const GuestbookException('서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해주세요.');
    } catch (_) {
      throw const GuestbookException('수정에 실패했습니다. 네트워크 상태를 확인해주세요.');
    }
  }

  /// 에러 응답 본문에서 사용자용 문구(detail) 또는 error 코드를 추출한다.
  /// 파싱 불가 시 null.
  String? _detailFromBody(List<int> bodyBytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bodyBytes));
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.trim().isNotEmpty) return detail;
        final error = decoded['error'];
        if (error is String && error.trim().isNotEmpty) return error;
      }
    } catch (_) {
      // 파싱 실패 → null 반환.
    }
    return null;
  }

  void dispose() => _client.close();
}

/// 방명록 한 항목.
class GuestEntry {
  const GuestEntry({
    required this.id,
    required this.name,
    required this.message,
    required this.createdAt,
    this.ip,
    this.country,
    this.region,
    this.city,
    this.latitude,
    this.longitude,
    this.postal,
    this.isp,
  });

  final int id;
  final String name;
  final String message;

  /// 로컬 시간대로 변환된 작성 시각.
  final DateTime createdAt;

  // 관리자 조회 시에만 채워짐(공개 응답엔 없음). null 가능.
  final String? ip;
  final String? country;
  final String? region;
  final String? city;
  final String? latitude;
  final String? longitude;
  final String? postal;
  final String? isp;

  factory GuestEntry.fromJson(Map<String, dynamic> json) {
    String? s(dynamic v) {
      if (v == null) return null;
      final t = v.toString().trim();
      return t.isEmpty ? null : t;
    }

    return GuestEntry(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      message: (json['message'] as String?) ?? '',
      createdAt: _parseCreatedAt(json['created_at'] as String?),
      ip: s(json['ip']),
      country: s(json['country']),
      region: s(json['region']),
      city: s(json['city']),
      latitude: s(json['latitude']),
      longitude: s(json['longitude']),
      postal: s(json['postal']),
      isp: s(json['isp']),
    );
  }

  /// 국가/지역/도시를 " · " 로 합친 표시 문자열. 정보 없으면 null.
  String? get locationLabel {
    final parts = [country, region, city]
        .where((e) => e != null && e.isNotEmpty)
        .toList();
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// 구글맵 URL. 위경도가 있으면 좌표로, 없으면 지역명 검색으로. 정보 없으면 null.
  String? get mapUrl {
    if (latitude != null && longitude != null) {
      return 'https://www.google.com/maps?q=$latitude,$longitude';
    }
    final q = locationLabel;
    if (q != null) {
      final query = Uri.encodeComponent(q.replaceAll(' · ', ' '));
      return 'https://www.google.com/maps/search/?api=1&query=$query';
    }
    return null;
  }

  /// `created_at`은 UTC "YYYY-MM-DD HH:MM:SS". 'T' 구분자 + 'Z'를 붙여
  /// UTC로 파싱한 뒤 로컬로 변환한다.
  static DateTime _parseCreatedAt(String? raw) {
    if (raw == null || raw.isEmpty) return DateTime.now();
    final normalized = '${raw.trim().replaceFirst(' ', 'T')}Z';
    final parsed = DateTime.tryParse(normalized);
    return (parsed ?? DateTime.now().toUtc()).toLocal();
  }

  /// 로컬 'YYYY.MM.DD' 표시용.
  String get localDate {
    final d = createdAt;
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}.$mm.$dd';
  }
}

/// 사용자에게 그대로 보여줄 수 있는 한국어 메시지를 담은 예외.
class GuestbookException implements Exception {
  const GuestbookException(this.message, {this.authExpired = false});
  final String message;

  /// 관리자 인증 만료/실패(401)로 인한 예외면 true. UI가 관리자 모드를 해제하는 데 사용.
  final bool authExpired;

  @override
  String toString() => message;
}
