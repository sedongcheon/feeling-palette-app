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

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> hasPin() async {
    final hash = await _storage.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  Future<bool> biometricEnabled() async {
    return (await _storage.read(key: _biometricEnabledKey)) == '1';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: _biometricEnabledKey,
      value: enabled ? '1' : '0',
    );
  }

  static const int defaultAutoLockDelaySeconds = 5;

  Future<int> getAutoLockDelaySeconds() async {
    final raw = await _storage.read(key: _autoLockDelayKey);
    return int.tryParse(raw ?? '') ?? defaultAutoLockDelaySeconds;
  }

  Future<void> setAutoLockDelaySeconds(int seconds) async {
    await _storage.write(key: _autoLockDelayKey, value: seconds.toString());
  }

  Future<bool> canUseBiometric() async {
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
    final salt = await _storage.read(key: _pinSaltKey);
    final hash = await _storage.read(key: _pinHashKey);
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
