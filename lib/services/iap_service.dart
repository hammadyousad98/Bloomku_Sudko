import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../data/repositories/progress_repository.dart';

class IapService {
  static const String removeAdsId = 'bloomku_remove_ads';
  static const String hintPackId  = 'bloomku_hint_pack_10';
  static const String undoPackId  = 'bloomku_undo_pack_10';

  static final Map<String, ProductDetails> _products = {};
  static StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// Initialize and load product details. Call in main().
  static Future<void> initialize() async {
    final available = await InAppPurchase.instance.isAvailable();
    if (!available) return;

    final response = await InAppPurchase.instance.queryProductDetails(
      {removeAdsId, hintPackId, undoPackId},
    );
    for (final product in response.productDetails) {
      _products[product.id] = product;
    }
  }

  /// Returns product details map (productId → ProductDetails).
  static Map<String, ProductDetails> get products => _products;

  /// Initiates a purchase flow. Pass productId.
  static Future<void> purchase(String productId) async {
    final productDetails = _products[productId];
    if (productDetails == null) return;

    final purchaseParam = PurchaseParam(productDetails: productDetails);
    if (productId == hintPackId || productId == undoPackId) {
      await InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);
    } else {
      await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  /// Restores previous purchases (for non-consumables).
  static Future<void> restorePurchases() async {
    await InAppPurchase.instance.restorePurchases();
  }

  /// Must be called to set up the purchase stream listener.
  static void listenToPurchaseUpdates(ProgressRepository progressRepo) {
    _subscription = InAppPurchase.instance.purchaseStream.listen(
      (purchaseDetailsList) async {
        for (final purchase in purchaseDetailsList) {
          if (purchase.status == PurchaseStatus.pending) {
            continue;
          } else if (purchase.status == PurchaseStatus.error) {
            // handle error
          } else if (purchase.status == PurchaseStatus.purchased ||
                     purchase.status == PurchaseStatus.restored) {
            
            if (purchase.productID == removeAdsId) {
              final progress = progressRepo.getProgress();
              progress.adsRemoved = true;
              progressRepo.saveProgress(progress);
            } else if (purchase.productID == hintPackId) {
              progressRepo.addHints(10);
            } else if (purchase.productID == undoPackId) {
              progressRepo.addUndos(10);
            }
          }
          
          if (purchase.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(purchase);
          }
        }
      },
      onDone: () => _subscription?.cancel(),
      onError: (error) {},
    );
  }
}
