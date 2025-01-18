import 'package:in_app_purchase/in_app_purchase.dart';

import '../enums/enums.dart';

class SubscriptionStatus {
  bool subscribed;
  SubscriptionPlan? plan;
  PurchaseStatus purchaseStatus;
  SubscriptionStatus({
    required this.subscribed,
    required this.plan,
    required this.purchaseStatus,
  });
}
