// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

import '../../../theme/colors.dart';
import '../enums/enums.dart';
import '../models/subscription_info.dart';

class SubscriptionInfoItem extends StatelessWidget {
  final SubscriptionInfo? prevInfo;
  final SubscriptionInfo info;
  final SubscriptionPlan? currentPlan;
  final SubscriptionPlan? previousPlan;

  final void Function(SubscriptionPlan? plan)? onChanged;
  const SubscriptionInfoItem({
    super.key,
    required this.info,
    required this.currentPlan,
    required this.previousPlan,
    required this.onChanged,
    this.prevInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        //crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (prevInfo == null || prevInfo!.type != info.type) ...[
            Text(
              info.type.name.capitalize,
              style:
                  context.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
          ],
          if (info.infos.isNotEmpty) ...[
            ...List.generate(info.infos.length, (index) {
              final infoName = info.infos[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: CircleAvatar(radius: 3, backgroundColor: tint),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        infoName,
                        style: context.bodySmall?.copyWith(
                          color: lightTint,
                        ),
                      ),
                    )
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              if (onChanged != null) {
                onChanged!(info.plan);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: info.plan == previousPlan
                    ? primaryColor.withOpacity(0.1)
                    : lightestTint,
                border: Border.all(
                    color:
                        currentPlan == info.plan ? primaryColor : lightestTint,
                    width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.plan?.name.capitalize ?? "Basic",
                          style: context.bodySmall?.copyWith(color: tint),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "\$${info.dollarPrice ?? 0}",
                          style: context.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: tint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Radio<SubscriptionPlan?>(
                      value: info.plan,
                      groupValue: currentPlan,
                      onChanged: onChanged)
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
