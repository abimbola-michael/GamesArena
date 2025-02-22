import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

import '../../theme/colors.dart';
import '../widgets/action_button.dart';
import '../widgets/app_button.dart';

class OptionsSelectWithComfirmationDialog extends StatefulWidget {
  final String title;
  final String? message;
  final List<String>? actions;
  final int quarterTurns;
  final String? selectedOption;
  final List<String>? selectedOptions;

  final List<String> options;
  final void Function(List<String>? options)? onPressed;
  final Axis scrollDirection;
  final bool isMultiSelect;

  const OptionsSelectWithComfirmationDialog(
      {super.key,
      required this.title,
      required this.options,
      this.selectedOption,
      this.selectedOptions,
      this.message,
      this.onPressed,
      this.actions,
      this.quarterTurns = 0,
      this.scrollDirection = Axis.horizontal,
      this.isMultiSelect = false});

  @override
  State<OptionsSelectWithComfirmationDialog> createState() =>
      _OptionsSelectWithComfirmationDialogState();
}

class _OptionsSelectWithComfirmationDialogState
    extends State<OptionsSelectWithComfirmationDialog> {
  String? selectedOption;
  List<String>? selectedOptions;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    selectedOption = widget.selectedOption;
    if (widget.selectedOptions != null) {
      selectedOptions = [...widget.selectedOptions!];
    }
  }

  void toggleSelectOption(String option) {
    if (selectedOptions != null) {
      if (selectedOptions!.contains(option)) {
        selectedOptions!.remove(option);
      } else {
        selectedOptions!.add(option);
      }
      setState(() {});
    } else if (selectedOption != null) {
      selectedOption = option;
      setState(() {});
    }
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
              SizedBox(
                height: widget.scrollDirection == Axis.horizontal ? 40 : 150,
                child: LayoutBuilder(builder: (context, constraint) {
                  final width = constraint.maxWidth;
                  return ListView(
                    shrinkWrap: true,
                    scrollDirection: widget.scrollDirection,
                    children: List.generate(widget.options.length, (index) {
                      final option = widget.options[index];
                      return Padding(
                        padding: EdgeInsets.only(
                            right: widget.scrollDirection == Axis.vertical
                                ? 0
                                : index == widget.options.length - 1
                                    ? 0
                                    : 8,
                            bottom: widget.scrollDirection == Axis.horizontal
                                ? 0
                                : index == widget.options.length - 1
                                    ? 0
                                    : 8),
                        child: InkWell(
                          onTap: () => toggleSelectOption(option),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 450),
                            width: widget.scrollDirection == Axis.horizontal
                                ? widget.options.length < 3
                                    ? (width - 40) / widget.options.length
                                    : (width - 40) / 3
                                : double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: (selectedOptions != null &&
                                          selectedOptions!.contains(option)) ||
                                      (selectedOption != null &&
                                          selectedOption == option)
                                  ? primaryColor
                                  : lightestTint,
                            ),
                            child: Text(
                              option,
                              style: const TextStyle(fontSize: 14),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                }),
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
                              : "Cancel",
                      onPressed: () {
                        if (widget.onPressed != null) {
                          widget.onPressed!(null);
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
                      title:
                          widget.actions != null && widget.actions!.length > 1
                              ? widget.actions![1]
                              : "Done",
                      //comfirmationType.capitalize,
                      onPressed: () {
                        final result = selectedOptions ??
                            (selectedOption != null ? [selectedOption!] : []);
                        if (widget.onPressed != null) {
                          widget.onPressed!(result);
                        } else {
                          context.pop(result);
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
