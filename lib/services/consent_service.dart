import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Gathers the consent required before requesting ads:
///   1. UMP (GDPR / CCPA) via Google's User Messaging Platform
///   2. iOS App Tracking Transparency (only on iOS 14+)
///
/// Running this is idempotent within a session. UMP itself persists the
/// user's choice, so subsequent launches only re-trigger it when the stored
/// consent becomes stale.
class ConsentService {
  static final instance = ConsentService._();
  ConsentService._();

  bool _inFlight = false;
  bool _done = false;

  bool get isDone => _done;

  Future<void> gather() async {
    if (_done || _inFlight) return;
    _inFlight = true;
    try {
      await _runUmp();
      await _runAtt();
      _done = true;
    } finally {
      _inFlight = false;
    }
  }

  Future<void> _runUmp() async {
    try {
      await _requestConsentInfoUpdate();
      await _loadAndShowFormIfRequired();
    } catch (e) {
      if (kDebugMode) debugPrint('[ConsentService] UMP failed: $e');
      // Non-fatal: ads still work (non-personalized if region requires it).
    }
  }

  Future<void> _requestConsentInfoUpdate() {
    final params = ConsentRequestParameters();
    final c = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () => c.complete(),
      (FormError err) => c.completeError(err),
    );
    return c.future;
  }

  Future<void> _loadAndShowFormIfRequired() {
    final c = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((FormError? err) {
      if (err != null) {
        c.completeError(err);
      } else {
        c.complete();
      }
    });
    return c.future;
  }

  Future<void> _runAtt() async {
    if (!Platform.isIOS) return;
    try {
      final status =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        // Small gap so the UMP sheet is fully off-screen before the
        // native ATT alert shows.
        await Future<void>.delayed(const Duration(milliseconds: 250));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ConsentService] ATT failed: $e');
    }
  }

  Future<bool> canRequestAds() async {
    try {
      return await ConsentInformation.instance.canRequestAds();
    } catch (_) {
      return true;
    }
  }

  /// Only for development / support. Wipes locally stored UMP state so the
  /// consent form appears again on the next launch. Not exposed in UI.
  Future<void> resetForDebug() async {
    await ConsentInformation.instance.reset();
    _done = false;
  }
}
