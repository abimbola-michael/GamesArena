import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

import '../../theme/colors.dart';
import '../widgets/action_button.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

class TextInputDialog extends StatefulWidget {
  final String title;
  final String? message;
  final String? hintText;

  final List<String>? actions;
  final void Function(bool positive)? onPressed;
  final int quarterTurns;

  const TextInputDialog(
      {super.key,
      required this.title,
      this.hintText,
      this.message,
      this.onPressed,
      this.actions,
      this.quarterTurns = 0});

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  final inputController = TextEditingController();
  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: RotatedBox(
        quarterTurns: widget.quarterTurns,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: TextStyle(fontSize: 24, color: tint),
                textAlign: TextAlign.center,
              ),
              if (widget.message != null && widget.message!.isNotEmpty) ...[
                const SizedBox(
                  height: 4,
                ),
                Text(
                  widget.message!,
                  style: TextStyle(fontSize: 14, color: lightTint),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(
                height: 20,
              ),
              AppTextField(
                controller: inputController,
                hintText: widget.hintText ?? "",
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      title:
                          widget.actions != null && widget.actions!.isNotEmpty
                              ? widget.actions![0]
                              : "No",
                      onPressed: () {
                        if (widget.onPressed != null) {
                          widget.onPressed!(false);
                        } else {
                          context.pop();
                        }
                      },
                      height: 50,
                      bgColor: Colors.red,
                      color: Colors.white,
                    ),
                  ),
                  // const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      title:
                          widget.actions != null && widget.actions!.length > 1
                              ? widget.actions![1]
                              : "Yes",
                      //comfirmationType.capitalize,
                      onPressed: () {
                        if (widget.onPressed != null) {
                          widget.onPressed!(true);
                        } else {
                          context.pop(inputController.text);
                        }
                      },
                      height: 50,
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
