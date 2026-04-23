import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'ads_service.dart';

/// Manages the "Remove Ads" in-app purchase (non-consumable, single product).
///
/// Product ID: [kRemoveAdsProductId] — must match the store listing in both
/// App Store Connect (iOS) and Google Play Console (Android).
///
/// Persists the purchased-flag locally in secure storage so the ad-free
/// experience is available before the store returns restore info on launch.
/// The store response is the authority — if [restorePurchases] shows no
/// record, the flag is cleared.
class PremiumService extends ChangeNotifier {
  PremiumService._();
  static final PremiumService instance = PremiumService._();

  static const String kRemoveAdsProductId = 'remove_ads';
  static const String _kIsPremiumKey = 'is_premium';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final InAppPurchase _iap = InAppPurchase.instance;

  bool _initialized = false;
  bool _available = false;
  bool _isPremium = false;
  bool _purchaseInFlight = false;
  bool _productLoading = false;
  bool _loadFailed = false;
  ProductDetails? _product;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  static const Duration _productLoadTimeout = Duration(seconds: 10);
  static const int _autoRetryCount = 1;

  bool get isInitialized => _initialized;
  bool get isAvailable => _available;
  bool get isPremium => _isPremium;
  bool get purchaseInFlight => _purchaseInFlight;
  bool get productLoading => _productLoading;
  bool get loadFailed => _loadFailed;
  ProductDetails? get product => _product;
  String get priceLabel => _product?.price ?? '';

  Future<void> initialize() async {
    if (_initialized) return;

    // Screenshot mode: force ad-free for App Store screenshot captures.
    // Enable with: flutter run --dart-define=SCREENSHOT_MODE=true
    if (const bool.fromEnvironment('SCREENSHOT_MODE')) {
      _isPremium = true;
      _available = false;
      AdsService.instance.setAdFree(true);
      _initialized = true;
      notifyListeners();
      return;
    }

    // Load cached flag so UI reflects last known state immediately.
    final cached = await _storage.read(key: _kIsPremiumKey);
    if (cached == '1') {
      _isPremium = true;
      AdsService.instance.setAdFree(true);
    }

    _available = await _iap.isAvailable();
    if (!_available) {
      _initialized = true;
      notifyListeners();
      return;
    }

    _sub = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object e) {
        if (kDebugMode) debugPrint('[Premium] purchaseStream error: $e');
      },
    );

    _initialized = true;
    notifyListeners();

    // Fire-and-forget so a stuck store call can't block initialize().
    unawaited(_loadProductWithRetry());

    // Ask the store for any existing purchases (reinstall case etc.).
    unawaited(_iap.restorePurchases());
  }

  Future<void> _loadProductWithRetry() async {
    for (var attempt = 0; attempt <= _autoRetryCount; attempt++) {
      final ok = await _loadProduct();
      if (ok) return;
      if (attempt < _autoRetryCount) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
    _loadFailed = true;
    _productLoading = false;
    notifyListeners();
  }

  Future<bool> _loadProduct() async {
    _productLoading = true;
    _loadFailed = false;
    notifyListeners();
    try {
      final resp = await _iap
          .queryProductDetails({kRemoveAdsProductId})
          .timeout(_productLoadTimeout);
      if (resp.error != null) {
        if (kDebugMode) debugPrint('[Premium] queryProductDetails error: ${resp.error}');
        return false;
      }
      if (resp.productDetails.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[Premium] remove_ads product not found. '
            'Have you registered it in Play Console / App Store Connect '
            'and attached it to the build for the first IAP submission?',
          );
        }
        return false;
      }
      _product = resp.productDetails.first;
      _productLoading = false;
      notifyListeners();
      return true;
    } on TimeoutException catch (_) {
      if (kDebugMode) debugPrint('[Premium] queryProductDetails timeout');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('[Premium] loadProduct exception: $e');
      return false;
    }
  }

  /// Manually retry loading the product. Safe to call from UI when the
  /// user taps a "retry" button after a failed load.
  Future<void> retryLoadProduct() async {
    if (_productLoading) return;
    if (!_available) {
      _available = await _iap.isAvailable();
      if (!_available) {
        notifyListeners();
        return;
      }
    }
    await _loadProductWithRetry();
  }

  /// Initiates the purchase flow. Returns immediately; the actual result
  /// is delivered through [purchaseStream] into [_onPurchaseUpdates].
  Future<bool> buyRemoveAds() async {
    if (_isPremium || _purchaseInFlight) return false;
    final product = _product;
    if (product == null) return false;
    _purchaseInFlight = true;
    notifyListeners();
    try {
      final ok = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      return ok;
    } catch (e) {
      if (kDebugMode) debugPrint('[Premium] buy exception: $e');
      _purchaseInFlight = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (!_available) return;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      if (kDebugMode) debugPrint('[Premium] restore exception: $e');
    }
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> list) async {
    for (final p in list) {
      if (p.productID != kRemoveAdsProductId) continue;
      switch (p.status) {
        case PurchaseStatus.pending:
          // Keep inFlight true; UI will show a spinner.
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _grantPremium();
          break;
        case PurchaseStatus.error:
          if (kDebugMode) debugPrint('[Premium] purchase error: ${p.error}');
          _purchaseInFlight = false;
          notifyListeners();
          break;
        case PurchaseStatus.canceled:
          _purchaseInFlight = false;
          notifyListeners();
          break;
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }

  Future<void> _grantPremium() async {
    _isPremium = true;
    _purchaseInFlight = false;
    await _storage.write(key: _kIsPremiumKey, value: '1');
    AdsService.instance.setAdFree(true);
    notifyListeners();
  }

  /// Clears the local premium flag. For support / debugging only — never
  /// surfaced in UI. Doesn't revoke the store purchase itself.
  Future<void> clearLocalFlagForDebug() async {
    _isPremium = false;
    await _storage.delete(key: _kIsPremiumKey);
    AdsService.instance.setAdFree(false);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
