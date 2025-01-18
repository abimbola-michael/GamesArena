import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../shared/widgets/button.dart';
import '../../../theme/colors.dart';

class Social extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onPressed;
  const Social(
      {super.key, required this.title, required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Button(
        onPressed: onPressed,
        height: 50,
        color: lightestTint,
        padding: const EdgeInsets.all(10),
        borderRadius: BorderRadius.circular(25),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
