// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

import '../../theme/colors.dart';

class ImageAsset extends StatelessWidget {
  final Color? color;
  final LinearGradient? gradient;
  final double? size;
  final double? height;
  final double? width;
  final String name;
  final BoxFit? fit;
  const ImageAsset(
      {super.key,
      this.color,
      this.size,
      required this.name,
      this.gradient,
      this.height,
      this.width,
      this.fit});

  @override
  Widget build(BuildContext context) {
    if (color != null) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
        child: Image.asset(
          "assets/images/png/$name.png",
          height: height ?? size,
          width: width ?? size,
          fit: fit,
        ),
      );
    }
    if (gradient != null) {
      return ShaderMask(
        shaderCallback: (Rect bounds) {
          return gradient!.createShader(bounds);
        },
        child: Image.asset(
          "assets/images/png/$name.png",
          height: height ?? size,
          width: width ?? size,
          fit: fit,
        ),
      );
    }
    return Image.asset(
      "assets/images/png/$name.png",
      height: height ?? size,
      width: width ?? size,
      fit: fit,
    );
  }
}
