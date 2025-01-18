import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

import '../../theme/colors.dart';

class SuccessView extends StatelessWidget {
  final String message;
  final String action;

  const SuccessView({super.key, required this.message, this.action = "Done"});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      color: context.bgColor,
      alignment: Alignment.center,
      child: SizedBox(
        width: 350,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Successful",
              style: context.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 2,
            ),
            Text(
              message,
              style: context.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 10,
            ),
            ActionChip(
              backgroundColor: primaryColor,
              label: Text(
                action,
                style: context.bodySmall,
              ),
              onPressed: () => context.pop(true),
            )
          ],
        ),
      ),
    );
  }
}
