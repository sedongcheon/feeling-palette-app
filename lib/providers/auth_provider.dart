import 'package:flutter/widgets.dart';

import '../db/database.dart';
import '../services/auth_service.dart';

enum AuthStage { loading, needsSetup, locked, unlocked }

class AuthProvider extends ChangeNotifier with WidgetsBindingObserver {
  AuthProvider({AuthService? service}) : _service = service ?? AuthService() {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  final AuthService _service;

  AuthStage _stage = AuthStage.loading;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _isAuthenticatingBiometric = false;
  int _autoLockDelaySecs = AuthService.defaultAutoLockDelaySeconds;
  DateTime? _backgroundedAt;

  AuthStage get stage => _stage;
  bool get isUnlocked => _stage == AuthStage.unlocked;
  bool get biometricEnabled => _biometricEnabled;
  bool get biometricAvailable => _biometricAvailable;
  int get autoLockDelaySeconds => _autoLockDelaySecs;

  Future<void> _init() async {
    final hasPin = await _service.hasPin();
    _biometricAvailable = await _service.canUseBiometric();
    _biometricEnabled = await _service.biometricEnabled();
    _autoLockDelaySecs = await _service.getAutoLockDelaySeconds();
    _stage = hasPin ? AuthStage.locked : AuthStage.needsSetup;
    notifyListeners();
  }

  Future<void> setAutoLockDelaySeconds(int seconds) async {
    await _service.setAutoLockDelaySeconds(seconds);
    _autoLockDelaySecs = seconds;
    _backgroundedAt = null;
    notifyListeners();
  }

  Future<void> completeSetup({
    required String pin,
    required bool enableBiometric,
  }) async {
    await _service.setPin(pin);
    final canBio = await _service.canUseBiometric();
    final enabled = enableBiometric && canBio;
    await _service.setBiometricEnabled(enabled);
    _biometricAvailable = canBio;
    _biometricEnabled = enabled;
    _stage = AuthStage.unlocked;
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    final ok = await _service.verifyPin(pin);
    if (ok) {
      _stage = AuthStage.unlocked;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> authenticateBiometric() async {
    if (!_biometricEnabled) return false;
    _isAuthenticatingBiometric = true;
    try {
      final ok = await _service.authenticateWithBiometric();
      if (ok) {
        _stage = AuthStage.unlocked;
        notifyListeners();
      }
      return ok;
    } finally {
      _isAuthenticatingBiometric = false;
    }
  }

  void lock() {
    if (_stage == AuthStage.unlocked) {
      _stage = AuthStage.locked;
      notifyListeners();
    }
  }

  Future<void> resetAllData() async {
    await _service.clearAll();
    await AppDatabase.instance.wipe();
    _biometricEnabled = false;
    _autoLockDelaySecs = AuthService.defaultAutoLockDelaySeconds;
    _backgroundedAt = null;
    _stage = AuthStage.needsSetup;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isAuthenticatingBiometric) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_autoLockDelaySecs <= 0) {
        lock();
      } else {
        _backgroundedAt = DateTime.now();
      }
    } else if (state == AppLifecycleState.resumed) {
      final bg = _backgroundedAt;
      _backgroundedAt = null;
      if (bg != null) {
        final elapsed = DateTime.now().difference(bg).inSeconds;
        if (elapsed >= _autoLockDelaySecs) lock();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
