import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../theme/colors.dart';

class AppPopupMenuButton extends StatelessWidget {
  final List<String> options;
  final void Function(String option)? onSelected;
  final Widget? child;
  const AppPopupMenuButton(
      {super.key, required this.options, this.onSelected, this.child});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      itemBuilder: (context) {
        return List.generate(options.length, (index) {
          final option = options[index];
          return PopupMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: context.bodyMedium,
              ));
        });
      },
      onSelected: onSelected,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: child ?? Icon(EvaIcons.more_vertical, color: tint),
        ),
      ),
    );
  }
}
