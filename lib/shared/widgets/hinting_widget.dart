import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/widgets/blinking_border_container.dart';
import 'package:gamesarena/theme/colors.dart';

class HintingWidget extends StatefulWidget {
  final Widget child;
  final String hintText;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final double hintHeight;
  final double arrowSize;
  final double hintRadius;
  final double arrowEndPadding;

  final bool showHint;

  const HintingWidget(
      {super.key,
      required this.child,
      required this.hintText,
      this.top,
      this.right,
      this.bottom,
      this.left,
      required this.showHint,
      this.hintHeight = 30,
      this.arrowSize = 10,
      this.hintRadius = 30,
      this.arrowEndPadding = 0});

  @override
  State<HintingWidget> createState() => _HintingWidgetState();
}

class _HintingWidgetState extends State<HintingWidget> {
  // final GlobalKey _childKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (widget.showHint) ...[
          Positioned(
              top: widget.top != null
                  ? -widget.top! - widget.arrowSize - widget.arrowEndPadding
                  : null,
              right: widget.right != null
                  ? -widget.right! +
                      (widget.hintRadius / 2) +
                      widget.arrowEndPadding
                  : null,
              bottom: widget.bottom != null
                  ? -widget.bottom! - widget.arrowSize - widget.arrowEndPadding
                  : null,
              left: widget.left != null
                  ? -widget.left! +
                      (widget.hintRadius / 2) +
                      widget.arrowEndPadding
                  : null,
              child: Transform.rotate(
                angle: 45 * (pi / 180),
                child: Container(
                  width: widget.arrowSize,
                  height: widget.arrowSize,
                  // blink: true,
                  decoration: const BoxDecoration(color: primaryColor),
                ),
              )),
          Positioned(
            top: widget.top != null
                ? -widget.top! - widget.hintHeight - (widget.arrowSize / 2)
                : null,
            right: widget.right != null ? -widget.right! : null,
            bottom: widget.bottom != null
                ? -widget.bottom! - widget.hintHeight - (widget.arrowSize / 2)
                : null,
            left: widget.left != null ? -widget.left! : null,
            child: Container(
              // blinkBorderColor: primaryColor,
              //blink: true,
              height: widget.hintHeight,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(widget.hintRadius),
              ),
              child: Text(widget.hintText,
                  style: context.bodySmall?.copyWith(color: Colors.white)),
            ),
          ),
        ]
      ],
    );
  }
}
