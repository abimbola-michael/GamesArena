// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import 'app_container.dart';
import 'svg_asset.dart';

class AppSvgButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String icon;

  final Color? bgColor;
  final Color? borderColor;
  final Color? color;
  final double? size;
  final double? radius;
  final double? width;
  final double? height;
  final bool hideBackground;
  final bool isCircular;
  const AppSvgButton({
    super.key,
    this.onPressed,
    required this.icon,
    this.bgColor,
    this.size,
    this.radius,
    this.hideBackground = false,
    this.isCircular = false,
    this.color,
    this.borderColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(radius ?? 8),
      onTap: onPressed,
      child: AppContainer(
        width: width ?? (radius ?? 20) * 2,
        height: height ?? (radius ?? 20) * 2,
        borderRadius: !isCircular ? BorderRadius.circular(radius ?? 8) : null,
        borderColor: borderColor,
        isCircular: isCircular,
        borderWidth: 1,
        color: bgColor,
        child: SvgAsset(
          name: icon,
          size: size,
          color: color,
        ),
      ),
    );
  }
}
