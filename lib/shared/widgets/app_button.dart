// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

import 'svg_asset.dart';

class AppButton extends StatelessWidget {
  final String? title;
  final String? icon;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final Widget? child;
  final double? radius;
  final Color? color;
  final Color? bgColor;
  final TextStyle? textStyle;
  final double fontSize;
  final bool wrapped;
  final bool outlined;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const AppButton(
      {super.key,
      this.title,
      this.textStyle,
      this.onPressed,
      this.width,
      this.height,
      this.child,
      this.radius,
      this.bgColor,
      this.color,
      this.padding,
      this.fontSize = 14,
      this.wrapped = false,
      this.outlined = false,
      this.icon,
      this.margin});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      //borderRadius: BorderRadius.circular(radius ?? 30),
      child: Container(
        width: width,
        height: height ?? 35,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 12),
        margin: margin,
        //margin: const EdgeInsets.symmetric(horizontal: 4),
        alignment: wrapped ? null : Alignment.center,
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : bgColor ?? primaryColor,
          borderRadius: BorderRadius.circular(radius ?? 30),
          border: outlined
              ? Border.all(
                  color: primaryColor,
                  width: 1,
                )
              : null,
        ),

        child: child ??
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  SvgAsset(
                    name: icon!,
                    color: black,
                    size: 24,
                  ),
                if (icon != null && title != null)
                  const SizedBox(
                    width: 15,
                  ),
                if (title != null)
                  Flexible(
                    child: Text(
                      title ?? "",
                      style: textStyle ??
                          TextStyle(
                              fontSize: fontSize,
                              color: color ?? white,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.none),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
              ],
            ),
      ),
    );
  }
}
