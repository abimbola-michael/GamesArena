import 'package:flutter/material.dart';
import 'package:gamesarena/theme/colors.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

import 'app_container.dart';
import 'button.dart';

class AppTabItem extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final int badgeCount;
  final VoidCallback onPressed;
  const AppTabItem({
    super.key,
    required this.icon,
    required this.selected,
    required this.onPressed,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Button(
          onPressed: onPressed,
          width: 40,
          height: 40,
          isCircular: true,
          //color: selected ? primaryColor : Colors.transparent,
          child: Icon(icon, color: selected ? primaryColor : lighterTint),
        ),
        if (badgeCount > 0)
          Positioned(
              right: 0,
              top: 0,
              child: AppContainer(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                borderRadius: BorderRadius.circular(8),
                color: primaryColor,
                child: Text(
                  badgeCount.toString(),
                  style:
                      context.bodyMedium?.copyWith(color: white, fontSize: 10),
                ),
              )),
      ],
    );
  }
}
