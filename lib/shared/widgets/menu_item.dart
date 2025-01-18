import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

class MenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  const MenuItem({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
        ),
        const SizedBox(
          width: 4,
        ),
        Text(
          title,
          style: context.bodyMedium,
        ),
      ],
    );
  }
}
