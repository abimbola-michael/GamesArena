import 'package:flutter/material.dart';
import 'package:gamesarena/theme/colors.dart';

class CallActionButton extends StatelessWidget {
  final IconData icon;
  final Color? bgColor;
  final Color? iconColor;
  final bool? selected;
  final VoidCallback onPressed;
  const CallActionButton(
      {super.key,
      required this.icon,
      this.bgColor,
      this.iconColor,
      this.selected,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected == true ? primaryColor : (bgColor ?? white),
        ),
        child: Icon(
          icon,
          size: 25,
          color: bgColor != null || selected == true ? white : black,
        ),
      ),
    );
  }
}
