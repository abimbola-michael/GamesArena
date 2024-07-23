// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class BlinkingBorderContainer extends StatefulWidget {
  final double? width;
  final double? height;
  final double blinkBorderWidth;
  final Color blinkBorderColor;
  final BoxDecoration? decoration;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final double? radius;
  final Widget? child;
  final Color? color;
  final Alignment? alignment;
  final bool blink;
  final bool circular;

  const BlinkingBorderContainer({
    super.key,
    this.width,
    this.height,
    this.decoration,
    this.blinkBorderWidth = 4,
    this.margin,
    this.padding,
    this.radius,
    this.child,
    this.color,
    this.alignment,
    this.blinkBorderColor = Colors.purple,
    this.blink = false,
    this.circular = false,
  });

  @override
  State<BlinkingBorderContainer> createState() =>
      _BlinkingBorderContainerState();
}

class _BlinkingBorderContainerState extends State<BlinkingBorderContainer>
    with TickerProviderStateMixin {
  AnimationController? controller;
  @override
  void initState() {
    super.initState();
    toggleBlinkAnimation(widget.blink);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void startBlinkAnimation() {
    if (controller == null || !controller!.isAnimating) {
      controller = AnimationController(
          vsync: this, duration: const Duration(seconds: 1));
      controller!.repeat(reverse: true);
      controller!.addListener(() {
        setState(() {});
      });
    }
  }

  void stopBlinkAnimation() {
    if (controller != null && controller!.isAnimating) {
      controller!.dispose();
      controller = null;
      setState(() {});
    }
  }

  void toggleBlinkAnimation(bool blink) {
    if (blink) {
      startBlinkAnimation();
    } else {
      stopBlinkAnimation();
    }
  }

  @override
  Widget build(BuildContext context) {
    toggleBlinkAnimation(widget.blink);
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          padding: widget.padding,
          alignment: widget.alignment,
          color: widget.color,
          decoration: widget.decoration,
          child: widget.child,
        ),
        Positioned.fill(
          child: Container(
            width: widget.width,
            height: widget.height,
            margin: widget.margin,
            padding: widget.padding,
            decoration: !widget.blink
                ? null
                : BoxDecoration(
                    borderRadius: widget.decoration != null
                        ? widget.decoration!.borderRadius
                        : widget.radius == null
                            ? null
                            : BorderRadius.circular(widget.radius!.toDouble()),
                    border: controller == null
                        ? null
                        : Border.all(
                            color: widget.blinkBorderColor
                                .withOpacity(controller!.value),
                            width: widget.blinkBorderWidth)),
          ),
        ),
      ],
    );
  }
}
