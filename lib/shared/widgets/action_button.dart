import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/theme/colors.dart';
import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double? height, width;
  final Color? textColor, color, disabledColor;
  final bool wrap, half, disabled, outline;
  final double? margin, padding, radius;
  const ActionButton(this.text,
      {super.key,
      this.wrap = false,
      this.half = false,
      this.outline = false,
      required this.onPressed,
      this.height,
      this.textColor,
      this.color,
      this.margin,
      this.padding,
      this.radius,
      this.width,
      this.disabledColor,
      this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: wrap || disabled ? null : onPressed,
      borderRadius: BorderRadius.circular(radius ?? 30),
      child: Container(
        decoration: wrap
            ? null
            : BoxDecoration(
                color: outline
                    ? Colors.transparent
                    : disabled
                        ? disabledColor
                        : color ?? primaryColor,
                borderRadius: BorderRadius.circular(radius ?? 30),
                border: Border.all(
                    color: outline ? color ?? primaryColor : Colors.transparent,
                    width: 2)),
        alignment: Alignment.center,
        height: height,
        width: width ?? (wrap ? null : double.infinity),
        margin:
            // : wrap
            //     ? null
            //     :
            EdgeInsets.symmetric(
                vertical: margin ?? 10,
                horizontal: half
                    ? context.screenWidth.percentValue(half ? 25 : 5)
                    : margin ?? 0),
        padding: wrap || height != null ? null : EdgeInsets.all(padding ?? 10),
        child: wrap
            ? InkWell(
                onTap: disabled ? null : onPressed,
                borderRadius: BorderRadius.circular(radius ?? 30),
                child: Container(
                  margin: EdgeInsets.all(margin ?? 0),
                  padding: EdgeInsets.all(padding ?? 10),
                  decoration: BoxDecoration(
                      color: outline
                          ? Colors.transparent
                          : disabled
                              ? disabledColor
                              : color ?? primaryColor,
                      borderRadius: BorderRadius.circular(radius ?? 30),
                      border: Border.all(
                          color: outline
                              ? color ?? primaryColor
                              : Colors.transparent,
                          width: 2)),
                  child: Text(
                    text,
                    style: TextStyle(
                        color: outline
                            ? color ?? primaryColor
                            : textColor ?? Colors.white,
                        fontSize: 20),
                  ),
                ),
              )
            : Text(
                text,
                style: TextStyle(
                    color: outline
                        ? color ?? primaryColor
                        : textColor ?? Colors.white,
                    fontSize: 20),
              ),
      ),
    );
  }
}
