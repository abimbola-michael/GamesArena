// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

import '../../../shared/widgets/app_container.dart';
import '../../../theme/colors.dart';
import '../models/onboarding_info.dart';

class OnboardingInfoItem extends StatelessWidget {
  final OnboardingInfo onboardingInfo;
  const OnboardingInfoItem({
    super.key,
    required this.onboardingInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppContainer(
                height: double.infinity,
                width: double.infinity,
                //  image: AssetImage(onboardingInfo.image.toPng),
                margin: EdgeInsets.only(bottom: 50),
                imageFit: BoxFit.fill,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                onboardingInfo.title,
                style: context.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                onboardingInfo.message,
                style: context.bodyMedium?.copyWith(color: lighterTint),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
