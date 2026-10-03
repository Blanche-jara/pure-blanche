import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../engine/models.dart';

class SaveRepository {
  static const key = 'sword_upgrade.save.v1';
  final SharedPreferences preferences;
  Future<void> _writes = Future.value();
  SaveRepository(this.preferences);
  GameState? load() {
    final raw = preferences.getString(key);
    if (raw == null) return null;
    return decode(raw);
  }

  Future<void> preserveInvalidSave() async {
    final raw = preferences.getString(key);
    if (raw != null) await preferences.setString('$key.recovery', raw);
  }

  Future<void> save(GameState state) {
    final code = encode(state);
    final next = _writes.catchError((Object _) {}).then((_) async {
      if (!await preferences.setString(key, code)) {
        throw StateError('브라우저에 저장하지 못했습니다. 백업 코드를 보관하세요.');
      }
    });
    _writes = next;
    return next;
  }

  static String encode(GameState state) {
    final payload = jsonEncode(state.toJson());
    return 'SU1.${base64Url.encode(utf8.encode(jsonEncode({'payload': payload, 'checksum': _checksum(payload)})))}';
  }

  static GameState decode(String code) {
    try {
      final trimmed = code.trim();
      if (!trimmed.startsWith('SU1.') || trimmed.length > 100000) {
        throw const FormatException('올바른 SWORD 백업 코드가 아닙니다.');
      }
      final envelope = checkedMap(
        jsonDecode(utf8.decode(base64Url.decode(trimmed.substring(4)))),
      );
      final payload = envelope['payload'];
      if (payload is! String || envelope['checksum'] != _checksum(payload)) {
        throw const FormatException('백업 코드가 손상되었습니다.');
      }
      return GameState.fromJson(jsonDecode(payload));
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('백업 코드를 읽을 수 없습니다.');
    }
  }

  static String _checksum(String value) {
    var hash = 0;
    for (final byte in utf8.encode(value)) {
      hash = (hash * 31 + byte) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
