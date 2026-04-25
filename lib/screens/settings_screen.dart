import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/theme.dart';
import '../providers/auth_provider.dart';
import '../services/premium_service.dart';

const _autoLockOptions = <(int, String)>[
  (0, '즉시'),
  (5, '5초'),
  (30, '30초'),
  (60, '1분'),
  (300, '5분'),
  (600, '10분'),
];

String _autoLockLabel(int seconds) {
  for (final option in _autoLockOptions) {
    if (option.$1 == seconds) return option.$2;
  }
  return '$seconds초';
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '닫기',
            style: TextStyle(
              color: palette.tabBarActive,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        leadingWidth: 64,
        title: Text(
          '설정',
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
            _sectionLabel(palette, '앱 잠금'),
            const SizedBox(height: 8),
            const _AutoLockDelayTile(),
            // iOS 한정으로 IAP 섹션 숨김. Apple Paid Apps Agreement에 필요한
            // 한국 사업자등록 / 세금 정보가 미완성 상태라 IAP가 production에서
            // 로드 실패 → 리뷰어가 "구매 정보 로딩 실패" 화면을 봐서 거절됨.
            // 사업자등록 진행 후 다시 활성화 예정. Android는 Google Play Billing
            // 으로 정상 동작 중이라 그대로 노출.
            if (!Platform.isIOS) ...[
              const SizedBox(height: 24),
              _sectionLabel(palette, '구매'),
              const SizedBox(height: 8),
              const _RemoveAdsCard(),
              const SizedBox(height: 12),
              const _RestorePurchasesTile(),
            ],
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
    final premium = context.read<PremiumService>();
    final started = await premium.buyRemoveAds();
    if (!started) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('지금은 구매를 시작할 수 없어요. 잠시 후 다시 시도해주세요.'),
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
                      '광고 제거',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPremium
                          ? '구매 완료 — 배너와 전면 광고가 표시되지 않아요.'
                          : '배너 · 전면 광고 없이 쾌적하게 사용할 수 있어요.\n(리워드 광고는 보너스 분석 획득에 계속 사용 가능합니다.)',
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
                      '구매 완료',
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
          '$price에 구매하기',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      );
    }
    if (!premium.isAvailable) {
      return _filled(
        palette,
        onPressed: null,
        child: const Text(
          '스토어에 연결할 수 없어요',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      );
    }
    if (premium.loadFailed) {
      return OutlinedButton.icon(
        onPressed: () => _handleRetry(context),
        icon: Icon(Icons.refresh_rounded, color: palette.tabBarActive),
        label: Text(
          '구매 정보를 불러오지 못했어요 · 다시 시도',
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
        children: const [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          SizedBox(width: 10),
          Text(
            '구매 정보 불러오는 중…',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
                ? '구매 내역이 복원되었어요.'
                : '복원할 구매 내역이 없어요.',
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
                  '구매 복원',
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

class _AutoLockDelayTile extends StatelessWidget {
  const _AutoLockDelayTile();

  Future<void> _pick(BuildContext context) async {
    final palette = context.palette;
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
                        '자동 잠금',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: palette.text,
                        ),
                      ),
                    ],
                  ),
                ),
                for (final option in _autoLockOptions)
                  ListTile(
                    title: Text(
                      option.$2,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: palette.text,
                      ),
                    ),
                    trailing: option.$1 == current
                        ? Icon(
                            Icons.check_rounded,
                            color: palette.tabBarActive,
                          )
                        : null,
                    onTap: () => Navigator.of(sheetContext).pop(option.$1),
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
                      '자동 잠금',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '앱을 벗어난 뒤 이 시간이 지나면 잠금 화면이 다시 뜹니다.',
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
                _autoLockLabel(seconds),
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
