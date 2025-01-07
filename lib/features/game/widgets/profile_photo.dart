import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

import '../../../theme/colors.dart';

class ProfilePhoto extends StatelessWidget {
  final String name;
  final String? profilePhoto;
  final double size;
  final double? height;
  final double? width;
  final bool isDecorated;

  const ProfilePhoto(
      {super.key,
      required this.profilePhoto,
      required this.name,
      this.height,
      this.width,
      this.size = 50,
      this.isDecorated = true});

  @override
  Widget build(BuildContext context) {
    final textSize = width != null && height == null
        ? min(size, width!)
        : height != null && width == null
            ? min(size, height!)
            : height != null && width != null
                ? min(height!, width!)
                : size;
    return Container(
      width: width ?? size,
      height: height ?? size,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      decoration: BoxDecoration(
        shape: isDecorated ? BoxShape.circle : BoxShape.rectangle,
        // border: isDecorated ? Border.all(color: lightestTint) : null,
        color: lightestTint,
        image: profilePhoto != null && profilePhoto!.isNotEmpty
            ? DecorationImage(
                image: CachedNetworkImageProvider(profilePhoto!),
                fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: profilePhoto != null && profilePhoto!.isNotEmpty
          ? null
          : Text(
              name.firstChar?.capitalize ?? "",
              style: TextStyle(
                  fontSize: textSize * 0.7,
                  color: primaryColor,
                  fontWeight: FontWeight.bold),
            ),
    );
  }
}
