import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/premium_service.dart';
import 'pin_setup_screen.dart';

const _autoLockOptionSeconds = <int>[0, 5, 30, 60, 300, 600];

String _autoLockLabel(BuildContext context, int seconds) =>
    AppLocalizations.of(context).autoLockDelayLabel(seconds.toString());

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            loc.commonClose,
            style: TextStyle(
              color: palette.tabBarActive,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        leadingWidth: 64,
        title: Text(
          loc.settingsTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: palette.text,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            _sectionLabel(palette, loc.settingsSectionAppLock),
            const SizedBox(height: 8),
            const _AppLockToggleTile(),
            if (context.watch<AuthProvider>().hasPin) ...[
              const SizedBox(height: 8),
              const _AutoLockDelayTile(),
            ],
            const SizedBox(height: 24),
            _sectionLabel(palette, loc.settingsSectionPurchase),
            const SizedBox(height: 8),
            const _RemoveAdsCard(),
            const SizedBox(height: 12),
            const _RestorePurchasesTile(),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(AppPalette palette, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: palette.textSecondary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _RemoveAdsCard extends StatelessWidget {
  const _RemoveAdsCard();

  Future<void> _handleBuy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context);
    final premium = context.read<PremiumService>();
    final started = await premium.buyRemoveAds();
    if (!started) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(loc.settingsPurchaseStartFailed),
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  Future<void> _handleRetry(BuildContext context) async {
    await context.read<PremiumService>().retryLoadProduct();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final loc = AppLocalizations.of(context);
    final premium = context.watch<PremiumService>();
    final isPremium = premium.isPremium;
    final price = premium.priceLabel;
    final canBuy = premium.isAvailable &&
        premium.product != null &&
        !premium.purchaseInFlight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.tabBarActive.withAlpha(0x1F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.block_rounded,
                  color: palette.tabBarActive,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.settingsRemoveAdsTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPremium
                          ? loc.settingsRemoveAdsPurchased
                          : loc.settingsRemoveAdsDescription,
                      style: TextStyle(
                        fontSize: 12,
                        height: 18 / 12,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: isPremium
                ? OutlinedButton.icon(
                    onPressed: null,
                    icon: Icon(
                      Icons.check_circle_rounded,
                      color: palette.tabBarActive,
                    ),
                    label: Text(
                      loc.settingsRemoveAdsPurchasedButton,
                      style: TextStyle(
                        color: palette.tabBarActive,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: palette.tabBarActive.withAlpha(0x55),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                : _buildPurchaseButton(context, palette, premium, price, canBuy),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseButton(
    BuildContext context,
    AppPalette palette,
    PremiumService premium,
    String price,
    bool canBuy,
  ) {
    final loc = AppLocalizations.of(context);
    if (premium.purchaseInFlight) {
      return _filled(
        palette,
        onPressed: null,
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }
    if (price.isNotEmpty) {
      return _filled(
        palette,
        onPressed: canBuy ? () => _handleBuy(context) : null,
        child: Text(
          loc.settingsBuyAtPrice(price),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      );
    }
    if (!premium.isAvailable) {
      return _filled(
        palette,
        onPressed: null,
        child: Text(
          loc.settingsStoreUnavailable,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      );
    }
    if (premium.loadFailed) {
      return OutlinedButton.icon(
        onPressed: () => _handleRetry(context),
        icon: Icon(Icons.refresh_rounded, color: palette.tabBarActive),
        label: Text(
          loc.settingsLoadFailedRetry,
          style: TextStyle(
            color: palette.tabBarActive,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: palette.tabBarActive.withAlpha(0x55)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    return _filled(
      palette,
      onPressed: null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(
            loc.settingsLoadingPurchaseInfo,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _filled(AppPalette palette,
      {required VoidCallback? onPressed, required Widget child}) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: palette.tabBarActive,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: child,
    );
  }
}

class _RestorePurchasesTile extends StatefulWidget {
  const _RestorePurchasesTile();

  @override
  State<_RestorePurchasesTile> createState() => _RestorePurchasesTileState();
}

class _RestorePurchasesTileState extends State<_RestorePurchasesTile> {
  bool _busy = false;

  Future<void> _restore() async {
    final loc = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await context.read<PremiumService>().restorePurchases();
      if (!mounted) return;
      final premium = context.read<PremiumService>();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(
            premium.isPremium
                ? loc.settingsRestoreSuccess
                : loc.settingsRestoreNothing,
          ),
          behavior: SnackBarBehavior.floating,
        ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final loc = AppLocalizations.of(context);
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _busy ? null : _restore,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                Icons.restore_rounded,
                color: palette.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loc.settingsRestoreButton,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
              ),
              if (_busy)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: palette.tabBarActive,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppLockToggleTile extends StatelessWidget {
  const _AppLockToggleTile();

  Future<void> _onTap(BuildContext context, bool currentlyOn) async {
    final auth = context.read<AuthProvider>();
    final loc = AppLocalizations.of(context);
    if (currentlyOn) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(loc.settingsAppLockDisableTitle),
          content: Text(loc.settingsAppLockDisableBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(loc.settingsAppLockDisableCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(loc.settingsAppLockDisableConfirm),
            ),
          ],
        ),
      );
      if (ok == true) {
        await auth.disableLock();
      }
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PinSetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final loc = AppLocalizations.of(context);
    final hasPin = context.watch<AuthProvider>().hasPin;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _onTap(context, hasPin),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: palette.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.settingsAppLockToggleTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasPin
                          ? loc.settingsAppLockToggleDescriptionOn
                          : loc.settingsAppLockToggleDescriptionOff,
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: hasPin,
                onChanged: (_) => _onTap(context, hasPin),
                activeThumbColor: palette.tabBarActive,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AutoLockDelayTile extends StatelessWidget {
  const _AutoLockDelayTile();

  Future<void> _pick(BuildContext context) async {
    final palette = context.palette;
    final loc = AppLocalizations.of(context);
    final current = context.read<AuthProvider>().autoLockDelaySeconds;
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      Text(
                        loc.settingsAutoLockTitle,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: palette.text,
                        ),
                      ),
                    ],
                  ),
                ),
                for (final seconds in _autoLockOptionSeconds)
                  ListTile(
                    title: Text(
                      _autoLockLabel(sheetContext, seconds),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: palette.text,
                      ),
                    ),
                    trailing: seconds == current
                        ? Icon(
                            Icons.check_rounded,
                            color: palette.tabBarActive,
                          )
                        : null,
                    onTap: () => Navigator.of(sheetContext).pop(seconds),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null && picked != current && context.mounted) {
      await context.read<AuthProvider>().setAutoLockDelaySeconds(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final loc = AppLocalizations.of(context);
    final seconds = context.watch<AuthProvider>().autoLockDelaySeconds;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _pick(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lock_clock_rounded,
                color: palette.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.settingsAutoLockTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.settingsAutoLockDescription,
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _autoLockLabel(context, seconds),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: palette.tabBarActive,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: palette.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
