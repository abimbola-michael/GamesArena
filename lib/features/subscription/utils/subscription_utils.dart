// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../shared/utils/utils.dart';
import '../enums/enums.dart';
import '../models/subscription_status.dart';

class SubscriptionUtils {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  //List<PurchaseDetails> _purchases = [];
  List<SubscriptionPlan> _subscriptionPlans = [];
  SubscriptionPlan? _subscribedPlan;
  bool _available = false;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  StreamController<SubscriptionStatus>? _subscriptionStatusController;
  Stream<SubscriptionStatus>? subscriptionStatusStream;
  SubscriptionUtils([List<SubscriptionPlan> plans = SubscriptionPlan.values]) {
    init(plans);
  }

  void init([List<SubscriptionPlan> plans = SubscriptionPlan.values]) {
    if (!isAndroidAndIos) return;
    // plans.remove(SubscriptionPlan.free);
    _subscriptionPlans = plans;
    _subscriptionStatusController = StreamController.broadcast();
    subscriptionStatusStream = _subscriptionStatusController?.stream;

    final Stream<List<PurchaseDetails>> purchaseUpdated =
        InAppPurchase.instance.purchaseStream;
    _subscription = purchaseUpdated.listen((purchases) {
      _handlePurchaseUpdates(purchases);
    });
    _initializePurchases();
  }

  void dispose() {
    _subscription?.cancel();
    _subscriptionStatusController?.close();
  }

  Future subscribe(SubscriptionPlan plan) async {
    if (!_available) return;
    final id = plan.name;
    final productIndex = _products.indexWhere((element) => element.id == id);
    if (productIndex == -1) return;
    final product = _products[productIndex];
    _subscribedPlan = plan;
    return _buyProduct(product);
  }

  Future<void> _initializePurchases() async {
    _available = await _inAppPurchase.isAvailable();
    if (!_available) {
      // Handle store not available
      return;
    }

    Set<String> productIds = _subscriptionPlans.map((e) => e.name).toSet();

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(productIds);
    if (response.error != null) {
      // Handle error fetching product details
      return;
    }
    _products = response.productDetails;

    // setState(() {
    // });
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        _verifyPurchase(purchaseDetails);
      } else {
        if (purchaseDetails.status == PurchaseStatus.pending) {
          // Handle pending status
        } else if (purchaseDetails.status == PurchaseStatus.error) {
          // Handle error status
        }
        _subscriptionStatusController?.sink.add(SubscriptionStatus(
            subscribed: true,
            purchaseStatus: purchaseDetails.status,
            plan: _subscribedPlan));
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  void _verifyPurchase(PurchaseDetails purchaseDetails) {
    // In a real app, you would verify the purchase (receipt) with your server here
    //verify with firestore
    _subscriptionStatusController?.sink.add(SubscriptionStatus(
        subscribed: true,
        purchaseStatus: PurchaseStatus.purchased,
        plan: _subscribedPlan));
  }

  Future _buyProduct(ProductDetails productDetails) {
    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);
    return _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam); // For subscriptions
  }
}
