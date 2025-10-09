// lib/services/purchase_service.dart

import 'dart:async';
// The incorrect 'package.dart' import has been removed.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';

// IMPORTANT: You MUST create a subscription in the Google Play Console
// and put its unique ID here. For example: 'premium_monthly_sub'.
const String _premiumProductId = 'YOUR_PRODUCT_ID_FROM_GOOGLE_PLAY';

// Provider to make the service accessible throughout the app.
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  return PurchaseService(ref);
});

class PurchaseService {
  final Ref _ref;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  PurchaseService(this._ref) {
    // Listen to the stream of purchase updates from the store.
    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
          (purchaseDetailsList) {
        _handlePurchaseUpdates(purchaseDetailsList);
      },
      onDone: () {
        _subscription.cancel();
      },
      onError: (error) {
        // Handle stream errors if any.
        print("Purchase Stream Error: $error");
      },
    );
  }

  /// This is the method your UI will call when the user clicks "Upgrade".
  Future<void> buyPremium() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      print("Store not available");
      // Optionally, show a snackbar or dialog to the user.
      return;
    }

    final ProductDetailsResponse response =
    await _inAppPurchase.queryProductDetails({_premiumProductId});

    if (response.notFoundIDs.isNotEmpty) {
      print("Product not found: $_premiumProductId");
      // This means the product ID is not configured correctly in the Play Store.
      return;
    }

    // Get the product details from the response.
    final ProductDetails productDetails = response.productDetails.first;

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);

    // This will open the native Google Play payment sheet.
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// This private method is called whenever a purchase is made, restored, or fails.
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {

        // The purchase was successful!
        print("Purchase successful for product: ${purchaseDetails.productID}");

        // CRITICAL: For a real app, you should verify the purchase on your own server
        // to prevent fraud. For this MVP, we will trust the client.

        // If the purchase is valid, update the user's status in Firestore.
        // This is where everything connects!
        _ref
            .read(userProfileNotifierProvider.notifier)
            .updateUserPremiumStatus(true);

        // Mark the purchase as complete.
        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        print("Purchase Error: ${purchaseDetails.error}");
      }
    }
  }

  // It's good practice to have a dispose method to cancel the subscription
  // although with a Provider, it might live for the app's lifecycle.
  void dispose() {
    _subscription.cancel();
  }
}