import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

import '../../../theme/colors.dart';

class ProfilePhoto extends StatelessWidget {
  final String name;
  final String? profilePhoto;
  final double size;
  const ProfilePhoto(
      {super.key,
      required this.profilePhoto,
      required this.name,
      this.size = 50});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: lightestTint),
        color: lightestTint,
        image: profilePhoto != null && profilePhoto!.isNotEmpty
            ? DecorationImage(image: CachedNetworkImageProvider(profilePhoto!))
            : null,
      ),
      alignment: Alignment.center,
      child: profilePhoto != null && profilePhoto!.isNotEmpty
          ? null
          : Text(
              name.firstChar ?? "",
              style: TextStyle(
                  fontSize: size / 2,
                  color: primaryColor,
                  fontWeight: FontWeight.bold),
            ),
    );
  }
}
