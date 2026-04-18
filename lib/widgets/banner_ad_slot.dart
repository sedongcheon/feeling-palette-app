import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../constants/ad_ids.dart';
import '../services/ads_service.dart';

/// Bottom banner slot for content tabs (calendar / stats / timeline).
///
/// - Hidden (zero height) until the ad actually loads — avoids reserving
///   empty space when ads are blocked (ad-free user, offline, etc.).
/// - Auto-disposes the underlying [BannerAd] when unmounted or when the
///   user transitions to ad-free.
class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({super.key});

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  BannerAd? _ad;
  bool _loading = false;
  bool _failed = false;

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  void _ensureLoaded() {
    if (!mounted) return;
    if (_loading || _ad != null || _failed) return;
    if (!AdsService.instance.canShowBanner) return;

    _loading = true;
    late final BannerAd ad;
    ad = BannerAd(
      adUnitId: AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _ad = ad;
            _loading = false;
          });
        },
        onAdFailedToLoad: (adToDispose, err) {
          adToDispose.dispose();
          if (kDebugMode) debugPrint('[Ads] Banner failed: $err');
          if (!mounted) return;
          setState(() {
            _failed = true;
            _loading = false;
          });
        },
      ),
    );
    ad.load();
  }

  @override
  Widget build(BuildContext context) {
    final ads = context.watch<AdsService>();

    // Ad-free toggles or initialization hasn't finished — nothing to show.
    if (!ads.canShowBanner) {
      // If a previously loaded ad exists and we just went ad-free, drop it.
      if (_ad != null) {
        _ad!.dispose();
        _ad = null;
      }
      return const SizedBox.shrink();
    }

    if (_ad == null && !_failed && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
    }

    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
