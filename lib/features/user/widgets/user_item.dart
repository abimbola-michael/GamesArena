import 'package:cached_network_image/cached_network_image.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';

import '../../../shared/services.dart';
import '../../../shared/models/models.dart';
import '../../../theme/colors.dart';
import '../../../shared/utils/utils.dart';
import '../../game/widgets/profile_photo.dart';

class UserItem extends StatelessWidget {
  final User? user;
  final String type;
  final VoidCallback? onPressed;
  final bool showCheck;

  const UserItem(
      {super.key,
      required this.user,
      required this.type,
      this.onPressed,
      this.showCheck = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              ProfilePhoto(
                  profilePhoto: user?.profile_photo,
                  name: user?.username ?? ""),
              if (showCheck && (user?.checked ?? false)) ...[
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: onPressed,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: type == "select" &&
                              user != null &&
                              user!.user_id != myId
                          ? Colors.red
                          : primaryColor,
                      child: Icon(
                        type == "select" &&
                                user != null &&
                                user!.user_id != myId
                            ? Icons.close
                            : Icons.check,
                        size: 8,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              ],
            ],
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            user?.username ?? "",
            style: context.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
