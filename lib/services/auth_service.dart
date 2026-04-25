import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AuthService {
  static const _pinHashKey = 'lock_pin_hash';
  static const _pinSaltKey = 'lock_pin_salt';
  static const _biometricEnabledKey = 'lock_biometric_enabled';
  static const _autoLockDelayKey = 'lock_auto_lock_delay_seconds';

  // resetOnError: KeyStore 키가 무효화되면(앱 재설치/OS 업데이트/Samsung 키 회전 등)
  // EncryptedSharedPreferences 복호화가 실패하며 읽기가 무한 대기에 빠지는 케이스가 있다.
  // 이 옵션이 true면 복호화 실패 시 저장소를 자동 리셋해 앱이 멈추지 않게 한다.
  // 트레이드오프: 사용자는 PIN/생체인증 설정을 다시 해야 함.
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final LocalAuthentication _localAuth = LocalAuthentication();

  // 일부 Samsung 기기에서 첫 설치 후 EncryptedSharedPreferences/KeyStore 초기화가
  // 무한 대기에 빠지는 케이스가 있다. 모든 read 작업에 timeout을 걸어서
  // 일정 시간 안에 응답이 없으면 null로 폴백 → "값 없음" 처리 → 앱이 멈추지 않음.
  static const _readTimeout = Duration(seconds: 3);

  Future<String?> _readWithTimeout(String key) async {
    try {
      return await _storage.read(key: key).timeout(_readTimeout);
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasPin() async {
    final hash = await _readWithTimeout(_pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  Future<bool> biometricEnabled() async {
    return (await _readWithTimeout(_biometricEnabledKey)) == '1';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: _biometricEnabledKey,
      value: enabled ? '1' : '0',
    );
  }

  static const int defaultAutoLockDelaySeconds = 5;

  Future<int> getAutoLockDelaySeconds() async {
    final raw = await _readWithTimeout(_autoLockDelayKey);
    return int.tryParse(raw ?? '') ?? defaultAutoLockDelaySeconds;
  }

  Future<void> setAutoLockDelaySeconds(int seconds) async {
    await _storage.write(key: _autoLockDelayKey, value: seconds.toString());
  }

  Future<bool> canUseBiometric() async {
    // 일부 Samsung 기기에서 local_auth 호출이 멈추는 케이스 대비.
    try {
      return await _checkBiometric().timeout(_readTimeout);
    } catch (_) {
      return false;
    }
  }

  Future<bool> _checkBiometric() async {
    try {
      if (!await _localAuth.isDeviceSupported()) return false;
      if (!await _localAuth.canCheckBiometrics) return false;
      final available = await _localAuth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: '생체인증으로 잠금을 해제합니다',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _storage.write(key: _pinSaltKey, value: salt);
    await _storage.write(key: _pinHashKey, value: hash);
  }

  Future<bool> verifyPin(String pin) async {
    final salt = await _readWithTimeout(_pinSaltKey);
    final hash = await _readWithTimeout(_pinHashKey);
    if (salt == null || hash == null) return false;
    return _hashPin(pin, salt) == hash;
  }

  Future<void> clearAll() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinSaltKey);
    await _storage.delete(key: _biometricEnabledKey);
    await _storage.delete(key: _autoLockDelayKey);
  }

  String _generateSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return base64Encode(bytes);
  }

  String _hashPin(String pin, String salt) {
    final saltBytes = utf8.encode(salt);
    final pinBytes = utf8.encode(pin);
    var digest = sha256.convert([...saltBytes, ...pinBytes]).bytes;
    for (var i = 0; i < 5000; i++) {
      digest = sha256.convert([...digest, ...saltBytes]).bytes;
    }
    return base64Encode(digest);
  }
}
