/// 정산표 백엔드 API 클라이언트.
///
/// 계약 문서: `docs/SETTLEMENT_BACKEND.md` (3장 API 계약).
/// 모든 네트워크/타임아웃/파싱 오류는 [SettlementException]으로 변환되어
/// 사용자용 한국어 메시지를 담는다. 앱을 크래시시키지 않는다.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../apps/settlement/models.dart';

class SettlementService {
  SettlementService({http.Client? client}) : _client = client ?? http.Client();

  /// Base URL은 방명록과 같은 Worker. 로컬 개발 시:
  /// `flutter run -d chrome --dart-define=GUESTBOOK_API=http://localhost:8787`
  static const String baseUrl = String.fromEnvironment(
    'GUESTBOOK_API',
    defaultValue: 'https://api.pure-blanche.com',
  );

  static const Duration _timeout = Duration(seconds: 10);

  final http.Client _client;

  // ─────────────────────────── 프로젝트 ───────────────────────────

  /// 새 정산표 생성. 서버가 공유 코드와 소유자 토큰을 발급한다.
  Future<CreatedProject> create({
    required String name,
    required List<String> memberNames,
  }) async {
    final decoded = await _send(
      'POST',
      '/api/settlement',
      body: {'name': name, 'members': memberNames},
      expect: 201,
    );
    final project = _projectFrom(decoded);
    final token = decoded['ownerToken'];
    return CreatedProject(
      project: project,
      ownerToken: token is String ? token : null,
    );
  }

  /// 공유 코드로 정산표 조회.
  Future<SettlementProject> fetch(String code) async =>
      _projectFrom(await _send('GET', '/api/settlement/$code'));

  Future<SettlementProject> rename(String code, String name) async =>
      _projectFrom(await _send('PATCH', '/api/settlement/$code',
          body: {'name': name}));

  /// 정산표 삭제. 소유자 토큰(생성한 브라우저)이나 관리자 토큰이 필요하다.
  Future<void> deleteProject(String code, {String? ownerToken}) async {
    await _send('DELETE', '/api/settlement/$code', token: ownerToken);
  }

  // ─────────────────────────── 인원 ───────────────────────────

  Future<SettlementProject> addMember(String code, String name) async =>
      _projectFrom(await _send('POST', '/api/settlement/$code/members',
          body: {'name': name}));

  Future<SettlementProject> renameMember(
    String code,
    String memberId,
    String name,
  ) async =>
      _projectFrom(await _send(
          'PATCH', '/api/settlement/$code/members/$memberId',
          body: {'name': name}));

  Future<SettlementProject> removeMember(String code, String memberId) async =>
      _projectFrom(
          await _send('DELETE', '/api/settlement/$code/members/$memberId'));

  // ─────────────────────────── 지출 ───────────────────────────

  Future<SettlementProject> addExpense(
    String code, {
    required String title,
    required int amount,
    required String payerId,
    required List<String> participantIds,
  }) async =>
      _projectFrom(await _send('POST', '/api/settlement/$code/expenses', body: {
        'title': title,
        'amount': amount,
        'payerId': payerId,
        'participantIds': participantIds,
      }));

  Future<SettlementProject> updateExpense(
    String code,
    String expenseId, {
    required String title,
    required int amount,
    required String payerId,
    required List<String> participantIds,
  }) async =>
      _projectFrom(await _send(
          'PATCH', '/api/settlement/$code/expenses/$expenseId',
          body: {
            'title': title,
            'amount': amount,
            'payerId': payerId,
            'participantIds': participantIds,
          }));

  Future<SettlementProject> removeExpense(String code, String expenseId) async =>
      _projectFrom(
          await _send('DELETE', '/api/settlement/$code/expenses/$expenseId'));

  // ─────────────────────────── 직접 송금 ───────────────────────────

  Future<SettlementProject> addTransfer(
    String code, {
    required String fromId,
    required String toId,
    required int amount,
    String memo = '',
  }) async =>
      _projectFrom(
          await _send('POST', '/api/settlement/$code/transfers', body: {
        'fromId': fromId,
        'toId': toId,
        'amount': amount,
        'memo': memo,
      }));

  Future<SettlementProject> removeTransfer(
          String code, String transferId) async =>
      _projectFrom(
          await _send('DELETE', '/api/settlement/$code/transfers/$transferId'));

  // ─────────────────────────── 입금 처리 ───────────────────────────

  /// "입금했습니다"(settled=true) / 취소(false). 여러 건을 한 번에 보낼 수 있다.
  Future<SettlementProject> setLegs(
    String code, {
    required List<({String expenseId, String debtorId})> legs,
    required bool settled,
  }) async =>
      _projectFrom(await _send('PUT', '/api/settlement/$code/legs', body: {
        'legs': [
          for (final l in legs)
            {'expenseId': l.expenseId, 'debtorId': l.debtorId}
        ],
        'settled': settled,
      }));

  // ─────────────────────────── 내부 ───────────────────────────

  SettlementProject _projectFrom(Map<String, dynamic> decoded) {
    final p = decoded['project'];
    if (p is! Map<String, dynamic>) {
      throw const SettlementException('정산표 응답 형식이 올바르지 않습니다.');
    }
    return SettlementProject.fromJson(p);
  }

  /// 공통 요청. 실패는 전부 [SettlementException] 으로 변환한다.
  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
    int expect = 200,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.Request(method, uri);
    request.headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    try {
      final streamed = await _client.send(request).timeout(_timeout);
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == expect) {
        if (res.bodyBytes.isEmpty) return const {};
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! Map<String, dynamic>) {
          throw const SettlementException('정산표 응답 형식이 올바르지 않습니다.');
        }
        return decoded;
      }

      throw SettlementException(
        _detailFromBody(res.bodyBytes) ?? _fallbackMessage(res.statusCode),
        code: _codeFromBody(res.bodyBytes),
        status: res.statusCode,
      );
    } on SettlementException {
      rethrow;
    } on TimeoutException {
      throw const SettlementException('서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해주세요.');
    } catch (_) {
      throw const SettlementException('서버에 연결하지 못했습니다. 네트워크 상태를 확인해주세요.');
    }
  }

  static String _fallbackMessage(int status) => switch (status) {
        404 => '정산표를 찾을 수 없습니다. 링크를 다시 확인해주세요.',
        401 => '권한이 없습니다.',
        _ => '요청을 처리하지 못했습니다. ($status)',
      };

  static Map<String, dynamic>? _decodeBody(List<int> bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static String? _detailFromBody(List<int> bytes) {
    final detail = _decodeBody(bytes)?['detail'];
    return detail is String && detail.isNotEmpty ? detail : null;
  }

  static String? _codeFromBody(List<int> bytes) {
    final code = _decodeBody(bytes)?['error'];
    return code is String ? code : null;
  }
}

/// 생성 결과 — 프로젝트 + 소유자 토큰(이 브라우저에 보관해야 삭제 가능).
class CreatedProject {
  final SettlementProject project;
  final String? ownerToken;

  const CreatedProject({required this.project, this.ownerToken});
}

/// 사용자에게 그대로 보여줄 수 있는 한국어 메시지를 담은 예외.
class SettlementException implements Exception {
  final String message;

  /// 서버 `error` 코드(`not_found`, `member_in_use` 등). 없으면 null.
  final String? code;

  final int? status;

  const SettlementException(this.message, {this.code, this.status});

  @override
  String toString() => message;
}
