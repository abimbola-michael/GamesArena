import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

import '../../theme/colors.dart';
import '../widgets/app_button.dart';

class InfosDialog extends StatelessWidget {
  final String title;
  final String? message;
  final List<String>? messages;
  final List<String>? actions;
  final void Function(bool positive)? onPressed;

  const InfosDialog(
      {super.key,
      required this.title,
      this.message,
      this.onPressed,
      this.actions,
      this.messages});

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                style: TextStyle(fontSize: 14, color: tint),
                textAlign: TextAlign.center,
              ),
            ],
            if (messages != null && messages!.isNotEmpty) ...[
              const SizedBox(
                height: 4,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(messages!.length, (index) {
                  final message = messages![index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${index + 1}. ",
                          style: TextStyle(
                              fontSize: 14,
                              color: lightTint,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        Expanded(
                          child: Text(
                            message,
                            style: TextStyle(fontSize: 14, color: lightTint),
                            // textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              )
            ],
            const SizedBox(
              height: 20,
            ),
            if ((actions ?? []).isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      title: actions![0],
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
                      title: actions![1],
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
    );
  }
}
