import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// AdMob identifiers.
///
/// - Debug / profile builds (`kReleaseMode == false`) → Google test IDs
///   so we never accidentally rack up impressions during development.
/// - Release builds → real IDs for this app.
///
/// The App IDs below (the ones ending in `~...`) must match what we put into
/// `AndroidManifest.xml` and `Info.plist`. Ad unit IDs (ending in `/...`) are
/// what the SDK calls at runtime to request a specific ad.
class AdIds {
  AdIds._();

  /// Devices that should receive test ads even in release builds.
  /// Grab an ID by running the app in debug and watching the console —
  /// the SDK prints e.g. `Use RequestConfiguration.Builder.setTestDeviceIds(
  /// Arrays.asList("33BE2250B43518CCDA7DE426D04EE231"))`. Paste those MD5 hashes
  /// here to safely test real ad units without violating AdMob policy.
  static const List<String> testDeviceIds = <String>[
    // 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
  ];

  // ---------- App IDs ----------
  static String get appId {
    if (Platform.isAndroid) {
      return kReleaseMode
          ? 'ca-app-pub-5457202364123068~7469760665'
          : 'ca-app-pub-3940256099942544~3347511713';
    }
    return kReleaseMode
        ? 'ca-app-pub-5457202364123068~2337687639'
        : 'ca-app-pub-3940256099942544~1458002511';
  }

  // ---------- Banner ----------
  static String get banner {
    if (Platform.isAndroid) {
      return kReleaseMode
          ? 'ca-app-pub-5457202364123068/9026371607'
          : 'ca-app-pub-3940256099942544/6300978111';
    }
    return kReleaseMode
        ? 'ca-app-pub-5457202364123068/7406168172'
        : 'ca-app-pub-3940256099942544/2934735716';
  }

  // ---------- Interstitial ----------
  static String get interstitial {
    if (Platform.isAndroid) {
      return kReleaseMode
          ? 'ca-app-pub-5457202364123068/9238124599'
          : 'ca-app-pub-3940256099942544/1033173712';
    }
    return kReleaseMode
        ? 'ca-app-pub-5457202364123068/3985797917'
        : 'ca-app-pub-3940256099942544/4411468910';
  }

  // ---------- Rewarded ----------
  static String get rewarded {
    if (Platform.isAndroid) {
      return kReleaseMode
          ? 'ca-app-pub-5457202364123068/8974400719'
          : 'ca-app-pub-3940256099942544/5224354917';
    }
    return kReleaseMode
        ? 'ca-app-pub-5457202364123068/1835124758'
        : 'ca-app-pub-3940256099942544/1712485313';
  }
}
