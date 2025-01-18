import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:gamesarena/features/game/widgets/profile_photo.dart';
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
    // if (users.length == 1) {
    //   users = List.generate(4, (index) => users.first);
    // }
    final length = users.length;
    int gap = 2;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        // border: Border.all(color: lightestTint),
        // color: lightestTint,
      ),
      child: Stack(
        children: List.generate(length, (index) {
          final user = users[index];
          final width = length == 1 ? size : size / 2;
          final height =
              length == 1 || length == 2 || (index == 0 && length == 3)
                  ? size
                  : size / 2;

          return Positioned(
            top: index == 0 || index == 1 ? 0 : null,
            bottom: index == 2 || index == 3 ? 0 : null,
            left: index == 0 || index == 3 ? 0 : null,
            right: index == 1 || index == 2 ? 0 : null,
            child: ProfilePhoto(
                isDecorated: false,
                width: width - (width == (size / 2) ? gap : 0),
                height: height - (height == (size / 2) ? gap : 0),
                profilePhoto: user.profile_photo ?? "",
                name: user.username),
          );
        }),
      ),
    );
  }
}
