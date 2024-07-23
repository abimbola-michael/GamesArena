import 'package:flutter/material.dart';

class GradientMask extends StatelessWidget {
  final Gradient gradient;
  final Widget child;
  const GradientMask({super.key, required this.gradient, required this.child});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return gradient.createShader(bounds);
      },
      blendMode: BlendMode.srcIn,
      child: child,
    );
  }
}
