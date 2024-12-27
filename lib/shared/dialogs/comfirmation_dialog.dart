import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

import '../../theme/colors.dart';
import '../widgets/action_button.dart';
import '../widgets/app_button.dart';

class ComfirmationDialog extends StatelessWidget {
  final String title;
  final String? message;
  final List<String>? actions;
  final void Function(bool positive)? onPressed;
  final int quarterTurns;

  const ComfirmationDialog(
      {super.key,
      required this.title,
      this.message,
      this.onPressed,
      this.actions,
      this.quarterTurns = 0});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: RotatedBox(
        quarterTurns: quarterTurns,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 24, color: tint),
                textAlign: TextAlign.center,
              ),
              if (message != null && message!.isNotEmpty) ...[
                const SizedBox(
                  height: 4,
                ),
                Text(
                  message!,
                  style: TextStyle(fontSize: 14, color: lightTint),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      title: actions != null && actions!.isNotEmpty
                          ? actions![0]
                          : "No",
                      onPressed: () {
                        if (onPressed != null) {
                          onPressed!(false);
                        } else {
                          context.pop();
                        }
                      },
                      bgColor: Colors.red,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: AppButton(
                      title: actions != null && actions!.length > 1
                          ? actions![1]
                          : "Yes",
                      //comfirmationType.capitalize,
                      onPressed: () {
                        if (onPressed != null) {
                          onPressed!(true);
                        } else {
                          context.pop(true);
                        }
                      },
                      bgColor: Colors.blue,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
