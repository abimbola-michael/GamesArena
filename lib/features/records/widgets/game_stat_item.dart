import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../theme/colors.dart';

class GameStatItem extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onPressed;
  const GameStatItem(
      {super.key,
      required this.title,
      required this.count,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 90,
        height: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: tint,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(width: 4),
            Text(
              "$count",
              style: const TextStyle(
                fontSize: 16,
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
