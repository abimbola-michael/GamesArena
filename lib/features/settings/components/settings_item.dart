import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

class SettingsItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? color;
  final VoidCallback onPressed;
  const SettingsItem({
    super.key,
    required this.title,
    required this.icon,
    this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: color,
            ),
            const SizedBox(
              width: 8,
            ),
            Text(
              title,
              style: context.bodyMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
