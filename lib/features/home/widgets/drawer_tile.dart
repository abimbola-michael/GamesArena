// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

class DrawerTile extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  const DrawerTile({
    super.key,
    required this.title,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Text(title, style: context.bodyMedium),
      ),
    );
  }
}
