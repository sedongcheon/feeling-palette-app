---
title: in_app_purchase — quick reference
owner: harness-engineer
status: living
last_verified: 2026-05-23
upstream: https://pub.dev/packages/in_app_purchase
---

# in_app_purchase

Google Play Billing + Apple StoreKit. iOS/Android **동일 활성화**.

## 초기화 (`main.dart`)

```dart
await PremiumService.initialize();
```

내부적으로:

```dart
final available = await InAppPurchase.instance.isAvailable();
if (!available) return;

InAppPurchase.instance.purchaseStream.listen(_handlePurchaseUpdate);
final response = await InAppPurchase.instance.queryProductDetails({'premium_lifetime'});
// response.productDetails 활용
```

## 구매 흐름

```dart
final purchaseParam = PurchaseParam(productDetails: details);
await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
```

콜백은 `purchaseStream`으로 들어옴:

```dart
void _handlePurchaseUpdate(List<PurchaseDetails> purchases) {
  for (final p in purchases) {
    switch (p.status) {
      case PurchaseStatus.pending:
        // UI에 spinner
      case PurchaseStatus.purchased || PurchaseStatus.restored:
        await _grantPremium(p);
        if (p.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(p);
        }
      case PurchaseStatus.error:
        // 사유 분기 — 사용자 취소는 메시지 안 띄움
      case PurchaseStatus.canceled:
        // silent
    }
  }
}
```

## 규칙

- `PurchaseDetails`는 boundary — 직접 service에 흘리지 말고 boundary 파서
  통과시킬 것 (`PurchaseEvent.fromPurchaseDetails(p)`).
- `completePurchase`는 grant 후에 호출 (서버 검증 도입 시 그 직후).
- 복원 흐름은 별도 버튼 — `InAppPurchase.instance.restorePurchases()`.
- 가격은 `ProductDetails.price` 표시 (스토어가 현지 통화 자동 처리).
  하드코딩 KRW/USD 금지.
- 테스트 계정으로만 production 환경 테스트 가능. `docs/IAP_SETUP.md` 참조.

## 플랫폼 분기

iOS와 Android 동일하게 활성화. 한쪽만 비활성화하는 가드는 `exec-plan`으로
명시적 추적이 없으면 금지 (`docs/design-docs/core-beliefs.md` #8).

## 관련 문서

- [docs/IAP_SETUP.md](../IAP_SETUP.md) — 스토어 콘솔 설정
- [docs/product-specs/premium.md](../product-specs/premium.md)
