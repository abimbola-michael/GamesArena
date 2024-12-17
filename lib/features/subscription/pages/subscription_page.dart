import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/extensions/special_context_extensions.dart';

import '../../../shared/utils/utils.dart';
import '../../../shared/utils/utils.dart';
import '../../../shared/widgets/app_appbar.dart';
import '../../../shared/widgets/app_button.dart';
import '../components/subscription_info_item.dart';
import '../enums/enums.dart';
import '../models/subscription_info.dart';
import '../services/services.dart';
import '../utils/subscription_utils.dart';

class SubscriptionPage extends StatefulWidget {
  static const route = "/subscription";
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  bool loading = false;
  StreamSubscription? subscriptionStatusSub;
  late SubscriptionUtils subscriptionUtils;
  SubscriptionPlan? previousPlan;
  SubscriptionPlan? currentPlan;
  List<SubscriptionInfo> subscriptionInfos = [
    SubscriptionInfo(
      type: SubscriptionType.free,
      infos: [
        "Ads while playing game",
      ],
    ),
    SubscriptionInfo(
      type: SubscriptionType.paid,
      plan: SubscriptionPlan.daily,
      infos: [
        "No Ads while playing game",
      ],
      dollarPrice: 1,
    ),
    SubscriptionInfo(
      type: SubscriptionType.paid,
      plan: SubscriptionPlan.weekly,
      infos: [],
      dollarPrice: 5,
    ),
    SubscriptionInfo(
      type: SubscriptionType.paid,
      plan: SubscriptionPlan.monthly,
      infos: [],
      dollarPrice: 15,
    ),
    SubscriptionInfo(
      type: SubscriptionType.paid,
      plan: SubscriptionPlan.yearly,
      infos: [],
      dollarPrice: 165,
    ),
  ];
  @override
  void initState() {
    super.initState();
    listenToSubscriptionStatus();
    readSubscriptionPlan();
  }

  @override
  void dispose() {
    subscriptionUtils.dispose();
    subscriptionStatusSub?.cancel();
    super.dispose();
  }

  void listenToSubscriptionStatus() {
    subscriptionUtils = SubscriptionUtils();

    subscriptionStatusSub =
        subscriptionUtils.subscriptionStatusStream?.listen((subStatus) {
      final subscribed = subStatus.subscribed;
      final plan = subStatus.plan;
      final purchaseStatus = subStatus.purchaseStatus;
      if (subscribed) {
        setState(() {
          previousPlan = plan;
        });
      }
      showToast(
          "${plan?.name.capitalize ?? ""} subscription ${purchaseStatus.name}",
          isError: !subscribed);
    });
  }

  void readSubscriptionPlan() async {
    loading = true;
    setState(() {});

    previousPlan = await getSubscriptionPlan();
    currentPlan = previousPlan;
    loading = false;

    setState(() {});
  }

  void togglePlanChange(SubscriptionPlan? plan) {
    currentPlan = plan;
    setState(() {});
  }

  bool get isValidSelection {
    final prevPlanIndex = previousPlan == null ? 0 : previousPlan!.index + 1;
    final currentPlanIndex = currentPlan == null ? 0 : currentPlan!.index + 1;
    return currentPlan != previousPlan && currentPlanIndex > prevPlanIndex;
  }

  void selectPlan() async {
    if (!isAndroidAndIos) {
      context.pop();
      return;
    }
    await subscriptionUtils.subscribe(currentPlan!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(
        title: "Subscription",
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: subscriptionInfos.length,
              itemBuilder: (context, index) {
                final info = subscriptionInfos[index];
                final prevInfo =
                    index == 0 ? null : subscriptionInfos[index - 1];
                return SubscriptionInfoItem(
                    info: info,
                    prevInfo: prevInfo,
                    previousPlan: previousPlan,
                    currentPlan: currentPlan,
                    onChanged: togglePlanChange);
              },
            ),
      bottomNavigationBar: isValidSelection
          ? Container(
              height: 50,
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Center(
                  child: AppButton(
                      title: "Select Plan",
                      //wrapped: true,
                      onPressed: selectPlan)),
            )
          : null,
    );
  }
}
