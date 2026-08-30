import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../data/repositories/progress_repository.dart';

class IapService {
  static const String removeAdsId = 'bloomku_remove_ads';
  static const String hintPackId = 'bloomku_hint_pack_10';
  static const String undoPackId = 'bloomku_undo_pack_10';

  static final Map<String, ProductDetails> _products = {};
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static bool _initialized = false;
  static bool _available = false;

  static bool get isReady => _initialized && _available;
  static bool get isAvailable => _available;

  /// Initialize and load product details. Call in main().
  static Future<bool> initialize() async {
    if (_initialized) return _available;
    final available = await InAppPurchase.instance.isAvailable();
    _available = available;
    if (!available) {
      _initialized = true;
      return false;
    }

    final response = await InAppPurchase.instance.queryProductDetails(
      {removeAdsId, hintPackId, undoPackId},
    );
    if (response.error != null) {
      throw StateError(response.error!.message);
    }
    _products.clear();
    for (final product in response.productDetails) {
      _products[product.id] = product;
    }
    _initialized = true;
    return true;
  }

  /// Returns product details map (productId → ProductDetails).
  static Map<String, ProductDetails> get products => _products;

  /// Initiates a purchase flow. Pass productId.
  static Future<bool> purchase(String productId) async {
    if (!isReady) return false;
    final productDetails = _products[productId];
    if (productDetails == null) return false;

    final purchaseParam = PurchaseParam(productDetails: productDetails);
    if (productId == hintPackId || productId == undoPackId) {
      return InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);
    } else {
      return InAppPurchase.instance
          .buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  /// Restores previous purchases (for non-consumables).
  static Future<bool> restorePurchases() async {
    if (!isReady) return false;
    await InAppPurchase.instance.restorePurchases();
    return true;
  }

  /// Must be called to set up the purchase stream listener.
  static void listenToPurchaseUpdates(ProgressRepository progressRepo) {
    if (_subscription != null) return;
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
