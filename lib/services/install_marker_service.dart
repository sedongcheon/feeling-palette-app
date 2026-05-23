import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// iOS Keychain은 default access group일 때 앱 삭제 후에도 일부 item이
/// 잔존하는 케이스가 보고된다 (iOS 26.5에서 확인). 그 결과 사용자가 앱을
/// 삭제하고 새로 설치해도 [DiaryProvider]의 `bonus_YYYY-MM-DD` 보너스
/// 카운터가 그대로 살아 있어 "1/3"이 아닌 "1/6" 같은 stale max로 보인다.
///
/// 해결: install 여부를 NSUserDefaults / SharedPreferences(앱 삭제 시
/// 정상 cleanup됨)에 marker로 기록하고, 부트 시 marker가 없으면 신규
/// install로 간주해 보너스 키만 골라서 삭제한다. PIN 등 secure storage의
/// 다른 키는 보존해야 하므로 prefix 매칭만 수행한다.
class InstallMarkerService {
  static const _markerKey = 'install_marker_v1';
  static const _bonusKeyPrefix = 'bonus_';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// 첫 부트 시 호출. 이미 마커가 있으면 no-op (단발성).
  ///
  /// 어떤 단계에서 hang하더라도 부트가 막히면 안 되므로 각 호출에 짧은
  /// timeout. 실패 시 silently skip — 다음 부트에 재시도.
  static Future<void> cleanupOnFirstInstall() async {
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 2));
      if (prefs.getBool(_markerKey) == true) return;

      // 신규 install 또는 마커 없는 기존 install. 보너스 키만 삭제.
      try {
        final all =
            await _storage.readAll().timeout(const Duration(seconds: 3));
        for (final key in all.keys) {
          if (key.startsWith(_bonusKeyPrefix)) {
            await _storage
                .delete(key: key)
                .timeout(const Duration(seconds: 2));
          }
        }
      } catch (_) {
        // secure storage 작업 실패는 무시. marker만 설정해 다음 부트에
        // readAll로 hang하지 않도록.
      }

      await prefs
          .setBool(_markerKey, true)
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      // SharedPreferences 자체가 hang하면 이번 부트는 cleanup 포기.
      // 다음 부트에 다시 시도.
    }
  }
}
