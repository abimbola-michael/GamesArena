import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/utils/utils.dart';
import 'package:gamesarena/theme/colors.dart';
import '../../../shared/widgets/custom_grid_builder.dart';
import '../../game/models/match.dart';
import '../../user/models/user.dart';

class PlayersProfilePhoto extends StatelessWidget {
  final bool withoutMyId;
  final List<User> users;
  final double size;
  const PlayersProfilePhoto(
      {super.key,
      required this.users,
      this.withoutMyId = false,
      this.size = 50});

  @override
  Widget build(BuildContext context) {
    List<User> users = withoutMyId
        ? this.users.where((user) => user.user_id != myId).toList()
        : this.users;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: lightestTint),
        // color: lightestTint,
      ),
      child: CustomGridBuilder(
        expandedWidth: true,
        expandedHeight: true,
        gridCount: 2,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final profilePhoto = user.profile_photo ?? "";
          final name = user.username;
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: lightestTint,
              image: profilePhoto.isNotEmpty
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(profilePhoto))
                  : null,
            ),
            alignment: Alignment.center,
            child: profilePhoto.isNotEmpty
                ? null
                : Text(
                    name.firstChar ?? "",
                    style: TextStyle(
                        fontSize: size / 2,
                        color: primaryColor,
                        fontWeight: FontWeight.bold),
                  ),
          );
        },
      ),
    );
  }
}
