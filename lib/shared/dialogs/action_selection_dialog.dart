import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

class ActionSelectionDialog extends StatelessWidget {
  final String? title;
  final List<String> options;
  final void Function(int index, String option) onPressed;
  const ActionSelectionDialog(
      {super.key, required this.options, required this.onPressed, this.title});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              Text(
                title!,
                style: context.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ListView(
              shrinkWrap: true,
              children: List.generate(options.length, (index) {
                final option = options[index];
                return InkWell(
                  onTap: () => onPressed(index, option),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(option, style: context.bodyMedium),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
