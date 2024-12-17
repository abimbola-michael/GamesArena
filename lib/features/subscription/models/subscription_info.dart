// ignore_for_file: public_member_api_docs, sort_constructors_first
import '../enums/enums.dart';

class SubscriptionInfo {
  SubscriptionType type;
  SubscriptionPlan? plan;
  List<String> infos;
  int? dollarPrice;
  SubscriptionInfo({
    required this.type,
    this.plan,
    required this.infos,
    this.dollarPrice,
  });
}
