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
  bool _hasPin = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _isAuthenticatingBiometric = false;
  int _autoLockDelaySecs = AuthService.defaultAutoLockDelaySeconds;
  DateTime? _backgroundedAt;

  AuthStage get stage => _stage;
  bool get isUnlocked => _stage == AuthStage.unlocked;
  bool get hasPin => _hasPin;
  bool get biometricEnabled => _biometricEnabled;
  bool get biometricAvailable => _biometricAvailable;
  int get autoLockDelaySeconds => _autoLockDelaySecs;

  Future<void> _init() async {
    // 전체 init이 5초 이상 걸리면(예: Samsung KeyStore 첫 init 무한 대기) 안전하게
    // needsSetup으로 폴백해 사용자가 "흰 화면 + 동그라미 빙빙" 상태에 갇히지 않게 한다.
    // AuthService 내부 read도 각각 3초 timeout이 걸려있어 정상 케이스는 거의 즉시 완료.
    try {
      await _loadAll().timeout(const Duration(seconds: 5));
    } catch (_) {
      _hasPin = false;
      _biometricAvailable = false;
      _biometricEnabled = false;
      _autoLockDelaySecs = AuthService.defaultAutoLockDelaySeconds;
      _stage = AuthStage.unlocked;
      notifyListeners();
    }
  }

  Future<void> _loadAll() async {
    _hasPin = await _service.hasPin();
    _biometricAvailable = await _service.canUseBiometric();
    _biometricEnabled = await _service.biometricEnabled();
    _autoLockDelaySecs = await _service.getAutoLockDelaySeconds();
    _stage = _hasPin ? AuthStage.locked : AuthStage.unlocked;
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
    _hasPin = true;
    _biometricAvailable = canBio;
    _biometricEnabled = enabled;
    _stage = AuthStage.unlocked;
    notifyListeners();
  }

  /// Removes PIN & biometric settings so the app no longer requires unlock.
  /// Diary data and autoLockDelay preference are kept. Used by the
  /// "Use app lock" toggle in Settings when the user turns it off.
  Future<void> disableLock() async {
    await _service.clearPin();
    _hasPin = false;
    _biometricEnabled = false;
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

  Future<bool> authenticateBiometric({required String localizedReason}) async {
    if (!_biometricEnabled) return false;
    _isAuthenticatingBiometric = true;
    try {
      final ok = await _service.authenticateWithBiometric(
        localizedReason: localizedReason,
      );
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
    // PIN이 설정돼 있을 때만 잠금. 잠금 옵션 OFF 사용자는 백그라운드 복귀 시에도
    // unlocked 유지 (LockScreen에서 PIN 입력 못 하니까 갇히는 걸 방지).
    if (_stage == AuthStage.unlocked && _hasPin) {
      _stage = AuthStage.locked;
      notifyListeners();
    }
  }

  Future<void> resetAllData() async {
    await _service.clearAll();
    await AppDatabase.instance.wipe();
    _hasPin = false;
    _biometricEnabled = false;
    _autoLockDelaySecs = AuthService.defaultAutoLockDelaySeconds;
    _backgroundedAt = null;
    _stage = AuthStage.unlocked;
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
