import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/widgets/app_button.dart';

import '../../theme/colors.dart';

class ErrorOrSuccessView extends StatelessWidget {
  final String message;
  final String? title;
  final String? action;
  final bool isError;
  final bool wrapped;

  final VoidCallback? onPressed;
  const ErrorOrSuccessView(
      {super.key,
      required this.message,
      this.title,
      this.action,
      this.isError = true,
      this.wrapped = false,
      this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: wrapped ? null : double.infinity,
      width: wrapped ? null : double.infinity,
      color: context.bgColor,
      alignment: Alignment.center,
      child: SizedBox(
        width: wrapped ? null : 350,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isError || title != null)
              Text(
                title ?? (isError ? "Opps!" : "Kudos!"),
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
            if (action != null)
              AppButton(
                bgColor: primaryColor,
                title: action ?? (isError ? "Retry" : "Done"),
                wrapped: true,
                onPressed: () {
                  context.pop(true);
                },
              )
          ],
        ),
      ),
    );
  }
}
