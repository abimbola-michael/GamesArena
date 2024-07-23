// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  final Widget? child;
  final VoidCallback? onPressed;
  final Color? color;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final double? borderWidth;
  final Color? borderColor;
  final Alignment? alignment;
  final ImageProvider? image;
  final BoxFit? imageFit;
  final List<Color>? gradientColors;
  final List<BoxShadow>? shadows;
  final bool isCircular;
  final bool wrapped;

  const Button(
      {super.key,
      this.child,
      this.onPressed,
      this.color,
      this.width,
      this.height,
      this.padding,
      this.margin,
      this.borderRadius,
      this.borderWidth,
      this.borderColor,
      this.alignment,
      this.image,
      this.gradientColors,
      this.isCircular = false,
      this.shadows,
      this.wrapped = false,
      this.imageFit});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        // height: height,
        // width: width,
        height: height == null
            ? null
            : height! - (borderColor != null ? ((borderWidth ?? 1) * 2) : 0),
        width: width == null
            ? null
            : width! - (borderColor != null ? ((borderWidth ?? 1) * 2) : 0),
        padding: padding,
        margin: margin,
        alignment: alignment ?? (wrapped ? null : Alignment.center),
        decoration: BoxDecoration(
          image: image == null
              ? null
              : DecorationImage(image: image!, fit: imageFit ?? BoxFit.cover),
          color: color,
          gradient: gradientColors != null
              ? LinearGradient(
                  colors: gradientColors!,
                )
              : null,
          boxShadow: shadows,
          shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircular ? null : borderRadius,
          border: Border.all(
            color: borderColor ?? Colors.transparent,
            width: borderWidth ?? 0,
          ),
        ),
        child: child,
      ),
    );
  }
}
