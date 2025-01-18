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
  final Color? disabledColor;

  final TextStyle? textStyle;
  final double fontSize;
  final bool wrapped;
  final bool outlined;
  final bool loading;
  final bool disabled;

  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const AppButton(
      {super.key,
      this.disabledColor,
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
      this.loading = false,
      this.disabled = false,
      this.icon,
      this.margin});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onPressed,
      behavior: HitTestBehavior.opaque,
      //borderRadius: BorderRadius.circular(radius ?? 30),
      child: Container(
        width: width,
        height: height ?? 40,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 12),
        margin:
            margin ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        alignment: wrapped ? null : Alignment.center,
        decoration: BoxDecoration(
          color: outlined
              ? Colors.transparent
              : (bgColor ?? primaryColor.withOpacity(disabled ? 0.5 : 1)),
          borderRadius: BorderRadius.circular(radius ?? 30),
          border: outlined
              ? Border.all(
                  color: (color ?? bgColor ?? primaryColor)
                      .withOpacity(disabled ? 0.5 : 1),
                  width: 1,
                )
              : null,
        ),
        child: child ??
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading) ...[
                  const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                ],
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
                              color: color ??
                                  (outlined
                                      ? (bgColor ??
                                          primaryColor
                                              .withOpacity(disabled ? 0.5 : 1))
                                      : white),
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.none),
                      textAlign: TextAlign.center,
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
