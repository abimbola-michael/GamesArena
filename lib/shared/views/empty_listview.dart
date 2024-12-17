import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/widgets/app_button.dart';

import '../../theme/colors.dart';

class EmptyListView extends StatelessWidget {
  final String message;
  final String? action;
  final VoidCallback? onPressed;

  const EmptyListView(
      {super.key, required this.message, this.action, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      color: context.bgColor,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: context.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 10,
          ),
          if (action != null)
            AppButton(
              bgColor: primaryColor,
              title: action,
              wrapped: true,
              onPressed: onPressed,
            )
        ],
      ),
    );
  }
}
