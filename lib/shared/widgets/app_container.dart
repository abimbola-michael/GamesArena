import 'package:flutter/material.dart';

class AppContainer extends StatelessWidget {
  final Widget? child;
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
  final Gradient? gradient;
  final List<BoxShadow>? shadows;
  final Alignment imagePosition;
  final bool isCircular;
  final bool wrapped;
  final BoxConstraints? constraints;
  final bool clip;

  const AppContainer(
      {super.key,
      this.child,
      this.color,
      this.width,
      this.height,
      this.padding,
      this.borderRadius,
      this.borderWidth,
      this.borderColor,
      this.alignment,
      this.image,
      this.gradientColors,
      this.gradient,
      this.margin,
      this.isCircular = false,
      this.wrapped = false,
      this.clip = false,
      this.shadows,
      this.imageFit,
      this.imagePosition = Alignment.center,
      this.constraints});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: clip ? Clip.antiAliasWithSaveLayer : Clip.none,
      height: height == null
          ? null
          : height! - (borderColor != null ? ((borderWidth ?? 1) * 2) : 0),
      width: width == null
          ? null
          : width! - (borderColor != null ? ((borderWidth ?? 1) * 2) : 0),
      padding: padding,
      margin: margin,
      constraints: constraints,
      alignment: wrapped ? null : alignment ?? Alignment.center,
      decoration: BoxDecoration(
        image: image == null
            ? null
            : DecorationImage(
                image: image!,
                fit: imageFit ?? BoxFit.cover,
                alignment: imagePosition),
        color: color,
        gradient: gradient ??
            (gradientColors != null
                ? LinearGradient(
                    colors: gradientColors!,
                  )
                : null),
        boxShadow: shadows,
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircular ? null : borderRadius,
        border: Border.all(
          color: borderColor ?? Colors.transparent,
          width: borderWidth ?? 0,
        ),
      ),
      child: child,
    );
  }
}
