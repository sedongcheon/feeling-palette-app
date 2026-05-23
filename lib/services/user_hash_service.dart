import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 음성 일기 백엔드 호출에 사용하는 익명 user id를 발급/관리한다.
///
/// 첫 호출 시 secure storage에 UUID v4를 1회 저장하고, 이후엔 그 UUID를
/// SHA-256으로 해시해 16진 문자열로 반환한다. 서버에는 원본 UUID가
/// 노출되지 않으며, 앱 재설치 시 새 UUID가 발급된다 (재설치 = 추적 불가).
class UserHashService {
  UserHashService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions:
                  AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility:
                    KeychainAccessibility.first_unlock_this_device,
              ),
            );

  static const _storageKey = 'voice_journal_user_id';

  final FlutterSecureStorage _storage;

  String? _cachedHash;

  Future<String> getUserIdHash() async {
    final cached = _cachedHash;
    if (cached != null) return cached;

    var uuid = await _storage.read(key: _storageKey);
    if (uuid == null || uuid.isEmpty) {
      uuid = _generateUuidV4();
      await _storage.write(key: _storageKey, value: uuid);
    }
    final hash = sha256.convert(utf8.encode(uuid)).toString();
    _cachedHash = hash;
    return hash;
  }

  static String _generateUuidV4() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant
    String h(int b) => b.toRadixString(16).padLeft(2, '0');
    return '${h(bytes[0])}${h(bytes[1])}${h(bytes[2])}${h(bytes[3])}-'
        '${h(bytes[4])}${h(bytes[5])}-'
        '${h(bytes[6])}${h(bytes[7])}-'
        '${h(bytes[8])}${h(bytes[9])}-'
        '${h(bytes[10])}${h(bytes[11])}${h(bytes[12])}${h(bytes[13])}'
        '${h(bytes[14])}${h(bytes[15])}';
  }
}
