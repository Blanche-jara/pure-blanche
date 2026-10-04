import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../engine/models.dart';

class SaveRepository {
  static const key = 'sword_upgrade.save.v1';
  // Old open tabs keep writing v1. Never expose schema 4 to the old reader.
  static const currentKey = 'sword_upgrade.save.v4';
  static const preUpgradeKey = '$key.beforeSchema4';
  final SharedPreferences preferences;
  Future<void> _writes = Future.value();
  SaveRepository(this.preferences);
  GameState? load() {
    final raw = preferences.getString(currentKey) ?? preferences.getString(key);
    if (raw == null) return null;
    return decode(raw);
  }

  Future<void> preserveInvalidSave() async {
    final sourceKey = preferences.containsKey(currentKey) ? currentKey : key;
    final raw = preferences.getString(sourceKey);
    if (raw != null) await preferences.setString('$sourceKey.recovery', raw);
  }

  Future<void> preserveBeforeUpgrade(GameState? state) async {
    if (state == null ||
        state.loadedSchemaVersion >= GameState.schemaVersion ||
        preferences.containsKey(preUpgradeKey)) {
      return;
    }
    final raw = preferences.getString(key);
    if (raw != null && !await preferences.setString(preUpgradeKey, raw)) {
      throw StateError('업데이트 전 저장의 복구 사본을 보존하지 못했습니다.');
    }
  }

  Future<void> save(GameState state) {
    final code = encode(state);
    final next = _writes.catchError((Object _) {}).then((_) async {
      if (!await preferences.setString(currentKey, code)) {
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
