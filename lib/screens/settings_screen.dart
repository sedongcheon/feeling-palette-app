import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/theme.dart';
import '../services/premium_service.dart';

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
            _sectionLabel(palette, '구매'),
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
                : FilledButton(
                    onPressed: canBuy ? () => _handleBuy(context) : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.tabBarActive,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: premium.purchaseInFlight
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            price.isNotEmpty
                                ? '$price에 구매하기'
                                : premium.isAvailable
                                    ? '구매 정보 로딩 중…'
                                    : '스토어에 연결할 수 없어요',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
          ),
        ],
      ),
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
