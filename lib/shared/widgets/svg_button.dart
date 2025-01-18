// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import 'svg_asset.dart';

class SvgButton extends StatelessWidget {
  final String name;
  final VoidCallback? onPressed;
  final double? size;
  final Color? color;
  final EdgeInsets? padding;
  const SvgButton({
    super.key,
    required this.name,
    this.onPressed,
    this.size,
    this.color,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size != null ? size! / 2 : 20),
      child: GestureDetector(
          onTap: onPressed,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(8.0),
            child: SvgAsset(
              name: name,
              size: size,
              color: color,
            ),
          )),
    );
  }
}
