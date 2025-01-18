// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

import '../../theme/colors.dart';

class SvgAsset extends StatelessWidget {
  final Color? color;
  final LinearGradient? gradient;
  final double? size;
  final double? height;
  final double? width;
  final String name;
  const SvgAsset(
      {super.key,
      this.color,
      this.size,
      required this.name,
      this.gradient,
      this.height,
      this.width});

  @override
  Widget build(BuildContext context) {
    if (color != null) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
        child: SvgPicture.asset(
          "assets/svgs/$name.svg",
          height: height ?? size,
          width: width ?? size,
        ),
      );
    }

    if (gradient != null) {
      return ShaderMask(
        shaderCallback: (Rect bounds) {
          return gradient!.createShader(bounds);
        },
        child: SvgPicture.asset(
          "assets/images/svg/$name.svg",
          height: height ?? size,
          width: width ?? size,
        ),
      );
    }

    return SvgPicture.asset(
      "assets/images/svg/$name.svg",
      height: height ?? size,
      width: width ?? size,
    );
  }
}
