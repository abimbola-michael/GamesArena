import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

import '../../../../theme/colors.dart';

class QuizActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool disabled;
  const QuizActionButton(
      {super.key,
      required this.icon,
      required this.onPressed,
      this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
          onTap: disabled ? null : onPressed,
          child: CircleAvatar(
            radius: 25,
            backgroundColor: tint,
            child: Icon(
              icon,
              size: 25,
              color: context.bgColor,
            ),
          )),
    );
  }
}
